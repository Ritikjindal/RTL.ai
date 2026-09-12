import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from rtlai.formal import verify_equivalence, FormalError

FILES = sorted((PROJECT_ROOT / "designs" / "benchmark").glob("sha256*.v"))

if __name__ == "__main__":
    print("files:", [f.name for f in FILES])
    try:
        r = verify_equivalence(
            original_rtl=FILES, candidate_rtl=FILES, top_module="sha256",
            run_dir=PROJECT_ROOT / "runs" / "sha_multifile_selfcheck",
        )
        print(f"passed={r.passed}")
        print(r.summary)
    except FormalError as e:
        print(f"FormalError: {e}")