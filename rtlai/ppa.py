# rtlai/ppa.py

import json
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Optional

from rtlai.schema import AreaResult, TimingResult, PowerResult, PPAResult

DEFAULT_TARGETS_PATH = Path(__file__).resolve().parent.parent / "config" / "targets.json"


@dataclass
class PPATargets:
    """Target metrics used to normalize raw measurements into 0-100
    scores. These are project-defined targets, not industry standards
    (see docs/ppa_methodology.md) -- change them by editing
    config/targets.json, not by hand-editing this file per run.
    """
    target_area_um2: float = 60.0
    target_power_uw: float = 10.0
    target_slack_ns: float = 1.0

    # Weights for the overall score. Must sum to 1.0 -- checked at load
    # time, not silently renormalized, so a typo is caught immediately
    # instead of quietly skewing every score.
    weight_area: float = 0.40
    weight_timing: float = 0.30
    weight_power: float = 0.30

    @staticmethod
    def load(path: Optional[Path] = None) -> "PPATargets":
        path = path or DEFAULT_TARGETS_PATH
        if not path.exists():
            return PPATargets()  # built-in defaults, same as the old hardcoded values

        with open(path) as f:
            data = json.load(f)
        targets = PPATargets(**data)
        targets.validate()
        return targets

    def validate(self) -> None:
        total_weight = self.weight_area + self.weight_timing + self.weight_power
        if abs(total_weight - 1.0) > 1e-6:
            raise ValueError(
                f"PPA weights must sum to 1.0, got {total_weight} "
                f"(area={self.weight_area}, timing={self.weight_timing}, power={self.weight_power})"
            )


def _clamp(value: float, minimum: float = 0.0, maximum: float = 100.0) -> float:
    return max(minimum, min(maximum, value))


def score_ppa(
    area: AreaResult,
    timing: TimingResult,
    power: PowerResult,
    targets: Optional[PPATargets] = None,
) -> PPAResult:
    """Scores one run's metrics against `targets`. Each sub-score is a
    target-vs-measured ratio clamped to [0, 100]. This is intentionally
    the same formula as the original analyze.py -- the goal here is
    configurability, not a methodology change (that's a separate,
    bigger discussion for docs/ppa_methodology.md)."""
    targets = targets or PPATargets.load()
    result = PPAResult()

    if area.cell_area_um2 is not None and area.cell_area_um2 > 0:
        result.area_score = _clamp((targets.target_area_um2 / area.cell_area_um2) * 100.0)

    if timing.worst_slack_ns is not None:
        result.timing_score = _clamp((timing.worst_slack_ns / targets.target_slack_ns) * 100.0)

    if power.total_uw is not None and power.total_uw > 0:
        result.power_score = _clamp((targets.target_power_uw / power.total_uw) * 100.0)

    if None not in (result.area_score, result.timing_score, result.power_score):
        result.overall_score = (
            targets.weight_area * result.area_score
            + targets.weight_timing * result.timing_score
            + targets.weight_power * result.power_score
        )

    return result


def assess_ppa(ppa: PPAResult) -> str:
    """Rule-based qualitative label, same thresholds as the current
    analyze.py. Kept separate from scoring so a future GenAI-based
    assessment can replace just this function later."""
    if ppa.overall_score is None:
        return "PPA score not available."
    if ppa.overall_score >= 90:
        return "Excellent PPA characteristics."
    elif ppa.overall_score >= 75:
        return "Good PPA characteristics."
    elif ppa.overall_score >= 60:
        return "Moderate PPA characteristics."
    else:
        return "PPA optimization recommended."