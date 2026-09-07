#!/usr/bin/env python3
# analyze.py — thin CLI entry point over the rtlai package.

import sys
from pathlib import Path
from datetime import datetime, timezone

from rtlai.synth import run_yosys, SynthesisError
from rtlai.sta import run_sta, STAError
from rtlai.parse_timing import parse_timing_report
from rtlai.parse_power import parse_power_report
from rtlai.parse_netlist import build_area_result
from rtlai.ppa import score_ppa, assess_ppa
from rtlai.schema import RunResult
from rtlai.formal import verify_equivalence, FormalError

PROJECT_ROOT = Path(__file__).resolve().parent
RUNS_DIR = PROJECT_ROOT / "runs"

# Stage 0 bring-up config. Becomes CLI args once there's more than one design.
DESIGN_NAME = "counter"
TOP_MODULE = "counter"
RTL_FILE = PROJECT_ROOT / "designs" / "counter.v"
SDC_FILE = PROJECT_ROOT / "constraints" / "counter.sdc"
LIB_FILE = PROJECT_ROOT / "lib" / "NangateOpenCellLibrary_typical.lib"


def run_baseline() -> RunResult:
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    run_dir = RUNS_DIR / f"{DESIGN_NAME}_{timestamp}"
    run_dir.mkdir(parents=True, exist_ok=True)

    netlist_v = run_dir / "netlist" / f"{DESIGN_NAME}_netlist.v"
    netlist_json = run_dir / "netlist" / f"{DESIGN_NAME}_netlist.json"
    timing_report = run_dir / "reports" / "timing.rpt"
    power_report = run_dir / "reports" / "power.rpt"

    result = RunResult(
        design_name=DESIGN_NAME,
        rtl_path=str(RTL_FILE),
        sdc_path=str(SDC_FILE),
        timestamp=timestamp,
    )

    formal_dir = run_dir / "formal"
    print(f"[1/4] Running formal equivalence check for '{DESIGN_NAME}'...")
    try:
        eq_result = verify_equivalence(
            original_rtl=RTL_FILE,
            candidate_rtl=RTL_FILE,
            top_module=TOP_MODULE,
            run_dir=formal_dir,
        )
        result.formal_checked = True
        result.formal_passed = eq_result.passed
        result.formal_summary = eq_result.summary
    except FormalError as e:
        result.formal_checked = True
        result.formal_passed = False
        result.formal_summary = str(e)
        result.notes.append(f"Formal equivalence check error: {e}")

    print(f"[2/4] Running Yosys synthesis for '{DESIGN_NAME}'...")

    try:
        yosys_stdout = run_yosys(
            rtl_path=RTL_FILE,
            top_module=TOP_MODULE,
            lib_path=LIB_FILE,
            netlist_v=netlist_v,
            netlist_json=netlist_json,
            run_dir=run_dir,
        )
    except SynthesisError as e:
        result.notes.append(f"Synthesis failed: {e}")
        result.to_json(str(run_dir / "result.json"))
        print(e)
        sys.exit(1)

    if not netlist_json.exists():
        result.notes.append("Synthesis reported success but JSON netlist was not generated.")
    else:
        result.area = build_area_result(str(netlist_json), TOP_MODULE, yosys_stdout)

    print("[3/4] Running OpenSTA timing + power analysis...")
    try:
        run_sta(
            netlist_v=netlist_v,
            sdc_path=SDC_FILE,
            lib_path=LIB_FILE,
            top_module=TOP_MODULE,
            timing_report=timing_report,
            power_report=power_report,
            run_dir=run_dir,
        )
    except STAError as e:
        result.notes.append(f"OpenSTA failed: {e}")
        result.to_json(str(run_dir / "result.json"))
        print(e)
        sys.exit(1)

    if not timing_report.exists() or timing_report.stat().st_size == 0:
        result.notes.append("OpenSTA did not produce a valid timing report.")
    else:
        result.timing = parse_timing_report(timing_report.read_text(errors="ignore"))
        if result.timing.worst_slack_ns is not None:
            result.timing_passed = result.timing.worst_slack_ns >= 0

    if not power_report.exists() or power_report.stat().st_size == 0:
        result.notes.append("OpenSTA did not produce a valid power report.")
    else:
        result.power = parse_power_report(power_report.read_text(errors="ignore"))

    result.ppa = score_ppa(result.area, result.timing, result.power)

    print("[4/4] Writing result.json...")
    result_path = run_dir / "result.json"
    result.to_json(str(result_path))
    print(f"\nResult written to: {result_path}")
    print(f"All run artifacts: {run_dir}")

    return result


def print_summary(result: RunResult) -> None:
    print("\n" + "=" * 60)
    print(f"RTL.ai — {result.design_name}")
    print("=" * 60)

    print("\nFormal Equivalence")
    if result.formal_checked:
        print(f"  Passed  : {result.formal_passed}")
        print(f"  Summary : {result.formal_summary}")
    else:
        print("  (not checked)")


    a, t, p = result.area, result.timing, result.power

    print("\nArea")
    print(f"  Cell area   : {a.cell_area_um2}")
    print(f"  Total cells : {a.total_cells}")
    print(f"  Flip-flops  : {a.flip_flops}")

    print("\nTiming")
    print(f"  Startpoint     : {t.startpoint}")
    print(f"  Endpoint       : {t.endpoint}")
    print(f"  Clock          : {t.clock}")
    print(f"  Logic depth    : {t.logic_depth}")
    print(f"  Arrival time   : {t.data_arrival_time_ns} ns")
    print(f"  Required time  : {t.data_required_time_ns} ns")
    print(f"  Worst slack    : {t.worst_slack_ns} ns")
    print(f"  Max frequency  : {t.max_frequency_mhz} MHz")
    print(f"  Timing passed  : {result.timing_passed}")

    print("\nPower")
    print(f"  Internal   : {p.internal_uw} uW")
    print(f"  Switching  : {p.switching_uw} uW")
    print(f"  Leakage    : {p.leakage_uw} uW")
    print(f"  Total      : {p.total_uw} uW")

    print("\nPPA Score")
    print(f"  Area score     : {result.ppa.area_score}")
    print(f"  Timing score   : {result.ppa.timing_score}")
    print(f"  Power score    : {result.ppa.power_score}")
    print(f"  Overall score  : {result.ppa.overall_score}")
    print(f"  Assessment     : {assess_ppa(result.ppa)}")
    
    if result.notes:
        print("\nNotes")
        for n in result.notes:
            print(f"  - {n}")


if __name__ == "__main__":
    result = run_baseline()
    print_summary(result)