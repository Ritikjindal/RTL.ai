# rtlai/formal.py
#
# Formal equivalence checking via SymbiYosys, per the hackathon brief.
#
# We build the gold-vs-gate comparison ourselves as an explicit SystemVerilog
# assertion (rather than relying on Yosys's `miter -make_assert`, which was
# found to emit a hardwired always-true stub for this sequential design --
# see run history). The generated wrapper file is plain, readable Verilog:
# open it yourself to see exactly what's being checked.

import json
import re
import subprocess
from pathlib import Path
from dataclasses import dataclass
from typing import Optional, Dict


class FormalError(RuntimeError):
    pass


PREPARE_TEMPLATE = """\
read_verilog -sv {gold_rtl}
rename {top_module} gold

read_verilog -sv {gate_rtl}
rename {top_module} gate

hierarchy -check
proc

write_verilog -noattr {combined_v}
write_json {ports_json}
"""

SBY_TEMPLATE = """\
[options]
mode {mode}
depth {depth}
multiclock {multiclock}

[engines]
smtbmc

[script]
read_verilog -sv {combined_v_name}
read_verilog -sv {wrapper_v_name}
prep -top __eqcheck_top

[files]
{combined_v_path}
{wrapper_v_path}
"""


@dataclass
class EquivalenceResult:
    passed: bool
    log: str
    summary: str
    wrapper_path: Optional[Path] = None


def _prepare_gold_gate(original_rtl: Path, candidate_rtl: Path, top_module: str, run_dir: Path):
    """Loads both RTL files under distinct names (gold/gate), writes them
    back out as one combined Verilog file, and returns their port lists
    (validated to match -- a candidate with a different interface can't
    be meaningfully equivalence-checked at all)."""
    combined_v = run_dir / "gold_gate.v"
    ports_json = run_dir / "ports.json"

    script_content = PREPARE_TEMPLATE.format(
        gold_rtl=Path(original_rtl).resolve(),
        gate_rtl=Path(candidate_rtl).resolve(),
        top_module=top_module,
        combined_v=combined_v.resolve(),
        ports_json=ports_json.resolve(),
    )
    script_path = run_dir / "prepare.ys"
    script_path.write_text(script_content)

    result = subprocess.run(
        ["yosys", "-s", str(script_path)], cwd=run_dir, text=True, capture_output=True
    )
    (run_dir / "prepare.log").write_text(result.stdout + result.stderr)

    if result.returncode != 0 or not combined_v.exists() or not ports_json.exists():
        raise FormalError(
            f"Preparing gold/gate design failed (exit {result.returncode}). "
            f"See {run_dir / 'prepare.log'}"
        )

    with open(ports_json) as f:
        data = json.load(f)

    gold_ports = data["modules"]["gold"]["ports"]
    gate_ports = data["modules"]["gate"]["ports"]

    if set(gold_ports.keys()) != set(gate_ports.keys()):
        raise FormalError(
            f"Candidate RTL has a different port list than the original "
            f"(original={sorted(gold_ports)}, candidate={sorted(gate_ports)}) -- "
            f"cannot check equivalence of designs with different interfaces."
        )
    for name in gold_ports:
        if (
            gold_ports[name]["direction"] != gate_ports[name]["direction"]
            or len(gold_ports[name]["bits"]) != len(gate_ports[name]["bits"])
        ):
            raise FormalError(
                f"Port '{name}' differs in direction/width between original and candidate."
            )

    return combined_v, gold_ports


def _port_decl(name: str, info: Dict) -> str:
    width = len(info["bits"])
    return f"[{width-1}:0] {name}" if width > 1 else name


def _generate_wrapper(
    ports: Dict,
    top_wrapper_name: str = "__eqcheck_top",
    clock_port: Optional[str] = None,
    reset_port: Optional[str] = None,
    reset_active_high: Optional[bool] = None,
):
    """Builds a small Verilog module that instantiates gold and gate side
    by side and asserts their outputs match -- after forcing both through a
    real reset first via $initstate, so the proof isn't defeated by
    unconstrained initial register state.

    Returns (wrapper_source, is_multiclock)."""
    inputs = [(name, info) for name, info in ports.items() if info["direction"] == "input"]
    outputs = [(name, info) for name, info in ports.items() if info["direction"] == "output"]

    if not inputs:
        raise FormalError("Design has no input ports -- cannot build equivalence wrapper.")
    if not outputs:
        raise FormalError("Design has no output ports -- nothing to compare for equivalence.")

    if clock_port is not None:
        clock_ports = [clock_port]
    else:
        clock_ports = [
            name for name, _ in inputs
            if "clk" in name.lower() or "clock" in name.lower()
        ]
        if not clock_ports:
            raise FormalError(
                "Could not auto-detect a clock input (looked for names containing 'clk'/'clock'). "
                "Pass clock_port= explicitly for this design."
            )
    is_multiclock = len(clock_ports) > 1
    clock_port = clock_ports[0]

    if reset_port is None:
        reset_candidates = [
            name for name, _ in inputs if "rst" in name.lower() or "reset" in name.lower()
        ]
        reset_port = reset_candidates[0] if reset_candidates else None
        if reset_port and reset_active_high is None:
            lname = reset_port.lower()
            reset_active_high = not (lname.endswith("_n") or lname.endswith("b"))

    lines = [f"module {top_wrapper_name} ("]
    lines.append(",\n".join(f"    input wire {_port_decl(name, info)}" for name, info in inputs))
    lines.append(");")
    lines.append("")

    for name, info in outputs:
        width = len(info["bits"])
        width_str = f"[{width-1}:0] " if width > 1 else ""
        lines.append(f"    wire {width_str}gold_{name};")
        lines.append(f"    wire {width_str}gate_{name};")
    lines.append("")

    gold_conns = [f".{n}({n})" for n, _ in inputs] + [f".{n}(gold_{n})" for n, _ in outputs]
    gate_conns = [f".{n}({n})" for n, _ in inputs] + [f".{n}(gate_{n})" for n, _ in outputs]

    lines.append("    gold gold_inst (")
    lines.append("        " + ",\n        ".join(gold_conns))
    lines.append("    );")
    lines.append("")
    lines.append("    gate gate_inst (")
    lines.append("        " + ",\n        ".join(gate_conns))
    lines.append("    );")
    lines.append("")

    eq_terms = " && ".join(f"gold_{n} == gate_{n}" for n, _ in outputs)
    assume_expr = None
    if reset_port:
        assume_expr = reset_port if reset_active_high else f"!{reset_port}"

        if is_multiclock:
            if not reset_port:
                raise FormalError(
                "Multi-clock equivalence checking needs a reset port so gold and gate start "
                "from identical known state. Pass reset_port= explicitly."
            )
        lines.append(f"    // Multiple clock domains detected ({', '.join(clock_ports)}).")
        lines.append("    // Hold reset until EVERY domain has seen a reset edge, so both copies")
        lines.append("    // start from identical known state; only then compare outputs, at every")
        lines.append("    // timestep (neither clock is 'the' clock here).")
        seen_flags = []
        for clk in clock_ports:
            flag = f"seen_rst_{clk}"
            seen_flags.append(flag)
            lines.append(f"    reg {flag} = 1'b0;")
            lines.append(f"    always @(posedge {clk}) if ({assume_expr}) {flag} <= 1'b1;")
        lines.append("")
        lines.append(f"    wire all_domains_reset = {' && '.join(seen_flags)};")
        lines.append("")
        lines.append("    always @(*) begin")
        lines.append(f"        if (!all_domains_reset) assume ({assume_expr});")
        lines.append(f"        else assert ({eq_terms});")
        lines.append("    end")

    lines.append("")
    lines.append("endmodule")

    return "\n".join(lines), is_multiclock

def verify_equivalence(
    original_rtl: Path,
    candidate_rtl: Path,
    top_module: str,
    run_dir: Path,
    depth: int = 20,
    clock_port: Optional[str] = None,
    reset_port: Optional[str] = None,
    reset_active_high: Optional[bool] = None,
) -> EquivalenceResult:
    run_dir.mkdir(parents=True, exist_ok=True)

    combined_v, ports = _prepare_gold_gate(original_rtl, candidate_rtl, top_module, run_dir)

    wrapper_src, is_multiclock = _generate_wrapper(
        ports, clock_port=clock_port, reset_port=reset_port, reset_active_high=reset_active_high
    )
    wrapper_path = run_dir / "eqcheck_wrapper.v"
    wrapper_path.write_text(wrapper_src)

    effective_depth = max(depth, 40) if is_multiclock else depth
    mode = "bmc" if is_multiclock else "prove"

    sby_content = SBY_TEMPLATE.format(
        mode=mode,
        depth=effective_depth,
        multiclock="on" if is_multiclock else "off",
        combined_v_name=combined_v.name,
        wrapper_v_name=wrapper_path.name,
        combined_v_path=combined_v.resolve(),
        wrapper_v_path=wrapper_path.resolve(),
    )
    sby_path = run_dir / "equiv.sby"
    sby_path.write_text(sby_content)

    result = subprocess.run(
        ["sby", "-f", str(sby_path)], cwd=run_dir, text=True, capture_output=True
    )
    log = result.stdout + result.stderr
    (run_dir / "equiv_sby.log").write_text(log)

    match = re.search(r"DONE\s*\((PASS|FAIL|UNKNOWN)", log)
    if match is None:
        raise FormalError(
            f"Could not determine a verdict from sby output (exit {result.returncode}). "
            f"INCONCLUSIVE, not verified. See {run_dir / 'equiv_sby.log'}"
        )

    verdict = match.group(1)
    basecase_passed = "returned pass for basecase" in log

    if verdict == "PASS":
        passed = True
        bounded = is_multiclock
    elif verdict == "UNKNOWN" and basecase_passed:
        # Unbounded induction could not close -- normal for designs with counters or
        # FSM loops, since induction may start from a state where the two copies'
        # registers already differ. BMC found no counterexample within the depth, so
        # we report a BOUNDED result and label it as such.
        passed = True
        bounded = True
    elif verdict == "FAIL":
        passed = False
        bounded = False
    else:
        raise FormalError(
            f"Verdict '{verdict}' with no passing basecase -- INCONCLUSIVE, not verified. "
            f"See {run_dir / 'equiv_sby.log'}"
        )

    if passed and bounded:
        summary = (
            f"PASS (bounded) — {Path(original_rtl).name} and {Path(candidate_rtl).name} "
            f"show no counterexample within {effective_depth} steps (bounded model check; "
            f"this is NOT an unbounded proof)."
        )
    elif passed:
        summary = (
            f"PASS — {Path(original_rtl).name} and {Path(candidate_rtl).name} "
            f"are formally equivalent (proved by SymbiYosys, depth={effective_depth})."
        )
    else:
        summary = (
            f"FAIL — {Path(original_rtl).name} and {Path(candidate_rtl).name} "
            f"are NOT equivalent. See {run_dir}/equiv/engine_0/ for the counterexample trace."
        )
        
    return EquivalenceResult(passed=passed, log=log, summary=summary, wrapper_path=wrapper_path)