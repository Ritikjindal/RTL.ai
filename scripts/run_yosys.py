#!/usr/bin/env python3

from pathlib import Path
import subprocess


PROJECT_ROOT = Path(__file__).resolve().parent.parent

SYNTH_SCRIPT = PROJECT_ROOT / "scripts" / "synth_counter.ys"
NETLIST_FILE = PROJECT_ROOT / "netlist" / "counter_netlist.v"


def run_yosys():

    print("=" * 60)
    print("RTL.ai - Yosys Synthesis")
    print("=" * 60)

    print()
    print("Running Yosys...")

    result = subprocess.run(
        ["yosys", str(SYNTH_SCRIPT)],
        cwd=PROJECT_ROOT / "scripts",
        capture_output=True,
        text=True
    )

    print(result.stdout)

    if result.returncode != 0:
        print("Yosys synthesis FAILED.")
        print(result.stderr)
        return False

    if not NETLIST_FILE.exists():
        print("Yosys finished, but netlist was not generated.")
        return False

    print()
    print("Yosys synthesis completed successfully.")
    print()
    print("Generated netlist:")
    print(NETLIST_FILE)

    return True


if __name__ == "__main__":
    run_yosys()