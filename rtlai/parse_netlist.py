# rtlai/parse_netlist.py

import json
import re
from typing import Optional, Tuple
from rtlai.schema import AreaResult

# Matches Yosys `stat -liberty` output, e.g.:
#   Chip area for module '\counter': 57.988000
AREA_RE = re.compile(r"Chip area for module.*?([0-9]+\.[0-9]+)", re.IGNORECASE)


def parse_json_netlist(json_path: str, top_module: str) -> Tuple[Optional[int], Optional[int]]:
    """Returns (total_cells, flip_flops) from a Yosys JSON netlist."""
    with open(json_path) as f:
        netlist_data = json.load(f)

    module_data = netlist_data["modules"][top_module]
    cells = module_data.get("cells", {})

    total_cells = len(cells)
    flip_flops = sum(1 for c in cells.values() if "DFF" in c.get("type", "").upper())

    return total_cells, flip_flops


def parse_yosys_area(yosys_stdout: str) -> Optional[float]:
    """Extracts the reported chip area (um^2) from Yosys stdout."""
    m = AREA_RE.search(yosys_stdout)
    return float(m.group(1)) if m else None


def build_area_result(json_path: str, top_module: str, yosys_stdout: str) -> AreaResult:
    result = AreaResult()

    try:
        total_cells, flip_flops = parse_json_netlist(json_path, top_module)
        result.total_cells = total_cells
        result.flip_flops = flip_flops
    except (KeyError, json.JSONDecodeError, OSError):
        pass  # left as None — caller should log this into RunResult.notes

    result.cell_area_um2 = parse_yosys_area(yosys_stdout)
    return result