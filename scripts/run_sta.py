#!/usr/bin/env python3

from pathlib import Path
import subprocess


# ============================================================
# Paths
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

NETLIST_FILE = PROJECT_ROOT / "netlist" / "counter_netlist.v"
SDC_FILE = PROJECT_ROOT / "constraints" / "counter.sdc"
STA_SCRIPT = PROJECT_ROOT / "scripts" / "sta_counter.tcl"
REPORT_FILE = PROJECT_ROOT / "reports" / "timing_auto.rpt"


# ============================================================
# Run OpenSTA
# ============================================================

def run_sta():

    if not NETLIST_FILE.exists():   
        raise FileNotFoundError(
            f"Netlist not found: {NETLIST_FILE}"
        )

    if not SDC_FILE.exists():
        raise FileNotFoundError(
            f"SDC file not found: {SDC_FILE}"
        )

    if not STA_SCRIPT.exists():
        raise FileNotFoundError(
            f"STA script not found: {STA_SCRIPT}"
        )

    REPORT_FILE.parent.mkdir(exist_ok=True)

    print()
    print("=" * 60)
    print("RTL.ai - OpenSTA Timing Analysis")
    print("=" * 60)

    print(f"Netlist : {NETLIST_FILE}")
    print(f"SDC     : {SDC_FILE}")
    print(f"Report  : {REPORT_FILE}")
    print()

    command = [
    "sta",
    str(STA_SCRIPT)
    ]

    print("Running OpenSTA...")
    print()

    result = subprocess.run(
    command,
    capture_output=True,
    text=True
)

    print(result.stdout)

    if result.returncode != 0:
        print("OpenSTA failed:")
        print(result.stderr)
        raise RuntimeError("OpenSTA timing analysis failed")

    print("OpenSTA timing analysis completed successfully.")

    if result.returncode != 0:
        print(result.stderr)
        raise RuntimeError("OpenSTA timing analysis failed.")

    print("=" * 60)
    print("OpenSTA timing analysis completed successfully.")
    print("=" * 60)
    print()

    print(f"Generated timing report:")
    print(REPORT_FILE)


# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":
    run_sta()