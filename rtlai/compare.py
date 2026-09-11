# rtlai/compare.py
#
# Prints a baseline-vs-candidate comparison report. Refuses to compare
# numbers for a candidate that hasn't been proven formally equivalent --
# a broken design's PPA numbers are meaningless, and printing them next
# to the baseline as if they were a fair comparison would be actively
# misleading.

from typing import Optional

from rtlai.schema import RunResult


def pct_delta(baseline: Optional[float], candidate: Optional[float]) -> str:
    if baseline is None or candidate is None:
        return "n/a"
    if baseline == 0:
        return "n/a"
    # A percentage across a sign change is meaningless (e.g. slack -0.22 -> +0.11),
    # so report the absolute movement instead.
    if (baseline < 0) != (candidate < 0):
        return f"{candidate - baseline:+.2f} abs"
    return f"{(candidate - baseline) / baseline * 100:+.1f}%"


def compare_results(baseline: RunResult, candidate: RunResult) -> None:
    if not candidate.formal_checked:
        print("Cannot compare: candidate was never formally checked against the baseline.")
        return
    if not candidate.formal_passed:
        print("Cannot compare: candidate FAILED formal equivalence against the baseline.")
        print(f"  {candidate.formal_summary}")
        return
    if candidate.formal_baseline_rtl_path != baseline.rtl_path:
        print("Cannot compare: candidate was formally checked against a different baseline.")
        print(f"  Candidate was checked against: {candidate.formal_baseline_rtl_path}")
        print(f"  Baseline provided here is:     {baseline.rtl_path}")
        return

    print("\n" + "=" * 70)
    print(f"Comparison: {baseline.design_name}  vs.  {candidate.design_name}")
    print("=" * 70)
    print(f"Formal equivalence: {candidate.formal_summary}")

    rows = [
        ("Cell area (um2)",   baseline.area.cell_area_um2,        candidate.area.cell_area_um2),
        ("Total cells",       baseline.area.total_cells,          candidate.area.total_cells),
        ("Flip-flops",        baseline.area.flip_flops,           candidate.area.flip_flops),
        ("Worst slack (ns)",  baseline.timing.worst_slack_ns,     candidate.timing.worst_slack_ns),
        ("Max freq (MHz)",    baseline.timing.max_frequency_mhz,  candidate.timing.max_frequency_mhz),
        ("Total power (uW)",  baseline.power.total_uw,            candidate.power.total_uw),
        ("PPA overall score", baseline.ppa.overall_score,         candidate.ppa.overall_score),
    ]

    print(f"\n{'Metric':<20}{'Baseline':>15}{'Candidate':>15}{'Delta':>12}")
    print("-" * 62)
    for label, b_val, c_val in rows:
        b_str = "n/a" if b_val is None else f"{b_val:g}"
        c_str = "n/a" if c_val is None else f"{c_val:g}"
        print(f"{label:<20}{b_str:>15}{c_str:>15}{pct_delta(b_val, c_val):>12}")