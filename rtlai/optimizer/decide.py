# rtlai/optimizer/decide.py
from typing import Optional, Tuple

from rtlai.schema import RunResult

# Balanced weights, used when the baseline already meets its timing constraint.
BALANCED_WEIGHTS = {"area": 0.40, "max frequency": 0.30, "power": 0.30}

# Timing-closure weights, used when the baseline VIOLATES its constraint. The brief is
# about closing timing: when the design is failing, frequency is what matters and
# area/power are almost irrelevant.
CLOSURE_WEIGHTS = {"area": 0.10, "max frequency": 0.80, "power": 0.10}

# Rejects catastrophic single-axis regressions (e.g. the hand-built ALU ripple-carry
# candidate, which lost 36% of max frequency). Deliberately loose enough to permit
# ordinary engineering trade-offs, since a net-positive weighted result already has to
# clear the bar on its own.
MAX_REGRESSION_PCT = 25.0


def _pct_improvement(baseline: Optional[float], candidate: Optional[float], lower_is_better: bool) -> Optional[float]:
    if baseline is None or candidate is None or baseline == 0:
        return None
    if lower_is_better:
        return (baseline - candidate) / baseline * 100.0
    return (candidate - baseline) / baseline * 100.0


def decide(baseline: RunResult, candidate: RunResult) -> Tuple[bool, str]:
    """
    Decides whether to accept a formally-equivalent candidate by comparing it
    RELATIVELY against the baseline, not against fixed absolute targets.

    Absolute target scores saturate: any design comfortably better than target clamps
    to 100 and stops differentiating, which is useless for ranking two good designs.
    Relative comparison needs no per-design tuning and works at any design scale.

    The weighting mirrors the planner's priority rules. If the baseline VIOLATES its
    timing constraint, closing timing is the only goal that matters, so frequency
    dominates and a candidate that doesn't get faster is rejected outright. If timing
    is already met, area/timing/power are weighted in balance.

    Note this scores TIMING on max frequency, not worst slack. Slack is measured
    against a fixed clock constraint, so a design can lose a third of its achievable
    frequency while its slack barely moves.

    Returns (accepted, human-readable reason).
    """
    closing_timing = baseline.timing_passed is False
    weights = CLOSURE_WEIGHTS if closing_timing else BALANCED_WEIGHTS
    mode = "timing-closure" if closing_timing else "balanced"

    dims = [
        ("area", weights["area"],
         _pct_improvement(baseline.area.cell_area_um2, candidate.area.cell_area_um2, True)),
        ("max frequency", weights["max frequency"],
         _pct_improvement(baseline.timing.max_frequency_mhz, candidate.timing.max_frequency_mhz, False)),
        ("power", weights["power"],
         _pct_improvement(baseline.power.total_uw, candidate.power.total_uw, True)),
    ]

    missing = [name for name, _, value in dims if value is None]
    if missing:
        return False, f"Cannot decide: missing measurements for {', '.join(missing)}."

    by_name = {name: value for name, _, value in dims}
    breakdown = ", ".join(f"{name} {value:+.1f}%" for name, _, value in dims)

    # When the baseline is failing timing, a candidate that doesn't make it faster is
    # not a solution, whatever it does for area or power.
    if closing_timing and by_name["max frequency"] <= 0:
        return False, (
            f"Rejected [{mode}]: baseline violates timing and this candidate does not improve "
            f"max frequency ({breakdown})."
        )

    regressions = [(name, value) for name, _, value in dims if value < -MAX_REGRESSION_PCT]
    if regressions:
        detail = ", ".join(f"{name} {value:+.1f}%" for name, value in regressions)
        return False, (
            f"Rejected [{mode}]: unacceptable regression ({detail}); "
            f"limit is {MAX_REGRESSION_PCT:.1f}%."
        )

    net = sum(weight * value for _, weight, value in dims)

    if net > 0:
        return True, f"Accepted [{mode}]: net weighted improvement {net:+.1f}% ({breakdown})."
    return False, f"Rejected [{mode}]: net weighted improvement {net:+.1f}% is not positive ({breakdown})."