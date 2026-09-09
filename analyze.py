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
CANDIDATE_RTL = PROJECT_ROOT / "designs" / "counter_broken.v"
SDC_FILE = PROJECT_ROOT / "constraints" / "counter.sdc"
LIB_FILE = PROJECT_ROOT / "lib" / "NangateOpenCellLibrary_typical.lib"

def analyze_design(rtl_path: Path, design_name: str, run_dir: Path, timestamp: str) -> RunResult:
    """Synthesizes one RTL file and runs STA on it, returning its RunResult.
    Formal equivalence is handled separately by the caller, since it's an
    RTL-level check that doesn't need a netlist at all."""
    run_dir.mkdir(parents=True, exist_ok=True)

    netlist_v = run_dir / "netlist" / f"{design_name}_netlist.v"
    netlist_json = run_dir / "netlist" / f"{design_name}_netlist.json"
    timing_report = run_dir / "reports" / "timing.rpt"
    power_report = run_dir / "reports" / "power.rpt"

    result = RunResult(
        design_name=design_name,
        rtl_path=str(rtl_path),
        sdc_path=str(SDC_FILE),
        timestamp=timestamp,
    )

    try:
        yosys_stdout = run_yosys(
            rtl_path=rtl_path,
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

    result.to_json(str(run_dir / "result.json"))
    return result


def run_baseline():
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    run_dir = RUNS_DIR / f"{DESIGN_NAME}_{timestamp}"

    print(f"[1/4] Running Yosys synthesis + OpenSTA on baseline '{DESIGN_NAME}'...")
    baseline_result = analyze_design(
        rtl_path=RTL_FILE,
        design_name=DESIGN_NAME,
        run_dir=run_dir / "baseline",
        timestamp=timestamp,
    )
    print(f"      Done: {run_dir / 'baseline' / 'result.json'}")
    candidate_result = None

    

    if CANDIDATE_RTL is not None:
        formal_dir = run_dir / "formal"
        print("[2/4] Checking formal equivalence: baseline vs candidate...")
        try:
            eq_result = verify_equivalence(
                original_rtl=RTL_FILE,
                candidate_rtl=CANDIDATE_RTL,
                top_module=TOP_MODULE,
                run_dir=formal_dir,
            )
            formal_passed = eq_result.passed
            formal_summary = eq_result.summary
        except FormalError as e:
            formal_passed = False
            formal_summary = str(e)

        if formal_passed:
            print(f"      {formal_summary}")
            print("[3/4] Running Yosys synthesis + OpenSTA on candidate...")
            candidate_result = analyze_design(
                rtl_path=CANDIDATE_RTL,
                design_name=f"{DESIGN_NAME}_candidate",
                run_dir=run_dir / "candidate",
                timestamp=timestamp,
            )
            candidate_result.formal_checked = True
            candidate_result.formal_passed = True
            candidate_result.formal_summary = formal_summary
            candidate_result.to_json(str(run_dir / "candidate" / "result.json"))
            print(f"      Done: {run_dir / 'candidate' / 'result.json'}")
        else:
            print(f"     {formal_summary}")
            print("[3/4] Skipping candidate synthesis — not formally equivalent to baseline.")
    else:
        print("[2/4] No candidate set — skipping equivalence check.")


    print(f"[4/4] All run artifacts under: {run_dir}")
    return baseline_result, candidate_result


def print_summary(result: RunResult) -> None:
    print("\n" + "=" * 60)
    print(f"RTL.ai — {result.design_name}")
    print("=" * 60)

    if result.formal_checked:
        print("\nFormal Equivalence")
        print(f"  Passed  : {result.formal_passed}")
        print(f"  Summary : {result.formal_summary}")


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
    baseline_result, candidate_result = run_baseline()
    print_summary(baseline_result)
    if candidate_result is not None:
        print_summary(candidate_result)