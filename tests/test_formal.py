# tests/test_formal.py — run with: python3 tests/test_formal.py

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from rtlai.formal import verify_equivalence

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DESIGNS = PROJECT_ROOT / "designs"
RUNS = PROJECT_ROOT / "runs" / "formal_smoke_test"

# Case 1: a design checked against itself must PASS.
result_self = verify_equivalence(
    original_rtl=DESIGNS / "counter.v",
    candidate_rtl=DESIGNS / "counter.v",
    top_module="counter",
    run_dir=RUNS / "self_check",
)
print("Self-check:", result_self.summary)
assert result_self.passed, "A design MUST be equivalent to itself — formal.py is broken."

# Case 2: a deliberately broken variant must FAIL.
result_broken = verify_equivalence(
    original_rtl=DESIGNS / "counter.v",
    candidate_rtl=DESIGNS / "counter_broken.v",
    top_module="counter",
    run_dir=RUNS / "broken_check",
)
print("Broken-check:", result_broken.summary)
assert not result_broken.passed, "formal.py did not catch a real functional difference — it's not actually checking anything."

print("\nBoth checks behaved correctly — formal.py is validated.")