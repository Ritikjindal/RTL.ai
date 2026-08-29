# rtlai/synth.py

import subprocess
from pathlib import Path


class SynthesisError(RuntimeError):
    pass


SYNTH_TEMPLATE = """\
read_verilog {rtl_path}

hierarchy -top {top_module}

proc
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
    rtl_path: Path,
    top_module: str,
    lib_path: Path,
    netlist_v: Path,
    netlist_json: Path,
    run_dir: Path,
) -> str:
    """Generates a Yosys script parameterized for this specific run and
    executes it. Netlist outputs go wherever the caller points
    netlist_v/netlist_json — pass paths inside runs/<design>_<timestamp>/
    so concurrent or historical runs can never clobber each other.

    All path arguments should be absolute (resolve() them before calling)
    since the generated script's cwd is run_dir, not the caller's cwd.

    The generated .ys script is saved into run_dir alongside the netlist
    it produced, so every run is independently reproducible/inspectable.
    """
    netlist_v.parent.mkdir(parents=True, exist_ok=True)
    netlist_json.parent.mkdir(parents=True, exist_ok=True)

    script_content = SYNTH_TEMPLATE.format(
        rtl_path=Path(rtl_path).resolve(),
        top_module=top_module,
        lib_path=Path(lib_path).resolve(),
        netlist_v=netlist_v.resolve(),
        netlist_json=netlist_json.resolve(),
    )

    script_path = run_dir / "synth.ys"
    script_path.write_text(script_content)

    result = subprocess.run(
        ["yosys", "-s", str(script_path)],
        cwd=run_dir,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        raise SynthesisError(f"Yosys failed (exit {result.returncode}):\n{result.stderr}")
    return result.stdout