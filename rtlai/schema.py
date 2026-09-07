# rtlai/schema.py

from dataclasses import dataclass, asdict, field
from typing import Optional
import json


@dataclass
class TimingResult:
    worst_slack_ns: Optional[float] = None
    data_arrival_time_ns: Optional[float] = None
    data_required_time_ns: Optional[float] = None
    startpoint: Optional[str] = None
    endpoint: Optional[str] = None
    clock: Optional[str] = None
    path_type: Optional[str] = None
    logic_depth: Optional[int] = None          # number of cells on the critical path
    max_frequency_mhz: Optional[float] = None  # derived: 1 / (period - slack)


@dataclass
class PowerResult:
    internal_uw: Optional[float] = None
    switching_uw: Optional[float] = None
    leakage_uw: Optional[float] = None
    total_uw: Optional[float] = None


@dataclass
class AreaResult:
    cell_area_um2: Optional[float] = None
    total_cells: Optional[int] = None
    flip_flops: Optional[int] = None


@dataclass
class PPAResult:
    area_score: Optional[float] = None
    timing_score: Optional[float] = None
    power_score: Optional[float] = None
    overall_score: Optional[float] = None


@dataclass
class RunResult:
    """The single machine-readable record for one analyze.py run.

    This is the contract every other module (optimizer, comparator,
    demo) reads and writes against. Add fields here, not ad-hoc keys
    elsewhere.
    """
    design_name: str
    rtl_path: str
    sdc_path: str
    timestamp: str                 # ISO 8601, set by the caller
    timing: TimingResult = field(default_factory=TimingResult)
    power: PowerResult = field(default_factory=PowerResult)
    area: AreaResult = field(default_factory=AreaResult)
    ppa: PPAResult = field(default_factory=PPAResult)
    timing_passed: Optional[bool] = None   # slack >= 0
    notes: list[str] = field(default_factory=list)  # free-text warnings, e.g. "area not found"
    formal_checked: bool = False
    formal_passed: Optional[bool] = None
    formal_summary: Optional[str] = None

    def to_json(self, path: str) -> None:
        with open(path, "w") as f:
            json.dump(asdict(self), f, indent=2)

    @staticmethod
    def from_json(path: str) -> "RunResult":
        with open(path) as f:
            data = json.load(f)
        return RunResult(
            design_name=data["design_name"],
            rtl_path=data["rtl_path"],
            sdc_path=data["sdc_path"],
            timestamp=data["timestamp"],
            timing=TimingResult(**data.get("timing", {})),
            power=PowerResult(**data.get("power", {})),
            area=AreaResult(**data.get("area", {})),
            ppa=PPAResult(**data.get("ppa", {})),
            timing_passed=data.get("timing_passed"),
            notes=data.get("notes", []),
        )