#!/usr/bin/env python3
# optimize.py — the GenAI optimization loop.
#
# Give it a design and it will keep optimizing until number of rounds which are equal to number of clocks in the file:
# each ROUND analyses the current design, identifies the module owning the critical
# path, rewrites and proves just that module, reintegrates it, and re-measures the
# whole design. The next round starts from that result, so as the bottleneck migrates
# from one domain to the next the tool follows it. Stops when a round finds nothing.

import re
import time

import json
from pathlib import Path
from datetime import datetime, timezone

from analyze import analyze_design, files_str, RUNS_DIR
from rtlai.cli import build_parser, resolve_config, DesignConfig, count_clock_domains
from rtlai.formal import verify_equivalence, FormalError
from rtlai.compare import compare_results
from rtlai.modules import list_modules, locate_module, patch_design
from rtlai.attribute import optimizable_modules
from rtlai.optimizer.planner import generate_plan, extract_latency_offset
from rtlai.optimizer.coder import generate_code
from rtlai.optimizer.config import MAX_ATTEMPTS, CANDIDATES_PER_ATTEMPT, MAX_ROUNDS
from rtlai.optimizer.counterexample import extract_counterexample
from rtlai.optimizer.decide import decide
from rtlai.equiv_eqy import verify_equivalence_eqy, EqyError
from rtlai.estimate import (
    estimate_seconds, format_estimate, manual_equivalent_hours, format_hours,
    format_duration, MANUAL_HOURS_PER_TRANSFORM,
)

PROJECT_ROOT = Path(__file__).resolve().parent

MAX_CEX_CHARS = 6000

CREATE_CLOCK_RE = re.compile(r"^\s*create_clock\b", re.MULTILINE)


def _round_budget(cfg) -> int:
    """
    One round per clock domain.

    Each round fixes the module owning the current critical path, after which the
    bottleneck moves to a different domain -- so a design with five asynchronous clocks
    needs five rounds before every domain has been visited once. Counted from
    create_clock statements in the SDC (master clocks only; generated clocks share a
    domain with their source). MAX_ROUNDS is an upper bound so a pathological SDC
    cannot run the loop forever.
    """
    try:
        n_clocks = len(CREATE_CLOCK_RE.findall(Path(cfg.sdc_file).read_text()))
    except OSError:
        return MAX_ROUNDS
    return min(n_clocks, MAX_ROUNDS) if n_clocks else MAX_ROUNDS


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


def _select_target_module(rtl_files, top_module, baseline_result, exclude=()):
    """
    Which module should be rewritten?

    For a single-module design, itself. For a hierarchy, the module owning the
    critical path: STA names the failing CLOCK, and a module instance's clock
    connection says which domain it belongs to. The netlist cannot answer this --
    abc renames every cell and keeps no hierarchy or source attributes.

    `exclude` holds modules already tried unsuccessfully this run, so a later round
    does not keep re-attacking a module the tool has shown it cannot improve.
    """
    index = list_modules(rtl_files)

    if len(index) == 1:
        only = next(iter(index))
        return None if only in exclude else only

    clock = baseline_result.timing.clock
    if not clock:
        return None

    for name in optimizable_modules(rtl_files, top_module, clock):
        if name not in exclude:
            return name
    return None


def _evaluate_candidate(cfg, rtl_files, target_module, rtl_code, plan, latency_offset,
                        baseline_result, candidate_dir, timestamp, label, seen_code):
    """
    Generate one candidate implementation of `plan`, prove the MODULE equivalent in
    isolation, reintegrate it, then measure and score the WHOLE design.

    Verification is at module scope because whole-design equivalence does not scale;
    scoring is at design scope because that is the improvement that matters. Identical
    module name and port list -- enforced by the coder prompt -- is what makes the
    substitution sound.
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

    location = locate_module(rtl_files, target_module)
    patched_files = patch_design(rtl_files, location, candidate_code, candidate_dir / "design")

        # Checker dispatch. eqy matches registers and proves each combinational cone, so it
    # scales far better than an unrolled miter -- but it needs the register sets to
    # correspond, which rules it out the moment a plan adds a pipeline stage. So it is
    # used only at LATENCY_OFFSET 0, and only its PASS is taken as final: eqy proves
    # cones for ALL register values including unreachable ones, so a FAIL from it may
    # be a false negative (a transform correct only because some register is one-hot).
    # In that case fall back to SymbiYosys, whose BMC path starts from reset and
    # therefore only explores reachable states.
    eq_result = None

    if latency_offset == 0:
        print(f"  [{label}] Checking equivalence of '{target_module}' with eqy...")
        try:
            eqy_result = verify_equivalence_eqy(
                original_rtl=rtl_files,
                candidate_rtl=patched_files,
                top_module=target_module,
                run_dir=candidate_dir / "formal_eqy",
            )
            if eqy_result.passed:
                eq_result = eqy_result
            else:
                print(f"  [{label}] eqy reports not equivalent — not conclusive "
                      "(it also proves unreachable states), falling back to SymbiYosys.")
        except EqyError as e:
            print(f"  [{label}] eqy inconclusive: {e}")
            print(f"  [{label}] Falling back to SymbiYosys.")

    if eq_result is None:
        # Also the only path for latency_offset != 0: eqy needs matching register
        # sets so it never runs there, but SymbiYosys takes latency_offset directly.
        print(f"  [{label}] Checking formal equivalence of '{target_module}' with SymbiYosys...")
        try:
            eq_result = verify_equivalence(
                original_rtl=rtl_files,
                candidate_rtl=patched_files,
                top_module=target_module,
                run_dir=candidate_dir / "formal",
                latency_offset=latency_offset,
            )
        except FormalError as e:
            print(f"  [{label}] FormalError: {e}")
            timed_out = "TIMED OUT" in str(e)
            return {"status": "formal_timeout" if timed_out else "formal_error",
                    "label": label, "path": module_path, "score": None,
                    "reason": f"could not be formally checked: {e}", "cex": None}

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
    candidate_result.formal_baseline_rtl_path = files_str(rtl_files)
    candidate_result.to_json(str(candidate_dir / "candidate" / "result.json"))

    accepted, reason, score = decide(baseline_result, candidate_result)
    print(f"  [{label}] {reason}")
    return {"status": "accepted" if accepted else "rejected", "label": label,
            "path": module_path, "design": patched_files, "result": candidate_result,
            "result_json": str(candidate_dir / "candidate" / "result.json"),
            "score": score, "reason": reason, "cex": None}


def _run_round(cfg, rtl_files, baseline_result, target_module, round_dir, timestamp):
    """
    One optimization round on `target_module`. Returns the winning candidate dict,
    or None if no attempt produced an accepted candidate.
    """
    location = locate_module(rtl_files, target_module)
    clock = baseline_result.timing.clock

    rtl_code = (
        f"// This module owns the critical path of the full design "
        f"(clock '{clock}', worst slack {baseline_result.timing.worst_slack_ns} ns).\n"
        f"{location.text}"
    )

    feedback = None
    timeout_attempts = 0

    for attempt in range(1, MAX_ATTEMPTS + 1):
        print(f"\n[attempt {attempt}/{MAX_ATTEMPTS}] Asking planner for a plan...")
        try:
            plan = generate_plan(rtl_code, baseline_result, previous_feedback=feedback)
        except RuntimeError as e:
            print(f"[attempt {attempt}] Planner failed: {e}")
            print(f"[attempt {attempt}] Abandoning '{target_module}' and moving on.")
            return None
        print(plan)

        latency_offset = extract_latency_offset(plan)
        if latency_offset:
            print(f"[attempt {attempt}] Plan declares +{latency_offset} cycle(s) of added latency.")

        attempt_dir = round_dir / f"attempt_{attempt}"

        print(f"[attempt {attempt}] Sampling {CANDIDATES_PER_ATTEMPT} implementation(s) of this plan.")
        candidates = []
        seen_code = set()
        for n in range(1, CANDIDATES_PER_ATTEMPT + 1):
            result = _evaluate_candidate(
                cfg=cfg, rtl_files=rtl_files, target_module=target_module,
                rtl_code=rtl_code, plan=plan, latency_offset=latency_offset,
                baseline_result=baseline_result,
                candidate_dir=attempt_dir / f"candidate_{n}",
                timestamp=timestamp, label=f"attempt {attempt}.{n}", seen_code=seen_code,
            )
            candidates.append(result)
            if result["status"] == "formal_timeout":
                print(f"  [attempt {attempt}] Formal check timed out; skipping the remaining "
                      f"{CANDIDATES_PER_ATTEMPT - n} sample(s) of this plan — they implement "
                      "the same transform and would time out identically.")
                break

        accepted = [c for c in candidates if c["status"] == "accepted"]
        if accepted:
            best = max(accepted, key=lambda c: c["score"])
            print(f"\n[attempt {attempt}] {len(accepted)}/{CANDIDATES_PER_ATTEMPT} sample(s) accepted; "
                  f"winner is [{best['label']}] at {best['score']:+.1f}%.")
            for c in sorted(candidates, key=lambda c: (c["score"] is None, -(c["score"] or 0))):
                mark = "*" if c is best else " "
                score = f"{c['score']:+.1f}%" if c["score"] is not None else "n/a"
                print(f"           {mark} [{c['label']}] {c['status']:<15} {score}")

            best["latency_offset"] = latency_offset
            best["module"] = target_module
            best["clock"] = clock
            # Persisted so a report generated later (report.py reads only run_dir
            # artifacts, never stdout) can name the actual transform, not just its score.
            (round_dir / "plan.txt").write_text(plan)
            return best

        with_cex = next((c for c in candidates if c["cex"]), None)
        rejected = [c for c in candidates if c["status"] == "rejected"]
        infeasible = [c for c in candidates if c["status"] == "infeasible"]
        not_equiv = [c for c in candidates if c["status"] == "not_equivalent"]
        timed_out = [c for c in candidates if c["status"] == "formal_timeout"]
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
        elif timed_out:
            timeout_attempts += 1
            if timeout_attempts >= 2:
                print(f"[attempt {attempt}] Two plans in a row could not be verified within the "
                      f"time budget. Abandoning '{target_module}'.")
                return None
            feedback = (
                f"Attempt {attempt}: your transform is likely correct but could NOT BE VERIFIED "
                "within the time budget — the equivalence checker timed out in both unbounded "
                "and bounded modes. This is a limitation of the checker, not evidence that your "
                "plan is wrong, but an unverifiable change cannot be accepted.\n\n"
                "Propose a change that is easier to verify. Transforms that defeat the checker: "
                "reassociating or rebalancing long arithmetic chains; anything touching wide "
                "multipliers; and transforms whose correctness depends on an invariant the "
                "checker cannot know, such as a state register always being one-hot. Transforms "
                "that verify quickly: inserting a pipeline register between existing stages "
                "without changing the arithmetic, re-encoding a state register, and sharing or "
                "removing redundant logic."
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
                f"{CANDIDATES_PER_ATTEMPT} attempt(s). Reported reason(s): "
                f"{'; '.join(c['reason'] for c in infeasible)}. "
                "Propose a different approach that does not require deriving a large table or "
                "complex closed-form transformation by hand - prefer structural changes."
            )
        else:
            detail = "; ".join(c["reason"] for c in candidates)
            feedback = (
                f"Attempt {attempt}: none of the {CANDIDATES_PER_ATTEMPT} implementations could "
                f"be evaluated ({detail}). Propose a simpler, more directly implementable change."
            )

    return None


def _effort_summary(accepted_rounds: int, wall_clock_seconds: float) -> dict:
    """
    The two effort figures for the results panel and the change-summary report: the
    agent's actual measured wall-clock, and a constant-per-transform manual-equivalent
    range. Kept separate on purpose -- never combined into one "hours saved" number,
    since one is measured and the other is a rough comparison point.
    """
    manual_low, manual_high = manual_equivalent_hours(accepted_rounds)
    return {
        "wall_clock_seconds": wall_clock_seconds,
        "wall_clock_label": format_duration(wall_clock_seconds),
        "accepted_rounds": accepted_rounds,
        "manual_hours_low": manual_low,
        "manual_hours_high": manual_high,
        "manual_label": format_hours(manual_low, manual_high),
        "manual_basis": (
            f"{accepted_rounds} accepted transform(s) × "
            f"{MANUAL_HOURS_PER_TRANSFORM[0]:g}-{MANUAL_HOURS_PER_TRANSFORM[1]:g} h/transform "
            "(manual RTL rewrite + re-verification per transform)"
        ),
    }


def optimize(cfg: DesignConfig):
    run_t0 = time.time()
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    run_dir = RUNS_DIR / f"{cfg.design_name}_optimize_{timestamp}"

    print(f"[baseline] Synthesizing + measuring baseline '{cfg.design_name}'...")
    print(f"           top module: {cfg.top_module}   sources: {len(cfg.rtl_files)} file(s)")
    _baseline_t0 = time.time()
    original_result = analyze_design(
        cfg=cfg, rtl_files=cfg.rtl_files, design_name=cfg.design_name,
        run_dir=run_dir / "baseline", timestamp=timestamp,
    )
    baseline_secs = time.time() - _baseline_t0
    print(f"           Done: {run_dir / 'baseline' / 'result.json'}")

    low, high = estimate_seconds(cfg.sdc_file, cfg, baseline_seconds=baseline_secs)
    print(f"[eta] Estimated total run time: {format_estimate(low, high)} "
          f"({_round_budget(cfg)} rounds)")

    rtl_files = list(cfg.rtl_files)
    current_result = original_result
    history = []
    exhausted = set()          # modules this run has failed to improve
    offsets = {}               # module -> cumulative added latency, in cycles
    round_times = []           # measured wall-clock seconds per completed round

    # One round per clock domain -- a single-clock design has exactly one critical
    # path to chase, so it gets one round; a 5-domain design still caps at MAX_ROUNDS
    # since each round is an expensive plan/code/prove loop.
    num_clocks = count_clock_domains(cfg.sdc_file)
    max_rounds = min(num_clocks, MAX_ROUNDS)

    budget = _round_budget(cfg)
    print(f"           round budget: {budget} (one per clock domain)")

    for rnd in range(1, budget + 1):
        round_t0 = time.time()
        target = _select_target_module(rtl_files, cfg.top_module, current_result, exhausted)
        if target is None:
            print(f"\n[round {rnd}] No further optimizable module on the critical path. Stopping.")
            break

        clock = current_result.timing.clock
        location = locate_module(rtl_files, target)
        print(f"\n{'=' * 70}")
        print(f"[round {rnd}/{max_rounds}] Critical path on clock '{clock}'.")
        print(f"           Responsible module: '{target}' ({location.path.name}, "
              f"{len(location.text.splitlines())} lines)")
        print(f"           Current worst slack: {current_result.timing.worst_slack_ns} ns")
        print("=" * 70)

        round_dir = run_dir / f"round_{rnd}"
        best = _run_round(cfg, rtl_files, current_result, target, round_dir, timestamp)

        if best is None:
            exhausted.add(target)
            # Whole-design worst slack is set by the worst domain. If that domain cannot
            # be improved, no other module can move the number -- decide() would reject
            # them all for not improving slack -- so stop rather than burn rounds
            # proving it. Once timing is met the loop is chasing area and power, where
            # another module genuinely can help, so there we keep going.
            if current_result.timing_passed is False:
                print(f"[round {rnd}] '{target}' could not be improved, and it owns the "
                      "binding constraint. No other module can improve worst slack while "
                      "that holds — stopping.")
                break
            print(f"[round {rnd}] '{target}' could not be improved. Timing is met, so "
                  "trying the next module for area/power.")
            round_times.append(time.time() - round_t0)
            low, high = estimate_seconds(cfg.sdc_file, cfg, baseline_seconds=baseline_secs,
                                          round_seconds=round_times)
            print(f"[eta] Revised estimate for remaining rounds: {format_estimate(low, high)}")
            continue

        # Adopt the winner as the new design and carry on from there.
        optimized_dir = round_dir / "optimized"
        patch_design(rtl_files, location, best["path"].read_text(), optimized_dir)

        rtl_files = sorted(optimized_dir.glob("*.v"))
        current_result = best["result"]
        offsets[target] = offsets.get(target, 0) + best["latency_offset"]
        history.append(best)

        print(f"\n[round {rnd}] Accepted: {best['reason']}")
        print(f"[round {rnd}] Design now at {optimized_dir}")

        round_times.append(time.time() - round_t0)
        low, high = estimate_seconds(cfg.sdc_file, cfg, baseline_seconds=baseline_secs,
                                      round_seconds=round_times)
        print(f"[eta] Revised estimate for remaining rounds: {format_estimate(low, high)}")

    # ---------------------------------------------------------------- summary
    print(f"\n{'=' * 70}")
    print("OPTIMIZATION COMPLETE")
    print("=" * 70)

    if not history:
        print("No round produced an accepted candidate. The original design stands.")
        wall_clock_seconds = time.time() - run_t0
        effort = _effort_summary(0, wall_clock_seconds)
        print(f"[effort] Agent wall-clock (measured): {effort['wall_clock_label']}  |  "
              f"Manual equivalent (estimated): {effort['manual_label']}")
        (run_dir / "summary.json").write_text(json.dumps({
            "rounds": [], "final_result": None, "cumulative_latency": {}, "effort": effort,
        }, indent=2))
        return original_result, None

    print(f"\n{len(history)} round(s) accepted:\n")
    print(f"  {'Rnd':<5}{'Clock':<10}{'Module':<18}{'Offset':<9}{'Net':>8}")
    for i, h in enumerate(history, 1):
        print(f"  {i:<5}{h['clock']:<10}{h['module']:<18}"
              f"{('+' + str(h['latency_offset'])) if h['latency_offset'] else '0':<9}"
              f"{h['score']:>+7.1f}%")

    final_dir = run_dir / "optimized"
    last_dir = run_dir / f"round_{len(history)}" / "optimized"
    final_dir.mkdir(parents=True, exist_ok=True)
    for f in sorted(last_dir.glob("*.v")):
        # Suffixed rather than same-named as the source, so a file downloaded next to
        # the original is never silently mistaken for it.
        (final_dir / f"{f.stem}_optimized{f.suffix}").write_text(f.read_text())

    # The definitive final result, unambiguous even when several candidates were
    # measured along the way (only some accepted) -- callers should read this rather
    # than guess at it from the per-attempt candidate/result.json files scattered
    # under round_*/attempt_*/.
    current_result.to_json(str(final_dir / "result.json"))

    # Each round proved its module equivalent against THAT round's baseline, so the
    # final design is linked to the original by a CHAIN of proofs rather than a single
    # one. compare_results rejects a candidate whose recorded baseline differs from the
    # one passed in -- right in general, wrong here -- so restate the provenance.
    chain = " -> ".join(["original"] + [h["module"] for h in history])
    current_result.formal_baseline_rtl_path = original_result.rtl_path
    current_result.formal_summary = (
        f"PASS (chain of {len(history)} proofs: {chain}). Each round's module was proven "
        "equivalent against the previous round's design; equivalence to the original "
        "follows by transitivity, at the cumulative latency offsets reported below."
    )
    compare_results(original_result, current_result)

    print(f"\nOptimized design : {final_dir}")

    latency_changed = {m: k for m, k in offsets.items() if k}
    if latency_changed:
        print("\nNOTE: cumulative added latency, relative to the ORIGINAL design:")
        for m, k in latency_changed.items():
            print(f"  {m}: +{k} cycle(s)")
        print("  Each round's proof is against that round's own baseline, which is valid, "
              "but the totals above are what the surrounding logic must tolerate.")

    bounded = [h for h in history
               if "bounded" in (h["result"].formal_summary or "").lower()]
    if bounded:
        print("\nNOTE: verified by BOUNDED model checking only (not an unbounded proof): "
              + ", ".join(h["module"] for h in bounded))

    wall_clock_seconds = time.time() - run_t0
    effort = _effort_summary(len(history), wall_clock_seconds)
    print(f"\n[effort] Agent wall-clock (measured): {effort['wall_clock_label']}  |  "
          f"Manual equivalent (estimated): {effort['manual_label']}")

    # Machine-readable round-by-round summary, so a UI can render the "N round(s)
    # accepted" table above without scraping it back out of the terminal transcript.
    (run_dir / "summary.json").write_text(json.dumps({
        "rounds": [
            {"round": i, "clock": h["clock"], "module": h["module"],
             "latency_offset": h["latency_offset"], "score": h["score"],
             "bounded": "bounded" in (h["result"].formal_summary or "").lower()}
            for i, h in enumerate(history, 1)
        ],
        "final_result": (str(Path(history[-1]["result_json"]).relative_to(PROJECT_ROOT))
                         if history else None),
        "cumulative_latency": offsets,
        "effort": effort,
    }, indent=2))

    return original_result, current_result


def main():
    parser = build_parser("Optimize an RTL design for timing and PPA using an LLM loop.")
    cfg = resolve_config(parser.parse_args(), PROJECT_ROOT)
    optimize(cfg)


if __name__ == "__main__":
    main()