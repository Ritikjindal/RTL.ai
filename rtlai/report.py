# rtlai/report.py
#
# Two report generators, both reading only what a run of optimize.py leaves on disk
# under its run_dir -- no re-running of any tool, no access to the live process.
#
#   build_formal_report(run_dir)  -> the equivalence report (what was proven, how, and
#                                     what was not)
#   build_change_summary(run_dir) -> the 1-2 page PPA summary (what changed and why)
#
# Both return Markdown. render_markdown_html / render_markdown_pdf turn that Markdown
# into the two downloadable formats the web UI offers.
#
# Every number here is re-derived from the same artifacts optimize.py wrote (result.json,
# summary.json, the formal/eqy logs, the .sby configs) and re-scored with the SAME
# decide() used at run time -- never re-implemented, so the report can't drift from what
# the run actually decided.

import re
from pathlib import Path
from typing import Dict, List, Optional

from rtlai.schema import RunResult
from rtlai.optimizer.decide import decide

SCOPE_PROVEN = (
    "- Functional equivalence between each round's baseline RTL and its accepted "
    "candidate, at the module's port boundary, under the clocking/reset assumptions "
    "built into the equivalence miter (see each round's log for its exact depth/mode).\n"
    "- Composed transitively: the final design is related to the ORIGINAL design by a "
    "chain of such proofs, one per accepted round, not by a single direct check.\n"
    "- Pre-place-and-route static timing and PPA measurements (Yosys synthesis + OpenSTA), "
    "on the standard-cell library configured for this run."
)

SCOPE_NOT_PROVEN = (
    "- **Clock-domain crossing (CDC) metastability.** The equivalence miter compares "
    "registered values at clock edges; it does not model metastable or glitchy behavior "
    "at an asynchronous crossing.\n"
    "- **Reset behavior beyond the miter's own reset assumption.** The proof assumes "
    "reset is asserted long enough to bring both copies to a known state before "
    "comparison starts; reset sequencing bugs outside that window are not covered.\n"
    "- **Post-place-and-route timing.** All timing numbers here come from a pre-P&R STA "
    "run; routing delay, clock skew and physical effects are not represented."
)


# ─────────────────────────────────────────────────────────── artifact loading ──

def _load_result(path: Path) -> Optional[RunResult]:
    if not path.exists():
        return None
    try:
        return RunResult.from_json(str(path))
    except (KeyError, ValueError, OSError):
        return None


def _round_dirs(run_dir: Path) -> List[Path]:
    dirs = [d for d in run_dir.glob("round_*") if d.is_dir()]
    return sorted(dirs, key=lambda d: int(d.name.split("_")[1]))


def _candidate_dirs(round_dir: Path) -> List[Path]:
    """Every attempt_*/candidate_* leaf directory in a round, in generation order."""
    dirs = [d for d in round_dir.glob("attempt_*/candidate_*") if d.is_dir()]

    def key(d: Path):
        attempt = int(d.parent.name.split("_")[1])
        cand = int(d.name.split("_")[1])
        return (attempt, cand)

    return sorted(dirs, key=key)


def _module_from_candidate_dir(cand_dir: Path) -> str:
    for f in cand_dir.glob("*_candidate.v"):
        return f.stem[: -len("_candidate")]
    return "unknown"


def _grep(text: str, pattern: str) -> Optional[str]:
    m = re.search(pattern, text)
    return m.group(1) if m else None


def _rel(path: Optional[Path], run_dir: Path) -> Optional[str]:
    if path is None or not path.exists():
        return None
    try:
        return str(path.relative_to(run_dir))
    except ValueError:
        return str(path)


def _eqy_eval(cand_dir: Path, run_dir: Path) -> Dict:
    eqy_dir = cand_dir / "formal_eqy"
    log_path = eqy_dir / "equiv_eqy.log"
    cfg_path = eqy_dir / "equiv.eqy"
    log = log_path.read_text() if log_path.exists() else ""
    cfg = cfg_path.read_text() if cfg_path.exists() else ""

    if re.search(r"Successfully proved designs equivalent", log) or re.search(r"Status:\s*PASSED", log):
        verdict = "PASS"
    elif re.search(r"Status:\s*FAILED", log) or re.search(r"not equivalent", log, re.I):
        verdict = "FAIL"
    else:
        verdict = "UNKNOWN"

    depth = _grep(cfg, r"depth\s+(\d+)")
    return {
        "engine": "eqy", "mode": "sat (register-matched partitions)",
        "depth": int(depth) if depth else None, "verdict": verdict,
        "bounded": False, "latency_offset": 0,
        "log_path": _rel(log_path, run_dir) if log_path.exists() else None,
    }


def _sby_eval(cand_dir: Path, run_dir: Path) -> Dict:
    formal_dir = cand_dir / "formal"
    # bmc is only present if prove timed out and the run fell back to it -- when present
    # it (not the earlier prove attempt) is the one that produced the final verdict.
    for mode_name in ("bmc", "prove"):
        log_path = formal_dir / f"equiv_sby_{mode_name}.log"
        sby_path = formal_dir / f"equiv_{mode_name}.sby"
        if log_path.exists():
            break
    else:
        log_path, sby_path, mode_name = None, None, None

    log = log_path.read_text() if log_path and log_path.exists() else ""
    sby = sby_path.read_text() if sby_path and sby_path.exists() else ""

    m = re.search(r"DONE\s*\((PASS|FAIL|UNKNOWN|TIMEOUT)", log)
    raw_verdict = m.group(1) if m else "UNKNOWN"
    basecase_passed = "returned pass for basecase" in log

    if raw_verdict == "PASS":
        verdict, bounded = "PASS", mode_name == "bmc"
    elif raw_verdict == "UNKNOWN" and basecase_passed:
        verdict, bounded = "PASS", True
    elif raw_verdict == "FAIL":
        verdict, bounded = "FAIL", False
    else:
        verdict, bounded = raw_verdict, False

    depth = _grep(sby, r"depth\s+(\d+)")
    wrapper = formal_dir / "eqcheck_wrapper.v"
    wrapper_text = wrapper.read_text() if wrapper.exists() else ""
    offset = _grep(wrapper_text, r"Latency offset of (\d+) cycle")

    return {
        "engine": "SymbiYosys", "mode": mode_name or "?",
        "depth": int(depth) if depth else None, "verdict": verdict,
        "bounded": bounded, "latency_offset": int(offset) if offset else 0,
        "log_path": _rel(log_path, run_dir) if log_path and log_path.exists() else None,
    }


def _candidate_eval(cand_dir: Path, run_dir: Path) -> Dict:
    """Every fact this report needs about one evaluated candidate, re-derived from its
    own directory: which checker ran it, at what depth, what it found, and -- if it got
    far enough to be measured -- its PPA result for scoring."""
    if (cand_dir / "formal_eqy").exists():
        base = _eqy_eval(cand_dir, run_dir)
    elif (cand_dir / "formal").exists():
        base = _sby_eval(cand_dir, run_dir)
    else:
        base = {"engine": None, "mode": None, "depth": None, "verdict": "INFEASIBLE",
                "bounded": False, "latency_offset": 0, "log_path": None}

    label = f"{cand_dir.parent.name.split('_')[1]}.{cand_dir.name.split('_')[1]}"
    result_path = cand_dir / "candidate" / "result.json"
    result = _load_result(result_path)

    base.update({
        "label": label,
        "module": _module_from_candidate_dir(cand_dir),
        "result": result,
        "cand_dir": cand_dir,
    })
    return base


def _walk_run(run_dir: Path):
    """
    Re-derive the entire round-by-round decision process from disk, using the same
    decide() the run itself used. Returns (baseline, final_result, rounds, offsets,
    accepted_chain).

    rounds is a list of dicts: round, module, clock, candidates (per-candidate eval
    dicts, each carrying a decide() verdict once it has a measured result), accepted
    (bool), winner (the accepted candidate's eval dict, or None).
    """
    baseline = _load_result(run_dir / "baseline" / "result.json")
    current_baseline = baseline
    offsets: Dict[str, int] = {}
    accepted_chain: List[str] = []
    rounds = []

    for round_dir in _round_dirs(run_dir):
        round_no = int(round_dir.name.split("_")[1])
        cands = [_candidate_eval(c, run_dir) for c in _candidate_dirs(round_dir)]
        module = cands[0]["module"] if cands else "unknown"
        clock = current_baseline.timing.clock if current_baseline else None

        best, best_net = None, None
        for c in cands:
            if c["result"] is None or current_baseline is None:
                continue
            ok, reason, net = decide(current_baseline, c["result"])
            c["decide_accepted"], c["decide_reason"], c["net_score"] = ok, reason, net
            if ok and (best_net is None or net > best_net):
                best, best_net = c, net

        rounds.append({
            "round": round_no, "module": module, "clock": clock,
            "candidates": cands, "accepted": best is not None, "winner": best,
        })

        if best is not None:
            offsets[module] = offsets.get(module, 0) + (best.get("latency_offset") or 0)
            current_baseline = best["result"]
            accepted_chain.append(module)

    final_path = run_dir / "optimized" / "result.json"
    final_result = _load_result(final_path) or current_baseline

    return baseline, final_result, rounds, offsets, accepted_chain


def _run_meta(run_dir: Path, baseline: Optional[RunResult]):
    design_name = baseline.design_name if baseline else run_dir.name
    return design_name, run_dir.name


# ───────────────────────────────────────────────────────────── formal report ──

_REJECT_REASONS = {
    "FAIL": "failed formal equivalence (not equivalent to the baseline)",
    "INFEASIBLE": "were judged undoable by the coder",
    "TIMEOUT": "could not be verified in time (the equivalence checker timed out)",
    "UNKNOWN": "returned no usable verdict from the equivalence checker",
}


def _round_reason(round_info: Dict) -> str:
    if round_info["accepted"]:
        return round_info["winner"]["decide_reason"]

    cands = round_info["candidates"]
    if not cands:
        return "No candidate was generated for this round."

    verified = [c for c in cands if c["result"] is not None]
    if verified:
        best = max(verified, key=lambda c: c.get("net_score") if c.get("net_score") is not None else float("-inf"))
        return f"Every implementation was formally equivalent, but none improved the design: {best['decide_reason']}"

    verdicts = {c["verdict"] for c in cands}
    if len(verdicts) == 1:
        reason = _REJECT_REASONS.get(next(iter(verdicts)), f"verdict {next(iter(verdicts))}")
        return f"All {len(cands)} candidate(s) {reason}."
    detail = ", ".join(f"{c['label']}: {_REJECT_REASONS.get(c['verdict'], c['verdict'])}" for c in cands)
    return f"No candidate was accepted ({detail})."


def build_formal_report(run_dir: Path) -> str:
    run_dir = Path(run_dir)
    baseline, final_result, rounds, offsets, chain = _walk_run(run_dir)
    design_name, run_name = _run_meta(run_dir, baseline)

    lines = [f"# Formal Equivalence Report — {design_name}", "", f"Run: `{run_name}`", ""]

    if not rounds:
        lines += ["No optimization round ran for this design. There is nothing to verify "
                   "beyond the baseline synthesis itself.", ""]
    else:
        lines += ["## Per-Round Verification", "",
                   "Every candidate that reached formal checking, however the round ended:", ""]
        for r in rounds:
            lines.append(f"### Round {r['round']}: `{r['module']}` (clock `{r['clock']}`)")
            lines.append("")
            if r["candidates"]:
                lines.append("| Candidate | Engine | Mode | Depth | Latency offset | Verdict | Log |")
                lines.append("|---|---|---|---|---|---|---|")
                for c in r["candidates"]:
                    verdict = c["verdict"] + (" (bounded)" if c.get("bounded") else "")
                    offset = f"+{c['latency_offset']}" if c.get("latency_offset") else "0"
                    log = c["log_path"] or "—"
                    depth = c["depth"] if c["depth"] is not None else "—"
                    engine = c["engine"] or "—"
                    mode = c["mode"] or "—"
                    marker = " **(winner)**" if r["winner"] is c else ""
                    lines.append(f"| {c['label']}{marker} | {engine} | {mode} | {depth} | {offset} | {verdict} | `{log}` |")
                lines.append("")
            else:
                lines.append("_No candidate was generated for this round._")
                lines.append("")

            verdict_word = "ACCEPTED" if r["accepted"] else "REJECTED"
            lines.append(f"**Round verdict: {verdict_word}** — {_round_reason(r)}")
            lines.append("")

    lines += ["## Chain of Proofs", ""]
    if chain:
        chain_str = " → ".join(["original"] + chain)
        lines.append(
            f"PASS (chain of {len(chain)} proof(s): {chain_str}). Each round's module was "
            "proven equivalent against the previous round's design; equivalence of the "
            "final design to the ORIGINAL follows by transitivity, at the cumulative "
            "latency offsets reported below."
        )
    else:
        lines.append("No round was accepted. The final design is the original RTL, unmodified.")
    lines.append("")

    lines += ["## Cumulative Latency", ""]
    changed = {m: k for m, k in offsets.items() if k}
    if changed:
        lines.append("Relative to the ORIGINAL design (each round's own proof is against "
                      "that round's baseline, which is valid; these totals are what the "
                      "surrounding logic must tolerate):")
        lines.append("")
        lines.append("| Module | Added latency |")
        lines.append("|---|---|")
        for m, k in changed.items():
            lines.append(f"| `{m}` | +{k} cycle(s) |")
    else:
        lines.append("No accepted round changed latency; the optimized design is cycle-accurate "
                      "identical to the original.")
    lines.append("")

    bounded_modules = [r["module"] for r in rounds
                        if r["accepted"] and r["winner"].get("bounded")]
    lines += ["## Scope", "", "**Proven:**", SCOPE_PROVEN, "", "**Not proven / out of scope:**",
              SCOPE_NOT_PROVEN, ""]
    if bounded_modules:
        lines.append(
            f"**Note:** the following accepted round(s) were verified only by BOUNDED model "
            f"checking, not an unbounded proof — a counterexample was ruled out up to the "
            f"depth shown above, but not for all possible traces: {', '.join(bounded_modules)}."
        )
        lines.append("")

    return "\n".join(lines)


# ──────────────────────────────────────────────────────────── change summary ──

_METRIC_ROWS = [
    ("Worst slack (ns)", lambda r: r.timing.worst_slack_ns, False, 2),
    ("Max frequency (MHz)", lambda r: r.timing.max_frequency_mhz, False, 1),
    ("Cell area (µm²)", lambda r: r.area.cell_area_um2, True, 0),
    ("Flip-flops", lambda r: r.area.flip_flops, True, 0),
    ("Total cells", lambda r: r.area.total_cells, True, 0),
    ("Total power (µW)", lambda r: r.power.total_uw, True, 0),
]


def _fmt_metric(v, dp) -> str:
    return "—" if v is None else f"{v:.{dp}f}"


def _fmt_delta(base, cand, lower_is_better) -> str:
    if base is None or cand is None or base == 0:
        return "—"
    if (base < 0) != (cand < 0):
        d = cand - base
        return f"{d:+.2f} (abs)"
    pct = (cand - base) / abs(base) * 100.0
    good = pct < 0 if lower_is_better else pct > 0
    arrow = "↓" if pct < 0 else "↑"
    return f"{pct:+.1f}% {arrow}" + (" (better)" if good else " (worse)" if abs(pct) >= 0.5 else "")


def _plan_excerpt(round_dir: Path, max_chars: int = 900) -> Optional[str]:
    plan_path = round_dir / "plan.txt"
    if not plan_path.exists():
        return None
    text = plan_path.read_text().strip()
    text = re.sub(r"^LATENCY_OFFSET:\s*\+?\d+\s*", "", text).strip()
    if len(text) > max_chars:
        text = text[:max_chars].rsplit(".", 1)[0] + "."
    return text


def _round_paragraph(r: Dict, run_dir: Path) -> str:
    w = r["winner"]
    result = w["result"]
    module, clock = r["module"], r["clock"]
    offset = w.get("latency_offset") or 0
    net = w.get("net_score")

    plan_excerpt = _plan_excerpt(run_dir / f"round_{r['round']}")
    transform = plan_excerpt or (
        f"a structural change to `{module}` (see `round_{r['round']}/plan.txt` if present "
        "for the planner's exact reasoning; not recorded for this run)"
    )

    parts = [
        f"**Round {r['round']} — `{module}`** (clock `{clock}`): {transform}"
    ]
    cost_bits = []
    if offset:
        cost_bits.append(f"+{offset} cycle(s) of latency")
    if result:
        cost_bits.append(f"{result.area.flip_flops} flip-flop(s), {result.area.cell_area_um2:.0f} µm² cell area")
    if net is not None:
        cost_bits.append(f"net weighted improvement {net:+.1f}%")
    if cost_bits:
        parts.append("Cost/effect: " + "; ".join(cost_bits) + ".")

    stop_note = (
        f"Verified equivalent by {w['engine']}"
        + (f" (depth {w['depth']})" if w.get("depth") else "")
        + (", bounded model checking only" if w.get("bounded") else ", unbounded proof")
        + "."
    )
    parts.append(stop_note)
    return " ".join(parts)


def build_change_summary(run_dir: Path) -> str:
    run_dir = Path(run_dir)
    baseline, final_result, rounds, offsets, chain = _walk_run(run_dir)
    design_name, run_name = _run_meta(run_dir, baseline)

    lines = [f"# Optimization Summary — {design_name}", "", f"Run: `{run_name}`", ""]

    lines += ["## Baseline vs Final", ""]
    if baseline is None:
        lines.append("No baseline result was recorded for this run.")
    else:
        lines.append("| Metric | Baseline | Final | Change |")
        lines.append("|---|---|---|---|")
        for name, getter, lower_is_better, dp in _METRIC_ROWS:
            b_val = getter(baseline)
            c_val = getter(final_result) if final_result else None
            lines.append(
                f"| {name} | {_fmt_metric(b_val, dp)} | {_fmt_metric(c_val, dp)} | "
                f"{_fmt_delta(b_val, c_val, lower_is_better)} |"
            )
        lines.append(
            f"| Timing constraint met | {baseline.timing_passed} | "
            f"{final_result.timing_passed if final_result else '—'} | |"
        )
    lines.append("")

    accepted_rounds = [r for r in rounds if r["accepted"]]
    lines += ["## Accepted Rounds", ""]
    if not accepted_rounds:
        lines.append(
            "No round was accepted. " +
            (f"{len(rounds)} round(s) were attempted; each is detailed in the formal "
             "equivalence report." if rounds else
             "No optimizable module was found on the critical path, or none of the "
             "attempted rounds cleared formal verification and net improvement together.")
        )
    else:
        for r in accepted_rounds:
            lines.append("- " + _round_paragraph(r, run_dir))
    lines.append("")

    lines += ["## Where It Stopped", ""]
    rejected_rounds = [r for r in rounds if not r["accepted"]]
    if rejected_rounds:
        last = rejected_rounds[-1]
        lines.append(
            f"The run stopped after round {last['round']} (`{last['module']}`): "
            f"{_round_reason(last)}"
        )
    elif accepted_rounds:
        lines.append("Every round attempted was accepted; the run stopped when no further "
                      "optimizable module remained on the critical path.")
    else:
        lines.append("No round was attempted.")
    lines.append("")

    return "\n".join(lines)


# ──────────────────────────────────────────────────────────────── rendering ──

_HTML_STYLE = """
body{font:15px/1.6 -apple-system,'Segoe UI',sans-serif;color:#1a1f27;
     background:#fff;max-width:900px;margin:0 auto;padding:40px 32px}
h1{font-size:26px;margin-bottom:4px} h2{font-size:19px;margin-top:32px;
   border-bottom:1px solid #e2e6ec;padding-bottom:6px}
h3{font-size:15px;margin-top:22px;color:#334}
table{border-collapse:collapse;width:100%;margin:14px 0;font-size:13.5px}
th,td{border:1px solid #dfe3ea;padding:7px 10px;text-align:left}
th{background:#f4f6f9}
code{background:#f1f3f7;padding:1px 5px;border-radius:4px;font-size:.92em}
"""


def render_markdown_html(markdown_text: str) -> str:
    from markdown_it import MarkdownIt
    body = MarkdownIt("commonmark", {"html": False}).enable("table").render(markdown_text)
    return f"<!doctype html><html><head><meta charset='utf-8'><style>{_HTML_STYLE}</style></head><body>{body}</body></html>"


def render_markdown_pdf(markdown_text: str, out_path: Path) -> Path:
    """
    Renders Markdown straight to PDF with reportlab (no system dependencies, unlike
    WeasyPrint/wkhtmltopdf). Only the subset of Markdown these reports actually produce
    is handled: #/##/### headers, pipe tables, '- ' bullets, blank-line paragraphs, and
    **bold** inline spans.
    """
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import LETTER
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, ListFlowable, ListItem

    styles = getSampleStyleSheet()
    h1 = ParagraphStyle("H1", parent=styles["Heading1"], fontSize=18, spaceAfter=6)
    h2 = ParagraphStyle("H2", parent=styles["Heading2"], fontSize=14, spaceBefore=14, spaceAfter=4)
    h3 = ParagraphStyle("H3", parent=styles["Heading3"], fontSize=11.5, spaceBefore=10, spaceAfter=3)
    body = ParagraphStyle("Body", parent=styles["BodyText"], fontSize=9.5, leading=13, spaceAfter=6)
    cell = ParagraphStyle("Cell", parent=body, fontSize=8.5, leading=11, spaceAfter=0)
    head_cell = ParagraphStyle("HeadCell", parent=cell, fontName="Helvetica-Bold")

    def inline(text: str) -> str:
        text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
        text = re.sub(r"`([^`]+)`", r"<font face='Courier'>\1</font>", text)
        return text

    out_path = Path(out_path)
    doc = SimpleDocTemplate(str(out_path), pagesize=LETTER,
                             topMargin=0.6 * inch, bottomMargin=0.6 * inch,
                             leftMargin=0.65 * inch, rightMargin=0.65 * inch)
    flow = []
    lines = markdown_text.splitlines()
    i, n = 0, len(lines)
    paragraph_buf: List[str] = []

    def flush_paragraph():
        if paragraph_buf:
            flow.append(Paragraph(inline(" ".join(paragraph_buf)), body))
            paragraph_buf.clear()

    while i < n:
        line = lines[i]
        stripped = line.strip()

        if not stripped:
            flush_paragraph()
            i += 1
            continue

        if stripped.startswith("### "):
            flush_paragraph()
            flow.append(Paragraph(inline(stripped[4:]), h3))
            i += 1
            continue
        if stripped.startswith("## "):
            flush_paragraph()
            flow.append(Paragraph(inline(stripped[3:]), h2))
            i += 1
            continue
        if stripped.startswith("# "):
            flush_paragraph()
            flow.append(Paragraph(inline(stripped[2:]), h1))
            i += 1
            continue

        if stripped.startswith("|"):
            flush_paragraph()
            table_lines = []
            while i < n and lines[i].strip().startswith("|"):
                table_lines.append(lines[i].strip())
                i += 1
            rows = [
                [c.strip() for c in tl.strip("|").split("|")]
                for tl in table_lines
                if not re.match(r"^\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?$", tl)
            ]
            if rows:
                data = [[Paragraph(inline(c), head_cell) for c in rows[0]]] + \
                       [[Paragraph(inline(c), cell) for c in r] for r in rows[1:]]
                ncols = len(rows[0])
                col_width = (LETTER[0] - 1.3 * inch) / max(ncols, 1)
                t = Table(data, colWidths=[col_width] * ncols, repeatRows=1)
                t.setStyle(TableStyle([
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#dfe3ea")),
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#f4f6f9")),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ]))
                flow.append(t)
                flow.append(Spacer(1, 8))
            continue

        if stripped.startswith("- "):
            flush_paragraph()
            items = []
            while i < n and lines[i].strip().startswith("- "):
                items.append(ListItem(Paragraph(inline(lines[i].strip()[2:]), body)))
                i += 1
            flow.append(ListFlowable(items, bulletType="bullet", leftIndent=14))
            continue

        paragraph_buf.append(stripped)
        i += 1

    flush_paragraph()
    doc.build(flow)
    return out_path
