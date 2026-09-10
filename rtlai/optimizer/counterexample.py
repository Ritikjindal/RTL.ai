# rtlai/optimizer/counterexample.py
from pathlib import Path
from typing import Optional


def extract_counterexample(formal_run_dir: Path, max_chars: int = 3000) -> Optional[str]:
    """
    Finds the SymbiYosys counterexample testbench from a failed equivalence check and pulls
    out the input stimulus that triggers the mismatch. Design-agnostic: it works off whatever
    input ports the trace happens to drive.

    Returns plain text, or None if no trace was found.
    """
    candidates = list(Path(formal_run_dir).glob("**/trace_tb.v"))
    if not candidates:
        return None

    keep = []
    recording = False
    for line in candidates[0].read_text().splitlines():
        stripped = line.strip()
        if stripped.startswith("// state "):
            recording = True
        if not recording:
            continue
        if stripped.startswith("genclock"):
            break
        if stripped.startswith("// state ") or stripped.startswith("PI_"):
            keep.append(stripped)

    if not keep:
        return None

    body = "\n".join(keep)
    if len(body) > max_chars:
        body = body[:max_chars] + "\n... (truncated)"
    return body