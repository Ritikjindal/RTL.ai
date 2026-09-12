#!/usr/bin/env python3
# optimize.py — the GenAI optimization loop.
#
#   python3 optimize.py --rtl designs/*.v --sdc constraints/foo.sdc
#
# Give it a whole design and it will: analyse it, identify the module that owns the
# critical path, rewrite only that module, prove that module equivalent in isolation,
# reintegrate it, and re-measure the whole design. Nothing in this file needs editing
# to optimize a new design.

from pathlib import Path
from datetime import datetime, timezone

from analyze import analyze_design, files_str, RUNS_DIR
from rtlai.cli import build_parser, resolve_config, DesignConfig
from rtlai.formal import verify_equivalence, FormalError
from rtlai.compare import compare_results
from rtlai.modules import list_modules, locate_module, patch_design
from rtlai.attribute import optimizable_modules
from rtlai.optimizer.planner import generate_plan, extract_latency_offset
from rtlai.optimizer.coder import generate_code
from rtlai.optimizer.config import MAX_ATTEMPTS, CANDIDATES_PER_ATTEMPT
from rtlai.optimizer.counterexample import extract_counterexample
from rtlai.optimizer.decide import decide

PROJECT_ROOT = Path(__file__).resolve().parent

MAX_CEX_CHARS = 6000


def _trim_cex(cex: str, limit: int = MAX_CEX_CHARS) -> str:
    """
    Counterexample traces on wide datapaths run to tens of thousands of characters.
    The divergence is almost always in the first few cycles, and an oversized trace
    both wastes budget and pushes the planner past its output limit.
    """
    if len(cex) <= limit:
        return cex
    return cex[:limit] + (
        "\n... trace truncated. The divergence occurs within the cycles shown above; "
        "reason from these."
    )


def _select_target_module(cfg, baseline_result):
    """
    Which module should be rewritten?

    For a single-module design, itself. For a hierarchy, the module that owns the
    critical path: STA names the failing CLOCK, and a module instance's clock
    connection says which domain it belongs to. The netlist cannot answer this --
    abc renames every cell and keeps no hierarchy or source attributes.
    """
    index = list_modules(cfg.rtl_files)

    if len(index) == 1:
        return next(iter(index))

    clock = baseline_result.timing.clock
    if not clock:
        raise RuntimeError(
            "No critical-path clock was reported, so the responsible module cannot be "
            "identified. Check the STA timing report."
        )

    candidates = optimizable_modules(cfg.rtl_files, cfg.top_module, clock)
    if not candidates:
        raise RuntimeError(
            f"No optimizable module found on the critical clock '{clock}'. Modules on "
            "that clock are all multi-clock or clock-generating, which cannot be "
            "formally checked with latency offsets."
        )

    return candidates[0]


def _evaluate_candidate(cfg, target_module, rtl_code, plan, latency_offset,
                        baseline_result, candidate_dir, timestamp, label, seen_code):
    """
    Generate one candidate implementation of `plan`, prove the MODULE equivalent in
    isolation, reintegrate it, then measure and score the WHOLE design.

    Verification is at module scope because whole-design equivalence does not scale;
    scoring is at design scope because that is the improvement that actually matters.
    Identical module name and port list -- enforced by the coder prompt -- is what
    makes the substitution sound.
    """
    candidate_dir.mkdir(parents=True, exist_ok=True)
    print(f"  [{label}] Asking coder to implement the plan...")
    candidate_code = generate_code(rtl_code, plan)

    if candidate_code.strip().startswith("INFEASIBLE:"):
        reason = candidate_code.strip().splitlines()[0]
        print(f"  [{label}] {reason}")
        return {"status": "infeasible", "label": label, "path": None, "score": None,
                "reason": reason, "cex": None}

    module_path = candidate_dir / f"{target_module}_candidate.v"
    module_path.write_text(candidate_code)
    normalized = candidate_code.strip()

    if normalized == rtl_code.strip():
        print(f"  [{label}] Identical to the baseline - no change was made.")
        return {"status": "unchanged", "label": label, "path": module_path, "score": None,
                "reason": "candidate identical to baseline", "cex": None}

    if normalized in seen_code:
        print(f"  [{label}] Byte-identical to an earlier sample - skipping re-verification.")
        return {"status": "duplicate", "label": label, "path": module_path, "score": None,
                "reason": "duplicate of an earlier sample", "cex": None}
    seen_code.add(normalized)

    # Reintegrate: the whole design, with just this module replaced.
    location = locate_module(cfg.rtl_files, target_module)
    patched_files = patch_design(
        cfg.rtl_files, location, candidate_code, candidate_dir / "design"
    )

    print(f"  [{label}] Checking formal equivalence of '{target_module}'...")
    try:
        eq_result = verify_equivalence(
            original_rtl=cfg.rtl_files,
            candidate_rtl=patched_files,
            top_module=target_module,
            run_dir=candidate_dir / "formal",
            latency_offset=latency_offset,
        )
    except FormalError as e:
        print(f"  [{label}] FormalError: {e}")
        return {"status": "formal_error", "label": label, "path": module_path,
                "score": None, "reason": f"could not be formally checked: {e}",
                "cex": None}

    if not eq_result.passed:
        print(f"  [{label}] {eq_result.summary}")
        return {"status": "not_equivalent", "label": label, "path": module_path,
                "score": None, "reason": "failed formal equivalence",
                "cex": extract_counterexample(candidate_dir / "formal")}

    print(f"  [{label}] {eq_result.summary}")
    print(f"  [{label}] Equivalent! Re-synthesizing the whole design...")
    candidate_result = analyze_design(
        cfg=cfg,
        rtl_files=patched_files,
        design_name=f"{cfg.design_name}_candidate",
        run_dir=candidate_dir / "candidate",
        timestamp=timestamp,
    )
    candidate_result.formal_checked = True
    candidate_result.formal_passed = True
    candidate_result.formal_summary = eq_result.summary
    candidate_result.formal_baseline_rtl_path = files_str(cfg.rtl_files)
    candidate_result.to_json(str(candidate_dir / "candidate" / "result.json"))

    accepted, reason, score = decide(baseline_result, candidate_result)
    print(f"  [{label}] {reason}")
    return {"status": "accepted" if accepted else "rejected", "label": label,
            "path": module_path, "design": patched_files, "result": candidate_result,
            "score": score, "reason": reason, "cex": None}


def optimize(cfg: DesignConfig):
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    run_dir = RUNS_DIR / f"{cfg.design_name}_optimize_{timestamp}"

    print(f"[baseline] Synthesizing + measuring baseline '{cfg.design_name}'...")
    print(f"           top module: {cfg.top_module}   sources: {len(cfg.rtl_files)} file(s)")
    baseline_result = analyze_design(
        cfg=cfg,
        rtl_files=cfg.rtl_files,
        design_name=cfg.design_name,
        run_dir=run_dir / "baseline",
        timestamp=timestamp,
    )
    print(f"           Done: {run_dir / 'baseline' / 'result.json'}")

    target_module = _select_target_module(cfg, baseline_result)
    location = locate_module(cfg.rtl_files, target_module)

    clock = baseline_result.timing.clock
    print(f"\n[target]   Critical path is on clock '{clock}'.")
    print(f"           Responsible module: '{target_module}' ({location.path.name}, "
          f"{len(location.text.splitlines())} lines)")

    # The planner sees only this module's source, plus a note on why it was chosen.
    # Sending the whole design would cost a fortune in output tokens and risk the coder
    # corrupting modules it was never asked to touch.
    rtl_code = (
        f"// This module owns the critical path of the full design "
        f"(clock '{clock}', worst slack {baseline_result.timing.worst_slack_ns} ns).\n"
        f"{location.text}"
    )

    feedback = None

    for attempt in range(1, MAX_ATTEMPTS + 1):
        print(f"\n[attempt {attempt}/{MAX_ATTEMPTS}] Asking planner for a plan...")
        plan = generate_plan(rtl_code, baseline_result, previous_feedback=feedback)
        print(plan)

        latency_offset = extract_latency_offset(plan)
        if latency_offset:
            print(f"[attempt {attempt}] Plan declares +{latency_offset} cycle(s) of added latency.")

        attempt_dir = run_dir / f"attempt_{attempt}"

        print(f"[attempt {attempt}] Sampling {CANDIDATES_PER_ATTEMPT} implementation(s) of this plan.")
        candidates = []
        seen_code = set()
        for n in range(1, CANDIDATES_PER_ATTEMPT + 1):
            candidates.append(_evaluate_candidate(
                cfg=cfg, target_module=target_module, rtl_code=rtl_code, plan=plan,
                latency_offset=latency_offset, baseline_result=baseline_result,
                candidate_dir=attempt_dir / f"candidate_{n}",
                timestamp=timestamp, label=f"attempt {attempt}.{n}", seen_code=seen_code,
            ))

        accepted = [c for c in candidates if c["status"] == "accepted"]
        if accepted:
            best = max(accepted, key=lambda c: c["score"])
            print(f"\n[attempt {attempt}] {len(accepted)}/{CANDIDATES_PER_ATTEMPT} sample(s) accepted; "
                  f"winner is [{best['label']}] at {best['score']:+.1f}%.")

            for c in sorted(candidates, key=lambda c: (c["score"] is None, -(c["score"] or 0))):
                mark = "*" if c is best else " "
                score = f"{c['score']:+.1f}%" if c["score"] is not None else "n/a"
                print(f"           {mark} [{c['label']}] {c['status']:<15} {score}")

            compare_results(baseline_result, best["result"])

            optimized_dir = run_dir / "optimized"
            patch_design(cfg.rtl_files, location, best["path"].read_text(), optimized_dir)

            print(f"\n[accepted] {best['label']}: {best['reason']}")
            print(f"\nOptimized module : {best['path']}")
            print(f"Optimized design : {optimized_dir}")
            if latency_offset:
                print(f"NOTE: '{target_module}' now produces its outputs +{latency_offset} "
                      "cycle(s) later. Substitution into the top level is only sound if the "
                      "surrounding logic tolerates that.")
            return baseline_result, best["result"]

        with_cex = next((c for c in candidates if c["cex"]), None)
        rejected = [c for c in candidates if c["status"] == "rejected"]
        infeasible = [c for c in candidates if c["status"] == "infeasible"]
        not_equiv = [c for c in candidates if c["status"] == "not_equivalent"]
        tally = ", ".join(c["status"] for c in candidates)
        print(f"[attempt {attempt}] No sample accepted ({tally}).")

        if with_cex:
            feedback = (
                f"Attempt {attempt}: {len(not_equiv)} of {CANDIDATES_PER_ATTEMPT} implementations "
                "of your plan failed formal equivalence against the baseline.\n\n"
                "A formal counterexample was found. Applying the following input stimulus "
                "(one state per clock cycle) makes the candidate's outputs differ from the "
                "baseline's:\n"
                f"{_trim_cex(with_cex['cex'])}\n\n"
                "Trace through the baseline RTL by hand for this exact input sequence, work out "
                "what your proposed change would produce instead, identify the specific signal "
                "that differs and why, and propose a corrected approach that fixes it."
            )
        elif rejected:
            best_rejected = max(rejected, key=lambda c: c["score"])
            feedback = (
                f"Attempt {attempt}: your plan was implemented {CANDIDATES_PER_ATTEMPT} times and "
                f"every version passed formal equivalence but none improved the design. The best "
                f"was: {best_rejected['reason']} Propose a different approach that actually "
                "improves area, power, or maximum frequency without significantly regressing "
                "the others."
            )
        elif infeasible and len(infeasible) == len(candidates):
            feedback = (
                f"Attempt {attempt}: the coder judged this plan undoable in all "
                f"{CANDIDATES_PER_ATTEMPT} attempt(s), not merely risky. Reported reason(s): "
                f"{'; '.join(c['reason'] for c in infeasible)}. "
                "Propose a different approach that does not require deriving a large table or "
                "complex closed-form transformation by hand - prefer structural changes "
                "(pipelining, re-encoding, sharing existing logic) over ones requiring new "
                "derived constants."
            )
        else:
            detail = "; ".join(c["reason"] for c in candidates)
            feedback = (
                f"Attempt {attempt}: none of the {CANDIDATES_PER_ATTEMPT} implementations could "
                f"be evaluated ({detail}). Propose a simpler, more directly implementable change."
            )

    print(f"\n[rejected] No improved candidate found after {MAX_ATTEMPTS} attempts. Keeping baseline.")
    return baseline_result, None


def main():
    parser = build_parser("Optimize an RTL design for timing and PPA using an LLM loop.")
    cfg = resolve_config(parser.parse_args(), PROJECT_ROOT)
    optimize(cfg)


if __name__ == "__main__":
    main()