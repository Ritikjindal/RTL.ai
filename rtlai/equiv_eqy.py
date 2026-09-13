# rtlai/equiv_eqy.py — equivalence checking via eqy (register matching + partitioning).
#
# Complements the SymbiYosys miter in formal.py. The two answer the same question by
# very different means, and each is right for a different kind of transform:
#
#   * formal.py builds a miter of the two designs and unrolls time. That handles
#     transforms which CHANGE the register set -- pipelining, retiming -- via the
#     latency-offset mechanism, but the unrolled formula grows with depth and with
#     datapath width, which is what defeats it on wide arithmetic.
#
#   * eqy MATCHES registers between the two designs by name and proves each
#     combinational cone separately. No unrolling, so it scales where the miter does
#     not -- but it requires the register sets to correspond, so it cannot express a
#     pipelining change at all, and it proves cones for ALL register values, including
#     states the design can never reach.
#
# So: eqy for LATENCY_OFFSET == 0 transforms (logic restructuring, resource sharing,
# re-encoding that preserves state), SymbiYosys for everything else. Note that eqy is
# NOT a way around the reachability problem -- a transform correct only because some
# register is one-hot will be reported as non-equivalent, correctly from eqy's point
# of view and unhelpfully from ours.

import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Sequence, Union

PathLike = Union[str, Path]


class EqyError(RuntimeError):
    pass


@dataclass
class EqyResult:
    passed: bool
    summary: str
    log_path: Path


EQY_TEMPLATE = """\
[gold]
read -sv {gold_files}
prep -top {top_module}

[gate]
read -sv {gate_files}
prep -top {top_module}

[strategy sat]
use sat
depth {depth}
"""


def _as_list(paths) -> List[Path]:
    if isinstance(paths, (str, Path)):
        return [Path(paths)]
    return [Path(p) for p in paths]


def _display(paths: Sequence[Path]) -> str:
    names = [p.name for p in paths]
    return names[0] if len(names) == 1 else f"{names[0]} (+{len(names) - 1} more)"


def verify_equivalence_eqy(
    original_rtl: PathLike,
    candidate_rtl: PathLike,
    top_module: str,
    run_dir: Path,
    depth: int = 5,
    timeout_s: int = 300,
) -> EqyResult:
    """
    Prove `top_module` equivalent between the two file sets using eqy.

    Only valid for transforms that do NOT change latency: eqy matches registers between
    the designs, so an added pipeline stage has nothing to match against.
    """
    gold = _as_list(original_rtl)
    gate = _as_list(candidate_rtl)
    run_dir = Path(run_dir)
    run_dir.mkdir(parents=True, exist_ok=True)

    cfg = EQY_TEMPLATE.format(
        depth=depth,
        top_module=top_module,
        gold_files=" ".join(str(p.resolve()) for p in gold),
        gate_files=" ".join(str(p.resolve()) for p in gate),
    )
    cfg_path = run_dir / "equiv.eqy"
    cfg_path.write_text(cfg)

    try:
        proc = subprocess.run(
            ["eqy", "-f", str(cfg_path.resolve())],
            cwd=run_dir, text=True, capture_output=True, timeout=timeout_s,
        )
    except FileNotFoundError:
        raise EqyError("eqy is not on PATH. It ships with oss-cad-suite.")
    except subprocess.TimeoutExpired:
        raise EqyError(
            f"eqy TIMED OUT after {timeout_s}s -- neither proven equivalent nor "
            f"proven different. See {run_dir}"
        )

    log = proc.stdout + proc.stderr
    log_path = run_dir / "equiv_eqy.log"
    log_path.write_text(log)

    name_a, name_b = _display(gold), _display(gate)

    if re.search(r"Successfully proved designs equivalent", log) or \
       re.search(r"Status:\s*PASSED", log):
        return EqyResult(
            passed=True,
            summary=(f"PASS — {name_a} and {name_b} are formally equivalent "
                     f"(proved by eqy, register-matched partitions)."),
            log_path=log_path,
        )

    if re.search(r"Status:\s*FAILED", log) or re.search(r"not equivalent", log, re.I):
        return EqyResult(
            passed=False,
            summary=(f"FAIL — {name_a} and {name_b} are NOT equivalent according to eqy. "
                     f"See {log_path}"),
            log_path=log_path,
        )

    raise EqyError(
        f"Could not determine a verdict from eqy (exit {proc.returncode}). "
        f"INCONCLUSIVE, not verified. See {log_path}"
    )