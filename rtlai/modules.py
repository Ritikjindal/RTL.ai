# rtlai/modules.py — locate and replace individual Verilog modules within a file set.
#
# The optimizer shows the planner a whole design but asks the coder to rewrite a
# single module. That needs two operations this file provides:
#   (a) pull one module's source out of whichever file defines it, and
#   (b) write the design back out with that module replaced and nothing else touched.
#
# Verilog has no nested modules, so a scan for `module <name> ... endmodule` is
# sufficient and avoids needing a real parser. Comments and string literals are masked
# before scanning so a stray "endmodule" in a comment cannot truncate a module.

import re
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Sequence

MODULE_RE = re.compile(r"\bmodule\s+(\\\S+|[A-Za-z_][A-Za-z0-9_$]*)")
ENDMODULE_RE = re.compile(r"\bendmodule\b")


class ModuleError(RuntimeError):
    pass


@dataclass
class ModuleLocation:
    """Where a module's source lives: which file, and the span within it."""
    name: str
    path: Path
    start: int          # index of the 'm' in 'module'
    end: int            # index just past 'endmodule'
    text: str           # the module source itself


def _mask(text: str) -> str:
    """
    Return a copy of `text` with comments and string literals blanked to spaces,
    preserving every character position so match offsets index correctly into the
    original. Newlines are kept so line structure is unchanged.
    """
    out = list(text)
    i, n = 0, len(text)

    while i < n:
        two = text[i:i + 2]

        if two == "//":
            while i < n and text[i] != "\n":
                out[i] = " "
                i += 1
        elif two == "/*":
            out[i] = out[i + 1] = " "
            i += 2
            while i < n and text[i:i + 2] != "*/":
                if text[i] != "\n":
                    out[i] = " "
                i += 1
            if i < n:
                out[i] = out[i + 1] = " "
                i += 2
        elif text[i] == '"':
            out[i] = " "
            i += 1
            while i < n and text[i] != '"':
                if text[i] == "\\" and i + 1 < n:
                    out[i] = " "
                    i += 1
                if i < n and text[i] != "\n":
                    out[i] = " "
                i += 1
            if i < n:
                out[i] = " "
                i += 1
        else:
            i += 1

    return "".join(out)


def find_modules(text: str) -> List[ModuleLocation]:
    """Every module defined in one file's text, in order of appearance."""
    masked = _mask(text)
    found: List[ModuleLocation] = []

    for m in MODULE_RE.finditer(masked):
        name = m.group(1)
        end_m = ENDMODULE_RE.search(masked, m.end())
        if end_m is None:
            raise ModuleError(f"module '{name}' has no matching endmodule")
        found.append(
            ModuleLocation(
                name=name,
                path=Path(),           # filled in by the file-level helpers
                start=m.start(),
                end=end_m.end(),
                text=text[m.start():end_m.end()],
            )
        )

    return found


def list_modules(paths: Sequence[Path]) -> Dict[str, Path]:
    """Map every module name in the file set to the file that defines it."""
    index: Dict[str, Path] = {}

    for p in paths:
        p = Path(p)
        for loc in find_modules(p.read_text()):
            if loc.name in index:
                raise ModuleError(
                    f"module '{loc.name}' is defined in both {index[loc.name]} and {p}"
                )
            index[loc.name] = p

    return index


def locate_module(paths: Sequence[Path], name: str) -> ModuleLocation:
    """Find one module by name across the file set."""
    for p in paths:
        p = Path(p)
        text = p.read_text()
        for loc in find_modules(text):
            if loc.name == name:
                loc.path = p
                return loc

    known = ", ".join(sorted(list_modules(paths))) or "(none)"
    raise ModuleError(f"module '{name}' not found in the given files. Defined: {known}")


def patch_design(
    paths: Sequence[Path],
    location: ModuleLocation,
    new_module_text: str,
    out_dir: Path,
) -> List[Path]:
    """
    Write the whole design into `out_dir` with `location`'s module replaced by
    `new_module_text`. Every other file is copied byte-for-byte, so a change to one
    module cannot disturb the rest of the design.

    Returns the new paths in the same order as `paths`.
    """
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    written: List[Path] = []
    seen_target = False

    for p in paths:
        p = Path(p)
        dest = out_dir / p.name

        if p.resolve() == location.path.resolve():
            original = p.read_text()
            dest.write_text(
                original[:location.start] + new_module_text.strip() + original[location.end:]
            )
            seen_target = True
        else:
            shutil.copyfile(p, dest)

        written.append(dest)

    if not seen_target:
        raise ModuleError(
            f"{location.path} (which defines '{location.name}') was not in the file list"
        )

    return written