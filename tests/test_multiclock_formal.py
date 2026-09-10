from pathlib import Path
from rtlai.formal import verify_equivalence, FormalError

PROJECT_ROOT = Path(__file__).resolve().parent
DESIGN = PROJECT_ROOT / "designs" / "cdc_counter.v"
BROKEN = PROJECT_ROOT / "designs" / "cdc_counter_broken.v"
RUNS = PROJECT_ROOT / "runs"


def check(label, a, b, run_dir):
    print(f"\n--- {label} ---")
    try:
        r = verify_equivalence(original_rtl=a, candidate_rtl=b, top_module="cdc_counter", run_dir=run_dir)
        print(f"passed={r.passed}")
        print(r.summary)
    except FormalError as e:
        print(f"FormalError: {e}")


if __name__ == "__main__":
    check("self-check (expect PASS)", DESIGN, DESIGN, RUNS / "cdc_selfcheck")
    check("broken variant (expect FAIL)", DESIGN, BROKEN, RUNS / "cdc_brokencheck")