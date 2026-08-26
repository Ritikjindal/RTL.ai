#!/usr/bin/env python3

from pathlib import Path
import subprocess
import sys
import re
import json

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
JSON_NETLIST_FILE = NETLIST_DIR / "counter_netlist.json"
TIMING_REPORT = REPORT_DIR / "timing_auto.rpt"
POWER_REPORT = REPORT_DIR / "power_auto.rpt"

LIB_FILE = PROJECT_ROOT / "lib" / "NangateOpenCellLibrary_typical.lib"


# ===========================================================
# Utility functions
# ===========================================================

def run_command(command, cwd=None):
    print("\nCommand:")
    print(" ".join(str(x) for x in command))
    print()

    result = subprocess.run(
        command,
        cwd=cwd,
        text=True,
        capture_output=True
    )

    print(result.stdout)

    if result.stderr:
        print(result.stderr)

    if result.returncode != 0:
        print("\n==============================================")
        print("RTL.ai FLOW FAILED")
        print("==============================================")
        print(f"Command failed with return code {result.returncode}")
        sys.exit(result.returncode)

    return result.stdout + result.stderr

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

# Remove old netlist so a failed synthesis

# can never be mistaken for a successful run.

if NETLIST_FILE.exists():
    NETLIST_FILE.unlink()

if JSON_NETLIST_FILE.exists():
    JSON_NETLIST_FILE.unlink()

yosys_output = run_command(
    [
        "yosys",
        "-s",
        str(SYNTH_SCRIPT)
    ],
    cwd=SCRIPTS_DIR
)

check_file(NETLIST_FILE, "Generated netlist")

# ------------------------------------------------------------
# Check generated JSON netlist
# ------------------------------------------------------------

check_file(
    JSON_NETLIST_FILE,
    "Generated JSON netlist"
)

# ------------------------------------------------------------
# Extract synthesis statistics from Yosys JSON
# ------------------------------------------------------------

try:

    with open(JSON_NETLIST_FILE, "r") as f:
        netlist_data = json.load(f)

    module_data = netlist_data["modules"]["counter"]

    cells = module_data.get("cells", {})

    total_cells = len(cells)

    flip_flops = 0

    for cell_name, cell_data in cells.items():

        cell_type = cell_data.get("type", "")

        if "DFF" in cell_type.upper():
            flip_flops += 1

except (KeyError, json.JSONDecodeError, OSError) as e:

    print("\nWARNING: Unable to parse Yosys JSON netlist.")
    print(f"Reason: {e}")

    total_cells = None
    flip_flops = None
# ------------------------------------------------------------
# Extract Yosys cell area
# ------------------------------------------------------------

area_match = re.search(
    r"Chip area for module.*?([0-9]+\.[0-9]+)",
    yosys_output,
    re.IGNORECASE
)

if area_match:
    cell_area = float(area_match.group(1))
else:
    cell_area = None   

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

if POWER_REPORT.exists():
    POWER_REPORT.unlink()

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
if not TIMING_REPORT.exists() or TIMING_REPORT.stat().st_size == 0:
    print("\n==============================================")
    print("RTL.ai FLOW FAILED")
    print("==============================================")
    print("OpenSTA did not generate a valid timing report.")
    print(f"Expected report: {TIMING_REPORT}")
    sys.exit(1)

if not POWER_REPORT.exists() or POWER_REPORT.stat().st_size == 0:
    print("\n==============================================")
    print("RTL.ai FLOW FAILED")
    print("==============================================")
    print("OpenSTA did not generate a valid power report.")
    print(f"Expected report: {POWER_REPORT}")
    sys.exit(1)

print("\nOpenSTA timing analysis completed successfully.")
print(f"Generated timing report: {TIMING_REPORT}")
print(f"Generated power report: {POWER_REPORT}")

# ============================================================
# STEP 3 - Analyze timing and generate recommendation
# ============================================================

print("\n" + "=" * 70)
print("STEP 3/3 - Timing Analysis & Recommendation")
print("=" * 70)


report_text = TIMING_REPORT.read_text(errors="ignore")
power_report_text = POWER_REPORT.read_text(errors="ignore")

# ============================================================
# Extract power
# ============================================================

internal_power = None
switching_power = None
leakage_power = None
total_power = None

# OpenSTA reports power in Watts.
#
# Example:
#
# Total  1.23e-06  4.56e-07  7.89e-09  1.80e-06

power_match = re.search(
    r"Total\s+"
    r"([0-9.eE+-]+)\s+"
    r"([0-9.eE+-]+)\s+"
    r"([0-9.eE+-]+)\s+"
    r"([0-9.eE+-]+)",
    power_report_text
)

if power_match:
    internal_power = float(power_match.group(1))
    switching_power = float(power_match.group(2))
    leakage_power = float(power_match.group(3))
    total_power = float(power_match.group(4))


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
# PPA SCORE
# ============================================================

TARGET_AREA = 60.0       # µm²
TARGET_POWER = 10.0      # µW
TARGET_SLACK = 1.0       # ns


def clamp(value, minimum=0.0, maximum=100.0):
    return max(minimum, min(maximum, value))


area_score = None
timing_score = None
power_score = None
ppa_score = None


# ------------------------------------------------------------
# Area score
# ------------------------------------------------------------

if cell_area is not None:
    area_score = clamp(
        (TARGET_AREA / cell_area) * 100.0
    )


# ------------------------------------------------------------
# Timing / performance score
# ------------------------------------------------------------

if slack is not None:

    timing_score = clamp(
        (slack / TARGET_SLACK) * 100.0
    )


# ------------------------------------------------------------
# Power score
# ------------------------------------------------------------

if total_power is not None:

    power_uW = total_power * 1e6

    power_score = clamp(
        (TARGET_POWER / power_uW) * 100.0
    )


# ------------------------------------------------------------
# Overall PPA score
# ------------------------------------------------------------

if (
    area_score is not None
    and timing_score is not None
    and power_score is not None
):

    ppa_score = (
        0.40 * area_score +
        0.30 * timing_score +
        0.30 * power_score
    )

# ============================================================
# Display results
# ============================================================

print("\nArea Summary")
print("-" * 40)

if cell_area is not None:
    print(f"Cell Area          : {cell_area:.3f} µm²")
else:
    print("Cell Area          : Not found")

if total_cells is not None:
    print(f"Total Cells        : {total_cells}")
else:
    print("Total Cells        : Not found")

if flip_flops is not None:
    print(f"Flip-Flops         : {flip_flops}")
else:
    print("Flip-Flops         : Not found")

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

print("\nPower Summary")
print("-" * 40)

if internal_power is not None:
    print(f"Internal Power     : {internal_power * 1e6:.3f} µW")
else:
    print("Internal Power     : Not found")

if switching_power is not None:
    print(f"Switching Power    : {switching_power * 1e6:.3f} µW")
else:
    print("Switching Power    : Not found")

if leakage_power is not None:
    print(f"Leakage Power      : {leakage_power * 1e6:.3f} µW")
else:
    print("Leakage Power      : Not found")

if total_power is not None:
    print(f"Total Power        : {total_power * 1e6:.3f} µW")
else:
    print("Total Power        : Not found")


# ============================================================
# PPA SCORE
# ============================================================

print("\nPPA Score")
print("-" * 40)

if area_score is not None:
    print(f"Area Score         : {area_score:.1f} / 100")
else:
    print("Area Score         : Not available")

if timing_score is not None:
    print(f"Performance Score  : {timing_score:.1f} / 100")
else:
    print("Performance Score  : Not available")

if power_score is not None:
    print(f"Power Score        : {power_score:.1f} / 100")
else:
    print("Power Score        : Not available")

if ppa_score is not None:
    print(f"Overall PPA Score  : {ppa_score:.1f} / 100")
else:
    print("Overall PPA Score  : Not available")

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

    print("\nPossible optimizations:")
    print("- Reduce combinational logic depth.")
    print("- Optimize high-fanout nets.")
    print("- Use faster standard cells where appropriate.")
    print("- Consider restructuring the RTL.")

else:

    print("TIMING PASSED.")
    print("No setup timing violation was detected.")

    if total_power is not None:

        power_uW = total_power * 1e6

        print(f"Estimated Total Power: {power_uW:.3f} µW")

        if power_uW > TARGET_POWER:
            print("Power is above the target.")
            print(
                "Recommendation: investigate switching activity "
                "and unnecessary logic."
            )
        else:
            print("Power is within the target range.")

    if slack > 1.0:

        print("There is substantial positive timing margin.")

        if ppa_score is not None and ppa_score < 70:

            print(
                "PPA score indicates that area optimization "
                "may be beneficial."
            )

            print("Recommended direction:")
            print("- Reduce unnecessary combinational logic.")
            print("- Reduce cell count where possible.")
            print("- Investigate opportunities for smaller cells.")

        else:

            print(
                "The design has a good area/timing balance."
            )

    else:

        print("Timing margin is relatively small.")

        print(
            "Prioritize timing preservation during RTL optimization."
        )
if ppa_score is not None:

    print("\nPPA Assessment")
    print("-" * 40)

    if ppa_score >= 90:
        print("Excellent PPA characteristics.")
    elif ppa_score >= 75:
        print("Good PPA characteristics.")
    elif ppa_score >= 60:
        print("Moderate PPA characteristics.")
    else:
        print("PPA optimization recommended.")
# ============================================================
# Final result
# ============================================================

print("\n" + "=" * 70)
print("RTL.ai FLOW COMPLETED SUCCESSFULLY")
print("=" * 70)

print(f"\nNetlist : {NETLIST_FILE}")
print(f"Report  : {TIMING_REPORT}")