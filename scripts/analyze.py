#!/usr/bin/env python3

from pathlib import Path
import re


# ============================================================
# RTL.ai - PPA Report Analyzer
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent
REPORTS_DIR = PROJECT_ROOT / "reports"

AREA_REPORT = REPORTS_DIR / "area.rpt"
TIMING_REPORT = REPORTS_DIR / "timing.rpt"


# ============================================================
# File utilities
# ============================================================

def read_report(path):
    if not path.exists():
        raise FileNotFoundError(f"Report not found: {path}")

    return path.read_text()


def extract_number(pattern, text, default=None):
    match = re.search(pattern, text)

    if match:
        return float(match.group(1))

    return default


# ============================================================
# AREA ANALYSIS
# ============================================================

def analyze_area():

    text = read_report(AREA_REPORT)

    total_area = extract_number(
        r"Chip area for module.*?:\s*([0-9.]+)",
        text
    )

    sequential_area = extract_number(
        r"used for sequential elements:\s*([0-9.]+)",
        text
    )

    sequential_percent = extract_number(
        r"\(([0-9.]+)%\)",
        text
    )

    # Flip-flops from the cell table
    flip_flops = extract_number(
        r"\n\s*(\d+)\s+DFF_X1",
        text
    )

    if total_area is not None and sequential_area is not None:
        combinational_area = total_area - sequential_area
    else:
        combinational_area = None

    return {
        "total_area": total_area,
        "sequential_area": sequential_area,
        "combinational_area": combinational_area,
        "sequential_percent": sequential_percent,
        "flip_flops": flip_flops,
    }


# ============================================================
# TIMING ANALYSIS
# ============================================================

def analyze_timing():

    text = read_report(TIMING_REPORT)

    wns = extract_number(
        r"wns max\s+([-0-9.]+)",
        text
    )

    tns = extract_number(
        r"tns max\s+([-0-9.]+)",
        text
    )

    slack = extract_number(
        r"([-0-9.]+)\s+slack\s+\(MET\)",
        text
    )

    # Use worst path slack to determine timing status.
    if slack is not None:
        timing_pass = slack >= 0
    else:
        timing_pass = False

    return {
        "wns": wns,
        "tns": tns,
        "slack": slack,
        "timing_pass": timing_pass,
    }


# ============================================================
# RECOMMENDATION ENGINE
# ============================================================

def generate_recommendation(area, timing):

    slack = timing["slack"]

    area_value = area["total_area"]

    print()
    print("RECOMMENDATION")
    print("-" * 60)

    if slack is None:
        print("Unable to determine timing status.")
        return

    if slack < 0:
        print("Timing violation detected.")
        print("Priority: PERFORMANCE / TIMING OPTIMIZATION")

    elif slack < 1.0:
        print("Timing is met, but the timing margin is small.")
        print("Priority: TIMING OPTIMIZATION")

    else:
        print("Timing is comfortably met.")

        if area_value is not None:
            print("Priority: AREA OPTIMIZATION")
        else:
            print("Area data unavailable.")

    print()


# ============================================================
# REPORT
# ============================================================

def print_report(area, timing):

    print()
    print("=" * 60)
    print("                     RTL.ai")
    print("                  PPA ANALYSIS")
    print("=" * 60)

    # --------------------------------------------------------
    # DESIGN
    # --------------------------------------------------------

    print()
    print("DESIGN")
    print("-" * 60)

    print("Design                  : counter")

    # --------------------------------------------------------
    # AREA
    # --------------------------------------------------------

    print()
    print("AREA")
    print("-" * 60)

    if area["total_area"] is not None:
        print(f"Total Area             : {area['total_area']:.3f}")
    else:
        print("Total Area             : N/A")

    if area["sequential_area"] is not None:
        print(
            f"Sequential Area        : "
            f"{area['sequential_area']:.3f}"
        )
    else:
        print("Sequential Area        : N/A")

    if area["combinational_area"] is not None:
        print(
            f"Combinational Area     : "
            f"{area['combinational_area']:.3f}"
        )
    else:
        print("Combinational Area     : N/A")

    if area["sequential_percent"] is not None:
        print(
            f"Sequential Area %      : "
            f"{area['sequential_percent']:.2f}%"
        )
    else:
        print("Sequential Area %      : N/A")

    if area["flip_flops"] is not None:
        print(
            f"Flip-Flops             : "
            f"{int(area['flip_flops'])}"
        )
    else:
        print("Flip-Flops             : N/A")

    # --------------------------------------------------------
    # TIMING
    # --------------------------------------------------------

    print()
    print("TIMING")
    print("-" * 60)

    if timing["wns"] is not None:
        print(f"WNS                    : {timing['wns']:.3f} ns")
    else:
        print("WNS                    : N/A")

    if timing["tns"] is not None:
        print(f"TNS                    : {timing['tns']:.3f} ns")
    else:
        print("TNS                    : N/A")

    if timing["slack"] is not None:
        print(
            f"Worst Slack            : "
            f"{timing['slack']:.3f} ns"
        )
    else:
        print("Worst Slack            : N/A")

    # --------------------------------------------------------
    # STATUS
    # --------------------------------------------------------

    print()
    print("STATUS")
    print("-" * 60)

    if timing["timing_pass"]:
        print("Timing                 : PASS")
    else:
        print("Timing                 : FAIL")

    # --------------------------------------------------------
    # Recommendation
    # --------------------------------------------------------

    generate_recommendation(area, timing)

    # --------------------------------------------------------
    # PPA SCORE
    # --------------------------------------------------------

    ppa_score = calculate_ppa_score(
        area["total_area"],
        timing["slack"]
    )

    print()
    print("PPA SCORE")
    print("-" * 60)

    if ppa_score is not None:
        print(f"PPA Score              : {ppa_score:.3f}")
    else:
        print("PPA Score              : N/A")

    print()
    print("=" * 60)
    print()

def calculate_ppa_score(area, slack):
    """
    Calculate a simple PPA score.

    Lower area is better.
    Higher timing slack is better.
    """

    if area <= 0:
        return None

    timing_factor = 1.0

    if slack < 0:
        timing_factor += abs(slack) * 10
    else:
        timing_factor = 1.0 / (1.0 + slack)

    score = area * timing_factor

    return score

# ============================================================
# MAIN
# ============================================================

def main():

    try:

        area = analyze_area()
        timing = analyze_timing()
        print_report(area, timing)

    except FileNotFoundError as error:

        print()
        print(f"ERROR: {error}")
        print()
        print("Run the RTL synthesis/STA flow first.")
        print()

    except Exception as error:

        print()
        print(f"ERROR: {error}")
        print()


if __name__ == "__main__":
    main()