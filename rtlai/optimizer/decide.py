# rtlai/optimizer/decide.py
from typing import Optional, Tuple

from rtlai.schema import RunResult

# Weights for the net-improvement score. Same spirit as config/targets.json's
# weights, but applied to improvement RELATIVE to the baseline rather than to
# absolute distance from a fixed target.
WEIGHT_AREA = 0.40
WEIGHT_TIMING = 0.30
WEIGHT_POWER = 0.30

# Reject a candidate if any single dimension regresses by more than this,
# even when the weighted net improvement is positive.
# Blocks catastrophic single-axis regressions (e.g. the hand-built ALU ripple-carry
# candidate, which lost 36% of max frequency). Deliberately loose enough to permit
# ordinary engineering trade-offs, since a net-positive weighted result already has
# to clear the bar on its own.
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

    Absolute target scores saturate: any design comfortably better than target
    clamps to 100 and stops differentiating, which is useless for ranking two
    good designs. Relative comparison needs no per-design tuning and works at
    any design scale.

    Note this scores TIMING on max frequency, not worst slack. Slack is measured
    against a fixed clock constraint, so a design can lose a third of its
    achievable frequency while its slack barely moves.

    Returns (accepted, human-readable reason).
    """
    dims = [
        ("area", WEIGHT_AREA,
         _pct_improvement(baseline.area.cell_area_um2, candidate.area.cell_area_um2, True)),
        ("max frequency", WEIGHT_TIMING,
         _pct_improvement(baseline.timing.max_frequency_mhz, candidate.timing.max_frequency_mhz, False)),
        ("power", WEIGHT_POWER,
         _pct_improvement(baseline.power.total_uw, candidate.power.total_uw, True)),
    ]

    missing = [name for name, _, value in dims if value is None]
    if missing:
        return False, f"Cannot decide: missing measurements for {', '.join(missing)}."

    regressions = [(name, value) for name, _, value in dims if value < -MAX_REGRESSION_PCT]
    if regressions:
        detail = ", ".join(f"{name} {value:+.1f}%" for name, value in regressions)
        return False, f"Rejected: unacceptable regression ({detail}); limit is {MAX_REGRESSION_PCT:.1f}%."

    net = sum(weight * value for _, weight, value in dims)
    breakdown = ", ".join(f"{name} {value:+.1f}%" for name, _, value in dims)

    if net > 0:
        return True, f"Accepted: net weighted improvement {net:+.1f}% ({breakdown})."
    return False, f"Rejected: net weighted improvement {net:+.1f}% is not positive ({breakdown})."