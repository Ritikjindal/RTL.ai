# Prints exactly what the planner will be sent. No API calls.
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from rtlai.schema import RunResult
from rtlai.optimizer.planner import build_planner_prompt

RTL = PROJECT_ROOT / "designs" / "vec_proc.v"
RUNS = PROJECT_ROOT / "runs"


def find_latest_baseline(design_name: str) -> Path:
    hits = sorted(RUNS.glob(f"{design_name}_*/baseline/result.json"), reverse=True)
    if not hits:
        raise FileNotFoundError(f"No baseline result.json for '{design_name}' under {RUNS}")
    return hits[0]


if __name__ == "__main__":
    result_path = find_latest_baseline("vec_proc")
    print(f"# using {result_path}\n")
    baseline = RunResult.from_json(str(result_path))
    print(build_planner_prompt(RTL.read_text(), baseline))