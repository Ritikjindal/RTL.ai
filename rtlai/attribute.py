# rtlai/attribute.py — work out which RTL module owns a timing path.
#
# OpenSTA names the critical path's CLOCK but its cell names are abc-generated, with
# no hierarchy and no source attributes, so the netlist cannot tell us which module a
# path lives in. The clock can: a module instance's clock connection says which domain
# it belongs to. This scans the top-level RTL for instances whose clock port is wired
# to the critical clock, and returns those module names as the candidates to optimize.
#
# This is deliberately a source-level scan rather than a netlist analysis. It relies
# only on instances connecting a port whose name contains "clk" or "clock", which is
# true of essentially all synchronous RTL.

import re
from rtlai.modules import find_modules, list_modules, locate_module
from pathlib import Path
from typing import Dict, List, Sequence, Tuple

from rtlai.modules import find_modules, list_modules

CLOCK_PORT_RE = re.compile(r"\.\s*(\w*(?:clk|clock)\w*)\s*\(", re.IGNORECASE)


def _connection_list(text: str, open_paren: int) -> Tuple[str, int]:
    """Return the text inside a balanced paren group starting at `open_paren`."""
    depth = 0
    for i in range(open_paren, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return text[open_paren + 1:i], i
    raise ValueError("unbalanced parentheses in instantiation")


def find_instances(top_text: str, module_names: Sequence[str]) -> List[Tuple[str, str, str]]:
    """
    Find instantiations of any of `module_names` inside `top_text`.

    Returns (module_name, instance_name, connection_text) per instance.
    """
    instances: List[Tuple[str, str, str]] = []

    for name in module_names:
        pattern = re.compile(
            r"\b" + re.escape(name) + r"\b\s*"      # module name
            r"(?:#\s*\([^;]*?\)\s*)?"               # optional parameter override
            r"([A-Za-z_]\w*)\s*\(",                 # instance name, then connections
        )
        for m in pattern.finditer(top_text):
            try:
                conns, _ = _connection_list(top_text, m.end() - 1)
            except ValueError:
                continue
            instances.append((name, m.group(1), conns))

    return instances


def modules_on_clock(
    paths: Sequence[Path],
    top_module: str,
    clock: str,
) -> List[str]:
    """
    Module names instantiated in `top_module` whose clock port is driven by `clock`.

    Matching is word-boundary exact, so a master clock does not match its own divided
    clock (clk_a does not match clk_a_div) -- those are separate path groups in STA and
    should be attributed separately.
    """
    index = list_modules(paths)

    top_path = index.get(top_module)
    if top_path is None:
        raise ValueError(f"top module '{top_module}' not found in the given files")

    top_text = ""
    for loc in find_modules(Path(top_path).read_text()):
        if loc.name == top_module:
            top_text = loc.text
            break

    others = [n for n in index if n != top_module]
    clock_re = re.compile(r"\b" + re.escape(clock) + r"\b")

    hits: List[str] = []
    for module_name, _inst, conns in find_instances(top_text, others):
        for pm in CLOCK_PORT_RE.finditer(conns):
            try:
                driver, _ = _connection_list(conns, pm.end() - 1)
            except ValueError:
                continue
            if clock_re.search(driver):
                if module_name not in hits:
                    hits.append(module_name)
                break

    return hits

CLOCK_PORT_DECL_RE = re.compile(
    r"\b(input|output)\b[^;,)]*?\b(\w*(?:clk|clock)\w*)\b", re.IGNORECASE
)


def _clock_port_count(module_text: str) -> Tuple[int, int]:
    """(clock inputs, clock outputs) declared by a module."""
    header_end = module_text.find(");")
    header = module_text[:header_end if header_end > 0 else len(module_text)]
    ins = outs = 0
    for direction, _name in CLOCK_PORT_DECL_RE.findall(header):
        if direction.lower() == "input":
            ins += 1
        else:
            outs += 1
    return ins, outs

PORT_RANGE_RE = re.compile(r"\b(?:input|output|inout)\b[^;,)]*?\[[^\]]+\]")


def _has_datapath_ports(module_text: str) -> bool:
    """
    True if the module has at least one multi-bit port.

    A module whose every port is a single bit is control or synchronizer logic, not a
    datapath block: there is nothing to restructure, and rewriting it is actively
    unsafe. SymbiYosys models no metastability, so it would prove a one-flop
    synchronizer "equivalent" to a two-flop one and the optimizer would happily accept
    the smaller, broken version.
    """
    header_end = module_text.find(");")
    header = module_text[:header_end if header_end > 0 else len(module_text)]
    return PORT_RANGE_RE.search(header) is not None

def optimizable_modules(
    paths: Sequence[Path],
    top_module: str,
    clock: str,
) -> List[str]:
    """
    Candidate modules for optimization on `clock`, best first.

    Two structural exclusions, both for correctness rather than convenience:

      * More than one clock input -- a multi-clock module takes the bounded-BMC path
        in formal.py and cannot use latency-offset checking, so a pipelined candidate
        could never be proven.
      * A clock output -- the module generates a clock; restructuring it changes the
        clock tree, which STA constrains by name and which no equivalence check covers.

    Clock-domain-crossing and reset synchronizers are the dangerous case and are caught
    by the first rule (handshakes) or should be left alone on principle: SymbiYosys
    models no metastability, so it would prove a one-flop synchronizer "equivalent" to
    a two-flop one. Ranking by source size puts real payload blocks first, and the
    caller should take the top candidate rather than iterating down the list.
    """
    index = list_modules(paths)
    candidates = modules_on_clock(paths, top_module, clock)

    ranked: List[Tuple[int, str]] = []
    for name in candidates:
        loc = locate_module(paths, name)
        clk_in, clk_out = _clock_port_count(loc.text)
        if clk_in > 1 or clk_out > 0:
            continue
        if not _has_datapath_ports(loc.text):
            continue
        ranked.append((len(loc.text), name))

    ranked.sort(reverse=True)
    return [name for _size, name in ranked]