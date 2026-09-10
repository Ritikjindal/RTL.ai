# rtlai/optimizer/planner.py
from rtlai.optimizer.llm_client import call_claude
from rtlai.optimizer.config import PLANNER_MODEL
from rtlai.schema import RunResult

PLANNER_SYSTEM_PROMPT = """You are an expert digital design engineer specializing in RTL (Verilog) optimization.
You will be shown a synthesized Verilog design along with its real, measured Power/Performance/Area (PPA) numbers.
Your job is NOT to write code. Your job is to study the design and its numbers, decide what ONE specific structural
change is most likely to improve it (area, timing/frequency, or power), and describe that change clearly enough that
another engineer could implement it without seeing your reasoning.

Rules you must follow:
- Do not change the module name or any port name, direction, or width. The modified design must keep the exact same
  interface as the original, or it cannot be verified as equivalent.
- Propose exactly ONE focused change, not a list of unrelated ideas.
- State which metric you are targeting (area, timing, or power) and briefly why, based on the numbers you were given.
- Describe the change structurally and specifically (e.g. "replace the behavioral +/- operators for ADD/SUB with an
  explicit N-bit ripple-carry adder built from single-bit full adders"), not vaguely (e.g. "optimize the arithmetic").
- If you are told a previous attempt failed, propose a genuinely different approach, not a minor variation of it.
"""


def build_planner_prompt(rtl_code: str, baseline_result: RunResult, previous_feedback: str = None) -> str:
    lines = []
    lines.append(f"Design name: {baseline_result.design_name}")
    lines.append("")
    lines.append("Verilog source:")
    lines.append("```verilog")
    lines.append(rtl_code)
    lines.append("```")
    lines.append("")
    lines.append("Measured PPA results for this design:")
    lines.append(f"- Cell area: {baseline_result.area.cell_area_um2} um^2 ({baseline_result.area.total_cells} cells, {baseline_result.area.flip_flops} flip-flops)")
    lines.append(f"- Worst slack: {baseline_result.timing.worst_slack_ns} ns")
    lines.append(f"- Max frequency: {baseline_result.timing.max_frequency_mhz} MHz")
    lines.append(f"- Total power: {baseline_result.power.total_uw} uW")
    lines.append(f"- PPA overall score: {baseline_result.ppa.overall_score}")
    lines.append("")

    if previous_feedback:
        lines.append("A previous attempt at improving this design was tried and did not work out:")
        lines.append(previous_feedback)
        lines.append("Propose a different approach this time.")
        lines.append("")

    lines.append(
        "Based on this, propose ONE specific structural change to improve this design. "
        "State clearly which metric you are targeting and why, then describe the change precisely."
    )
    return "\n".join(lines)


def generate_plan(rtl_code: str, baseline_result: RunResult, previous_feedback: str = None) -> str:
    prompt = build_planner_prompt(rtl_code, baseline_result, previous_feedback)
    return call_claude(
        model=PLANNER_MODEL,
        system_prompt=PLANNER_SYSTEM_PROMPT,
        user_prompt=prompt,
        max_tokens=8192,
    )
    if not plan.strip():
        raise RuntimeError("Planner returned an empty plan (likely hit the token limit during thinking).")
    return plan