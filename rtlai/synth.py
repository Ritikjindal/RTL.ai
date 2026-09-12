# rtlai/synth.py

import json
import re
import subprocess
from pathlib import Path


class SynthesisError(RuntimeError):
    pass


def _as_list(paths):
    """Accepts a single path or a list of them, so single-file callers keep working."""
    if isinstance(paths, (str, Path)):
        return [Path(paths)]
    return [Path(p) for p in paths]


DETECT_TOP_TEMPLATE = """\
{read_lines}
hierarchy -auto-top
proc
write_json {ports_json}
"""


def detect_top_module(rtl_paths, work_dir: Path) -> str:
    """Asks Yosys which module is the top -- the one nothing else instantiates.
    Saves having to name it for every design."""
    rtl_paths = _as_list(rtl_paths)
    work_dir.mkdir(parents=True, exist_ok=True)
    ports_json = work_dir / "detect_top.json"
    read_lines = "\n".join(f"read_verilog -sv {p.resolve()}" for p in rtl_paths)

    script_path = work_dir / "detect_top.ys"
    script_path.write_text(
        DETECT_TOP_TEMPLATE.format(read_lines=read_lines, ports_json=ports_json.resolve())
    )

    result = subprocess.run(
                ["yosys", "-s", str(script_path.resolve())], cwd=work_dir, text=True, capture_output=True
    )
    (work_dir / "detect_top.log").write_text(result.stdout + result.stderr)

    if result.returncode != 0 or not ports_json.exists():
        raise SynthesisError(
            f"Could not determine the top module (yosys exit {result.returncode}). "
            f"Pass --top explicitly. See {work_dir / 'detect_top.log'}"
        )

    with open(ports_json) as f:
        data = json.load(f)

    tops = [
        name for name, mod in data.get("modules", {}).items()
        if int(mod.get("attributes", {}).get("top", "0"), 2)
    ]
    if len(tops) != 1:
        raise SynthesisError(
            f"Expected exactly one top module, found {tops or 'none'}. Pass --top explicitly."
        )
    return tops[0]


# `hierarchy -check` makes Yosys fail loudly when a module is missing, instead of
# silently leaving it as a blackbox -- which is how a 50k-cell benchmark once
# synthesized to 260 cells without any error.
#
# `flatten` collapses the whole hierarchy into the top module before mapping.
# Without it, parameterized submodules survive as separate `$paramod$...` modules
# that never reach abc, so they are neither mapped to standard cells nor counted
# in the area report -- and OpenSTA cannot parse their mangled names at all.
SYNTH_TEMPLATE = """\
{read_lines}

hierarchy -check -top {top_module}

proc
flatten
opt

memory
opt

techmap
opt

dfflibmap -liberty {lib_path}

abc -liberty {lib_path}

clean

stat -liberty {lib_path}

write_verilog -noattr {netlist_v}

write_json {netlist_json}
"""


def run_yosys(
    rtl_paths,
    top_module: str,
    lib_path: Path,
    netlist_v: Path,
    netlist_json: Path,
    run_dir: Path,
) -> str:
    """Generates a Yosys script parameterized for this specific run and executes it.

    `rtl_paths` may be a single path or a list -- one `read_verilog` line is emitted
    per file, so multi-file designs need no concatenation.

    Netlist outputs go wherever the caller points netlist_v/netlist_json — pass
    paths inside runs/<design>_<timestamp>/ so concurrent or historical runs can
    never clobber each other.

    All path arguments should be absolute (resolve() them before calling) since the
    generated script's cwd is run_dir, not the caller's cwd.

    The generated .ys script is saved into run_dir alongside the netlist it
    produced, so every run is independently reproducible/inspectable.
    """
    rtl_paths = _as_list(rtl_paths)
    netlist_v.parent.mkdir(parents=True, exist_ok=True)
    netlist_json.parent.mkdir(parents=True, exist_ok=True)

    read_lines = "\n".join(f"read_verilog -sv {p.resolve()}" for p in rtl_paths)

    script_content = SYNTH_TEMPLATE.format(
        read_lines=read_lines,
        top_module=top_module,
        lib_path=Path(lib_path).resolve(),
        netlist_v=netlist_v.resolve(),
        netlist_json=netlist_json.resolve(),
    )

    script_path = run_dir / "synth.ys"
    script_path.write_text(script_content)

    result = subprocess.run(
        ["yosys", "-s", str(script_path.resolve())],
        cwd=run_dir,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        raise SynthesisError(f"Yosys failed (exit {result.returncode}):\n{result.stderr}")

    # OpenSTA's Verilog netlist reader does not accept `signed` in wire or port
    # declarations and fails with a syntax error. Signedness carries no meaning for
    # static timing analysis -- only structure does -- so strip it from the netlist
    # Yosys emitted. Designs with signed arithmetic (DSP, filters) hit this
    # immediately.
    netlist_text = netlist_v.read_text()
    netlist_v.write_text(re.sub(r"\bsigned\s+", "", netlist_text))

    return result.stdout