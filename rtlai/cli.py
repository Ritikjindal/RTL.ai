# rtlai/cli.py
#
# Shared command-line interface for analyze.py and optimize.py.
#
# The goal: hand the tool RTL files and an SDC, and nothing else needs editing.
# Top module, design name and run folders are all derived.

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional

from rtlai.synth import detect_top_module

DEFAULT_LIB = Path("lib") / "NangateOpenCellLibrary_typical.lib"


@dataclass
class DesignConfig:
    rtl_files: List[Path]
    sdc_file: Path
    lib_file: Path
    top_module: str
    design_name: str
    candidate_files: Optional[List[Path]] = None


def build_parser(description: str, with_candidate: bool = False) -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=description)
    p.add_argument("--rtl", nargs="+", required=True, type=Path,
                   help="RTL source file(s). Shell globs work: designs/foo/*.v")
    p.add_argument("--sdc", required=True, type=Path,
                   help="SDC timing constraints file.")
    p.add_argument("--lib", type=Path, default=None,
                   help=f"Liberty file. Default: {DEFAULT_LIB}")
    p.add_argument("--top", default=None,
                   help="Top module name. If omitted, detected automatically.")
    p.add_argument("--name", default=None,
                   help="Design name for run folders. Defaults to the top module name.")
    if with_candidate:
        p.add_argument("--candidate", nargs="+", type=Path, default=None,
                       help="Candidate RTL to check against the baseline (A/B mode).")
    return p


def _resolve_files(paths, label: str) -> List[Path]:
    files = [Path(f).resolve() for f in paths]
    for f in files:
        if not f.exists():
            raise FileNotFoundError(f"{label} not found: {f}")
    return files


def resolve_config(args, project_root: Path) -> DesignConfig:
    """Turns parsed arguments into a DesignConfig, detecting the top module when
    it wasn't given."""
    rtl_files = _resolve_files(args.rtl, "RTL file")

    sdc_file = Path(args.sdc).resolve()
    if not sdc_file.exists():
        raise FileNotFoundError(f"SDC file not found: {sdc_file}")

    lib_file = Path(args.lib).resolve() if args.lib else (project_root / DEFAULT_LIB).resolve()
    if not lib_file.exists():
        raise FileNotFoundError(f"Liberty file not found: {lib_file}")

    top_module = args.top or detect_top_module(rtl_files, project_root / "runs" / "_detect")
    design_name = args.name or top_module

    candidate_files = None
    if getattr(args, "candidate", None):
        candidate_files = _resolve_files(args.candidate, "Candidate RTL file")

    return DesignConfig(
        rtl_files=rtl_files,
        sdc_file=sdc_file,
        lib_file=lib_file,
        top_module=top_module,
        design_name=design_name,
        candidate_files=candidate_files,
    )