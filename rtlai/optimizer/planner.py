# rtlai/optimizer/planner.py
import re

from rtlai.optimizer.llm_client import call_claude
from rtlai.optimizer.config import PLANNER_MODEL
from rtlai.schema import RunResult

LATENCY_RE = re.compile(r"LATENCY_OFFSET:\s*\+?(\d+)")


def extract_latency_offset(plan: str) -> int:
    """Reads the LATENCY_OFFSET line the planner is required to emit. Takes the last
    match (the model may mention the format in prose before using it), and defaults to
    0 -- latency-preserving -- if it's missing."""
    matches = LATENCY_RE.findall(plan)
    return int(matches[-1]) if matches else 0


PLANNER_SYSTEM_PROMPT = """You are an expert digital design engineer working on RTL timing closure.

You will be shown a Verilog design, its clock constraint, its critical path, and its real measured
Power/Performance/Area numbers from synthesis and static timing analysis. Your job is NOT to write
code. Your job is to diagnose the design the way an engineer reads a timing report, choose ONE
specific structural change that will improve it, and describe that change precisely enough that
another engineer could implement it without seeing your reasoning.

PRIORITY - read the numbers before deciding what to optimize:
1. If the design VIOLATES its timing constraint (negative worst slack), closing timing is the only
   goal that matters. Attack the critical path directly.
2. If timing is met but the margin is thin, raising maximum frequency is the most valuable win.
3. Only when timing is comfortable should you target area or power instead.

OPTIMIZATION TECHNIQUES available to you - pick the one that fits your diagnosis:
- Pipelining: insert register stages to break a long combinational path into shorter ones. The most
  direct way to raise maximum frequency. Adds latency, which you must declare (see below).
- Retiming: move existing registers earlier or later across combinational logic to balance stage
  delays, without changing the total number of pipeline stages.
- Logic restructuring: rebalance a deep or unbalanced structure - convert a long priority if/else
  chain into a parallel case or a balanced tree, replace a ripple structure with a lookahead one,
  share a duplicated arithmetic unit.
- FSM optimization: re-encode state registers (one-hot, binary, gray), or restructure the
  next-state and output decode logic.

USE THE CRITICAL PATH. When timing is the target, your change MUST shorten the reported critical
path. The startpoint, endpoint and logic depth tell you exactly where the delay is. A change that
does not touch that path will not improve timing, however clever it is.

RULES you must follow:
- You MUST BEGIN your response with a line in exactly this format, stating how many EXTRA clock
  cycles your candidate needs to produce its outputs compared to the baseline:
      LATENCY_OFFSET: <n>
  Use LATENCY_OFFSET: 0 if your change does not alter cycle timing. Get this number right - the
  formal equivalence checker uses it, and a wrong value will cause your candidate to be rejected.
- Do not change the module name or any port name, direction, or width. The candidate must keep the
  exact same interface as the original. (Interface means PORTS only - you MAY change when outputs
  appear in time, provided you declare it with LATENCY_OFFSET.)
- Propose exactly ONE focused change, not a list of unrelated ideas.
- State which metric you are targeting and why, citing the specific numbers that led you there.
- Describe the change structurally and specifically ("insert a pipeline register between the
  multiplier output and the accumulator input, splitting the 14-level path at its midpoint"),
  never vaguely ("optimize the datapath").
- The candidate must remain functionally identical to the baseline. It is formally verified against
  the original, so any behavioural difference will be caught and the candidate rejected.
- If you are told a previous attempt failed, read the failure carefully - especially any
  counterexample stimulus - work out what went wrong, and propose a genuinely different approach.
- Do not propose changes that require precomputing a large table of constants (CRC
  matrices, coefficient ROMs, lookup tables). The implementer cannot derive such
  tables reliably and will produce wrong values. Prefer restructuring the existing
  computation - pipelining, retiming, rebalancing a tree, re-encoding state.
"""


def build_planner_prompt(rtl_code: str, baseline_result: RunResult, previous_feedback: str = None) -> str:
    t = baseline_result.timing
    a = baseline_result.area
    p = baseline_result.power

    lines = []
    lines.append(f"Design name: {baseline_result.design_name}")
    lines.append("")
    lines.append("Verilog source:")
    lines.append("```verilog")
    lines.append(rtl_code)
    lines.append("```")
    lines.append("")

    lines.append("=== TIMING (static timing analysis) ===")
    lines.append(f"- Clock: {t.clock}")
    violating = t.worst_slack_ns is not None and t.worst_slack_ns < 0
    lines.append(
        f"- Worst slack: {t.worst_slack_ns} ns"
        + ("   <<< TIMING VIOLATION - this is the problem to solve" if violating else "")
    )
    lines.append(f"- Timing constraint met: {baseline_result.timing_passed}")
    lines.append(f"- Max frequency achievable: {t.max_frequency_mhz} MHz")
    lines.append("")
    lines.append("CRITICAL PATH (the longest path in the design - this is what limits frequency):")
    lines.append(f"- Path type:          {t.path_type}")
    lines.append(f"- Startpoint:         {t.startpoint}")
    lines.append(f"- Endpoint:           {t.endpoint}")
    lines.append(f"- Logic depth:        {t.logic_depth} levels of logic")
    lines.append(f"- Data arrival time:  {t.data_arrival_time_ns} ns")
    lines.append(f"- Data required time: {t.data_required_time_ns} ns")
    lines.append("")

    lines.append("=== AREA ===")
    lines.append(f"- Cell area: {a.cell_area_um2} um^2")
    lines.append(f"- Total cells: {a.total_cells}")
    lines.append(f"- Flip-flops: {a.flip_flops}")
    lines.append("")

    lines.append("=== POWER ===")
    lines.append(f"- Total power: {p.total_uw} uW")
    lines.append("")

    if previous_feedback:
        lines.append("=== PREVIOUS ATTEMPT FAILED ===")
        lines.append(previous_feedback)
        lines.append("")

    lines.append(
        "Diagnose this design and propose ONE specific structural change to improve it. "
        "Begin your reply with the LATENCY_OFFSET line, then state which metric you are targeting "
        "and why - citing the numbers above - then describe the change precisely. If timing is "
        "violated or tight, your change must shorten the critical path shown above."
    )
    return "\n".join(lines)


def generate_plan(rtl_code: str, baseline_result: RunResult, previous_feedback: str = None) -> str:
    prompt = build_planner_prompt(rtl_code, baseline_result, previous_feedback)
    plan = call_claude(
        model=PLANNER_MODEL,
        system_prompt=PLANNER_SYSTEM_PROMPT,
        user_prompt=prompt,
        max_tokens=48000,
    )
    if not plan.strip():
        raise RuntimeError("Planner returned an empty plan (likely hit the token limit during thinking).")
    return plan