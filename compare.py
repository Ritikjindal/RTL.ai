#!/usr/bin/env python3
# compare.py — thin CLI entry point over rtlai.compare.
#
# Automatically finds the most recent run for DESIGN_NAME that has both
# a baseline and a candidate result. Becomes a real CLI argument once
# there's more than one design being actively compared.

from pathlib import Path

from rtlai.schema import RunResult
from rtlai.compare import compare_results

PROJECT_ROOT = Path(__file__).resolve().parent
RUNS_DIR = PROJECT_ROOT / "runs"

DESIGN_NAME = "traffic_light"


def find_latest_comparable_run(design_name: str) -> Path:
    """Finds the most recent run directory for this design that has both
    a baseline and a candidate result -- skips any baseline-only runs."""
    candidates = sorted(RUNS_DIR.glob(f"{design_name}_*"), reverse=True)
    for run_dir in candidates:
        if (run_dir / "baseline" / "result.json").exists() and (run_dir / "candidate" / "result.json").exists():
            return run_dir
    raise FileNotFoundError(
        f"No run with both baseline and candidate results found for '{design_name}' under {RUNS_DIR}"
    )


if __name__ == "__main__":
    run_dir = find_latest_comparable_run(DESIGN_NAME)
    print(f"Comparing results from: {run_dir}")

    baseline = RunResult.from_json(str(run_dir / "baseline" / "result.json"))
    candidate = RunResult.from_json(str(run_dir / "candidate" / "result.json"))
    compare_results(baseline, candidate)