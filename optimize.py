#!/usr/bin/env python3
# optimize.py — the GenAI optimization loop.
#
#   python3 optimize.py --rtl designs/foo/*.v --sdc constraints/foo.sdc
#
# Nothing in this file needs editing to optimize a new design.

from pathlib import Path
from datetime import datetime, timezone

from analyze import analyze_design, files_str, RUNS_DIR
from rtlai.cli import build_parser, resolve_config, DesignConfig
from rtlai.formal import verify_equivalence, FormalError
from rtlai.compare import compare_results
from rtlai.optimizer.planner import generate_plan, extract_latency_offset
from rtlai.optimizer.coder import generate_code
from rtlai.optimizer.config import MAX_ATTEMPTS, CANDIDATES_PER_ATTEMPT
from rtlai.optimizer.counterexample import extract_counterexample
from rtlai.optimizer.decide import decide

PROJECT_ROOT = Path(__file__).resolve().parent


def _evaluate_candidate(cfg, rtl_code, plan, latency_offset, baseline_result,
                        candidate_dir, timestamp, label, seen_code):
    """
    Generate, verify and score one candidate implementation of `plan`.

    Returns a dict with: path, status, score, reason, and (on an equivalence failure)
    a counterexample. Status is one of "accepted", "rejected", "not_equivalent",
    "duplicate", "unchanged", "formal_error".
    """
    candidate_dir.mkdir(parents=True, exist_ok=True)
    print(f"  [{label}] Asking coder to implement the plan...")
    candidate_code = generate_code(rtl_code, plan)

    candidate_rtl_path = candidate_dir / f"{cfg.design_name}_candidate.v"
    candidate_rtl_path.write_text(candidate_code)
    normalized = candidate_code.strip()

    if normalized == rtl_code.strip():
        print(f"  [{label}] Identical to the baseline - no change was made.")
        return {"status": "unchanged","label": label, "path": candidate_rtl_path, "score": None,
                "reason": "candidate identical to baseline", "cex": None}

    # Two samples that came out byte-identical only need verifying once. Formal is the
    # slowest step in the loop, so this is worth the two lines.
    if normalized in seen_code:
        print(f"  [{label}] Byte-identical to an earlier sample - skipping re-verification.")
        return {"status": "duplicate","label": label, "path": candidate_rtl_path, "score": None,
                "reason": "duplicate of an earlier sample", "cex": None}
    seen_code.add(normalized)

    print(f"  [{label}] Checking formal equivalence...")
    try:
        eq_result = verify_equivalence(
            original_rtl=cfg.rtl_files,
            candidate_rtl=candidate_rtl_path,
            top_module=cfg.top_module,
            run_dir=candidate_dir / "formal",
            latency_offset=latency_offset,
        )
    except FormalError as e:
        print(f"  [{label}] FormalError: {e}")
        return {"status": "formal_error","label": label, "path": candidate_rtl_path, "score": None,
                "reason": f"could not be formally checked: {e}", "cex": None}

    if not eq_result.passed:
        print(f"  [{label}] {eq_result.summary}")
        return {"status": "not_equivalent","label": label, "path": candidate_rtl_path, "score": None,
                "reason": "failed formal equivalence",
                "cex": extract_counterexample(candidate_dir / "formal")}

    print(f"  [{label}] {eq_result.summary}")
    print(f"  [{label}] Equivalent! Synthesizing + measuring...")
    candidate_result = analyze_design(
        cfg=cfg,
        rtl_files=[candidate_rtl_path],
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
    return {"status": "accepted" if accepted else "rejected","label": label,
            "path": candidate_rtl_path, "result": candidate_result,
            "score": score, "reason": reason, "cex": None}


def optimize(cfg: DesignConfig):
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    run_dir = RUNS_DIR / f"{cfg.design_name}_optimize_{timestamp}"

    # The candidate the coder writes is a single complete file. For a single-module
    # design that is exact. For a multi-module design the model must reproduce the
    # whole design in one file, which is why per-module optimization targets small
    # blocks rather than large hierarchies.
    rtl_code = "\n".join(Path(f).read_text() for f in cfg.rtl_files)

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

    feedback = None

    for attempt in range(1, MAX_ATTEMPTS + 1):
        print(f"\n[attempt {attempt}/{MAX_ATTEMPTS}] Asking planner for a plan...")
        plan = generate_plan(rtl_code, baseline_result, previous_feedback=feedback)
        print(plan)

        latency_offset = extract_latency_offset(plan)
        if latency_offset:
            print(f"[attempt {attempt}] Plan declares +{latency_offset} cycle(s) of added latency.")

        attempt_dir = run_dir / f"attempt_{attempt}"

        # Best-of-N: implement the SAME plan several times independently. LLM RTL
        # generation is sampling-limited -- a plan the model understands correctly will
        # often still be implemented wrongly on any given draw -- so drawing N samples
        # and keeping the best converts a coin-flip into a much better bet. Only the
        # coder is resampled; the plan is held fixed so the samples are comparable.
        print(f"[attempt {attempt}] Sampling {CANDIDATES_PER_ATTEMPT} implementation(s) of this plan.")
        candidates = []
        seen_code = set()
        for n in range(1, CANDIDATES_PER_ATTEMPT + 1):
            candidates.append(_evaluate_candidate(
                cfg=cfg, rtl_code=rtl_code, plan=plan, latency_offset=latency_offset,
                baseline_result=baseline_result,
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
            print(f"\n[accepted] {best['label']}: {best['reason']}")
            print(f"\nAccepted candidate RTL: {best['path']}")
            return baseline_result, best["result"]

        # Nothing was accepted. Build feedback from the most informative failure:
        # a counterexample beats a bare rejection, because it tells the planner exactly
        # which input sequence broke the transformation.
        with_cex = next((c for c in candidates if c["cex"]), None)
        rejected = [c for c in candidates if c["status"] == "rejected"]
        tally = ", ".join(c["status"] for c in candidates)
        print(f"[attempt {attempt}] No sample accepted ({tally}).")

        if with_cex:
            feedback = (
                f"Attempt {attempt}: all {CANDIDATES_PER_ATTEMPT} implementations of your plan failed "
                "formal equivalence against the baseline. This is a flaw in the PLAN, not a coding slip.\n\n"
                "A formal counterexample was found. Applying the following input stimulus "
                "(one state per clock cycle) makes the candidate's outputs differ from the baseline's:\n"
                f"{with_cex['cex']}\n\n"
                "Trace through the baseline RTL by hand for this exact input sequence, work out what "
                "your proposed change would produce instead, identify the specific signal that differs "
                "and why, and propose a corrected approach that fixes it."
            )
        elif rejected:
            best_rejected = max(rejected, key=lambda c: c["score"])
            feedback = (
                f"Attempt {attempt}: your plan was implemented {CANDIDATES_PER_ATTEMPT} times and every "
                f"version passed formal equivalence but none improved the design. The best was: "
                f"{best_rejected['reason']} Propose a different approach that actually improves area, "
                "power, or maximum frequency without significantly regressing the others."
            )
        else:
            detail = "; ".join(c["reason"] for c in candidates)
            feedback = (
                f"Attempt {attempt}: none of the {CANDIDATES_PER_ATTEMPT} implementations could be "
                f"evaluated ({detail}). Propose a simpler, more directly implementable change."
            )

    print(f"\n[rejected] No improved candidate found after {MAX_ATTEMPTS} attempts. Keeping baseline.")
    return baseline_result, None


def main():
    parser = build_parser("Optimize an RTL design for timing and PPA using an LLM loop.")
    cfg = resolve_config(parser.parse_args(), PROJECT_ROOT)
    optimize(cfg)


if __name__ == "__main__":
    main()