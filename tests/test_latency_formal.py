import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from rtlai.formal import verify_equivalence, FormalError

BASE = PROJECT_ROOT / "designs" / "lat_base.v"
PIPE = PROJECT_ROOT / "designs" / "lat_pipe.v"
RUNS = PROJECT_ROOT / "runs"

def check(label, offset, run_dir):
    print(f"\n--- {label} ---")
    try:
        r = verify_equivalence(
            original_rtl=BASE, candidate_rtl=PIPE, top_module="lat_test",
            run_dir=run_dir, latency_offset=offset,
        )
        print(f"passed={r.passed}")
        print(r.summary)
    except FormalError as e:
        print(f"FormalError: {e}")


if __name__ == "__main__":
    check("latency_offset=0 (expect FAIL)", 0, RUNS / "lat_off0")
    check("latency_offset=1 (expect PASS)", 1, RUNS / "lat_off1")