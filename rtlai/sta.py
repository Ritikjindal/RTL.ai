# rtlai/sta.py

import subprocess
from pathlib import Path


class STAError(RuntimeError):
    pass


# NOTE: the activity assumptions (0.1 / 1.0 / 0.0) and the hard-coded
# "clk"/"rst" port names are carried over unchanged from the original
# sta_counter.tcl. They're Stage-0-specific and tied to the "make power
# activity configurable" item already on the Week 1 list — not solved
# here, just not made any worse.
STA_TEMPLATE = """\
read_liberty {lib_path}
read_verilog {netlist_v}
link_design {top_module}
read_sdc {sdc_path}

set clk_groups {{}}
foreach c [all_clocks] {{ lappend clk_groups [get_name $c] }}
report_checks -path_delay max -path_group $clk_groups -format full_clock_expanded > {timing_report}

set_power_activity -input -activity 0.1
set_power_activity -input_ports clk -activity 1.0
set_power_activity -input_ports rst -activity 0.0
report_power > {power_report}
"""


def run_sta(
    netlist_v: Path,
    sdc_path: Path,
    lib_path: Path,
    top_module: str,
    timing_report: Path,
    power_report: Path,
    run_dir: Path,
) -> str:
    timing_report.parent.mkdir(parents=True, exist_ok=True)
    power_report.parent.mkdir(parents=True, exist_ok=True)

    script_content = STA_TEMPLATE.format(
        lib_path=Path(lib_path).resolve(),
        netlist_v=netlist_v.resolve(),
        top_module=top_module,
        sdc_path=Path(sdc_path).resolve(),
        timing_report=timing_report.resolve(),
        power_report=power_report.resolve(),
    )

    script_path = run_dir / "sta.tcl"
    script_path.write_text(script_content)

    result = subprocess.run(
        ["sta", "-exit", str(script_path)],
        cwd=run_dir,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        raise STAError(f"OpenSTA failed (exit {result.returncode}):\n{result.stderr}")
    return result.stdout