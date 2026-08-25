#!/usr/bin/env python3

from pathlib import Path
import subprocess
import sys
import re


# ============================================================
# RTL.ai - Automated RTL Analysis Flow
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

SCRIPTS_DIR = PROJECT_ROOT / "scripts"
DESIGN_DIR = PROJECT_ROOT / "designs"
NETLIST_DIR = PROJECT_ROOT / "netlist"
REPORT_DIR = PROJECT_ROOT / "reports"

SYNTH_SCRIPT = SCRIPTS_DIR / "synth_counter.ys"
STA_SCRIPT = SCRIPTS_DIR / "sta_counter.tcl"

NETLIST_FILE = NETLIST_DIR / "counter_netlist.v"
TIMING_REPORT = REPORT_DIR / "timing_auto.rpt"

LIB_FILE = PROJECT_ROOT / "lib" / "NangateOpenCellLibrary_typical.lib"


# ============================================================
# Utility functions
# ============================================================

def run_command(command, cwd=None):
    print("\nCommand:")
    print(" ".join(str(x) for x in command))
    print()

    result = subprocess.run(
        command,
        cwd=cwd,
        text=True
    )

    if result.returncode != 0:
        print("\n==============================================")
        print("RTL.ai FLOW FAILED")
        print("==============================================")
        print(f"Command failed with return code {result.returncode}")
        sys.exit(result.returncode)


def check_file(path, name):
    if not path.exists():
        print(f"\nERROR: {name} not found:")
        print(path)
        sys.exit(1)


# ============================================================
# Create directories
# ============================================================

NETLIST_DIR.mkdir(exist_ok=True)
REPORT_DIR.mkdir(exist_ok=True)


print("=" * 70)
print("RTL.ai - Automated RTL Analysis Flow")
print("=" * 70)

print(f"Project root: {PROJECT_ROOT}")


# ============================================================
# STEP 1 - Yosys synthesis
# ============================================================

print("\n" + "=" * 70)
print("STEP 1/3 - Yosys Synthesis")
print("=" * 70)

check_file(SYNTH_SCRIPT, "Yosys synthesis script")
check_file(DESIGN_DIR / "counter.v", "RTL design")
check_file(LIB_FILE, "Standard-cell library")

run_command(
    [
        "yosys",
        "-s",
        str(SYNTH_SCRIPT)
    ],
    cwd=SCRIPTS_DIR
)

check_file(NETLIST_FILE, "Generated netlist")

print("\nYosys synthesis completed successfully.")
print(f"Generated netlist: {NETLIST_FILE}")


# ============================================================
# STEP 2 - OpenSTA
# ============================================================

print("\n" + "=" * 70)
print("STEP 2/3 - OpenSTA Timing Analysis")
print("=" * 70)

check_file(STA_SCRIPT, "OpenSTA script")

# Remove old report so that we don't accidentally
# interpret an old report as a new successful run.
if TIMING_REPORT.exists():
    TIMING_REPORT.unlink()

run_command(
    [
        "sta",
        "-exit",
        str(STA_SCRIPT)
    ],
    cwd=SCRIPTS_DIR
)

# IMPORTANT:
# Do not claim success unless the report was actually created.
if not TIMING_REPORT.exists():
    print("\n==============================================")
    print("RTL.ai FLOW FAILED")
    print("==============================================")
    print("OpenSTA finished without creating the timing report.")
    print(f"Expected report: {TIMING_REPORT}")
    sys.exit(1)

print("\nOpenSTA timing analysis completed successfully.")
print(f"Generated timing report: {TIMING_REPORT}")


# ============================================================
# STEP 3 - Analyze timing and generate recommendation
# ============================================================

print("\n" + "=" * 70)
print("STEP 3/3 - Timing Analysis & Recommendation")
print("=" * 70)


report_text = TIMING_REPORT.read_text(errors="ignore")


# ------------------------------------------------------------
# Extract worst slack
# ------------------------------------------------------------

slack_match = re.search(
    r"([-+]?\d+\.\d+)\s+slack\s+\(MET\)",
    report_text
)

if slack_match:
    slack = float(slack_match.group(1))
else:
    slack = None


# ------------------------------------------------------------
# Extract data arrival time
# ------------------------------------------------------------

arrival_match = re.search(
    r"([-+]?\d+\.\d+)\s+data arrival time",
    report_text
)

arrival_time = float(arrival_match.group(1)) if arrival_match else None


# ------------------------------------------------------------
# Extract data required time
# ------------------------------------------------------------

required_match = re.search(
    r"([-+]?\d+\.\d+)\s+data required time",
    report_text
)

required_time = (
    float(required_match.group(1))
    if required_match
    else None
)


# ============================================================
# Display results
# ============================================================

print("\nTiming Summary")
print("-" * 40)

if slack is not None:
    print(f"Worst Slack        : {slack:.3f} ns")
else:
    print("Worst Slack        : Not found")

if arrival_time is not None:
    print(f"Data Arrival Time  : {arrival_time:.3f} ns")
else:
    print("Data Arrival Time  : Not found")

if required_time is not None:
    print(f"Data Required Time : {required_time:.3f} ns")
else:
    print("Data Required Time : Not found")


# ============================================================
# Recommendation
# ============================================================

print("\nRecommendation")
print("-" * 40)

if slack is None:

    print("Unable to determine timing status from the report.")

elif slack < 0:

    print("TIMING VIOLATION detected.")
    print("Recommendation: optimize the critical timing path.")

    if arrival_time is not None:
        print(
            f"The critical path requires approximately "
            f"{arrival_time:.3f} ns of propagation delay."
        )

    print("Possible optimizations:")
    print("- Reduce combinational logic depth.")
    print("- Optimize high-fanout nets.")
    print("- Use faster standard cells where appropriate.")
    print("- Consider restructuring the RTL.")

else:

    print("TIMING PASSED.")
    print("No setup timing violation was detected.")

    if slack > 1.0:
        print(
            "There is substantial positive timing margin. "
            "The design may have room for area or power optimization."
        )
    else:
        print(
            "Timing margin is relatively small. "
            "Further RTL changes should be made carefully."
        )


# ============================================================
# Final result
# ============================================================

print("\n" + "=" * 70)
print("RTL.ai FLOW COMPLETED SUCCESSFULLY")
print("=" * 70)

print(f"\nNetlist : {NETLIST_FILE}")
print(f"Report  : {TIMING_REPORT}")