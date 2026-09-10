# optimize.py — the GenAI optimization loop
from pathlib import Path
from datetime import datetime, timezone

from analyze import analyze_design, RTL_FILE, TOP_MODULE, DESIGN_NAME, RUNS_DIR
from rtlai.formal import verify_equivalence, FormalError
from rtlai.compare import compare_results
from rtlai.optimizer.planner import generate_plan
from rtlai.optimizer.coder import generate_code
from rtlai.optimizer.config import MAX_ATTEMPTS
from rtlai.optimizer.counterexample import extract_counterexample
from rtlai.optimizer.decide import decide

def optimize():
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    run_dir = RUNS_DIR / f"{DESIGN_NAME}_optimize_{timestamp}"

    print(f"[baseline] Synthesizing + measuring baseline '{DESIGN_NAME}'...")
    rtl_code = RTL_FILE.read_text()
    baseline_result = analyze_design(
        rtl_path=RTL_FILE,
        design_name=DESIGN_NAME,
        run_dir=run_dir / "baseline",
        timestamp=timestamp,
    )
    print(f"      Done: {run_dir / 'baseline' / 'result.json'}")

    feedback = None

    for attempt in range(1, MAX_ATTEMPTS + 1):
        print(f"\n[attempt {attempt}/{MAX_ATTEMPTS}] Asking planner for a plan...")
        plan = generate_plan(rtl_code, baseline_result, previous_feedback=feedback)
        print(plan)

        print(f"[attempt {attempt}] Asking coder to implement it...")
        candidate_code = generate_code(rtl_code, plan)

        attempt_dir = run_dir / f"attempt_{attempt}"
        attempt_dir.mkdir(parents=True, exist_ok=True)
        candidate_rtl_path = attempt_dir / f"{DESIGN_NAME}_candidate.v"
        candidate_rtl_path.write_text(candidate_code)
        if candidate_code.strip() == rtl_code.strip():
            print(f"[attempt {attempt}] Candidate is identical to the baseline - no change was made.")
            feedback = (
                f"Attempt {attempt} produced RTL identical to the baseline. You must actually change "
                "the design's structure, not return the original code unchanged."
            )
            continue

        print(f"[attempt {attempt}] Checking formal equivalence...")
        try:
            eq_result = verify_equivalence(
                original_rtl=RTL_FILE,
                candidate_rtl=candidate_rtl_path,
                top_module=TOP_MODULE,
                run_dir=attempt_dir / "formal",
            )
        except FormalError as e:
            print(f"[attempt {attempt}] FormalError: {e}")
            feedback = f"Attempt {attempt} could not even be formally checked (interface mismatch or tool error): {e}"
            continue

        if not eq_result.passed:
            print(f"[attempt {attempt}] {eq_result.summary}")
            feedback = (
                f"Attempt {attempt} FAILED formal equivalence against the baseline. "
                "The candidate was NOT behaviorally identical."
            )
            cex = extract_counterexample(attempt_dir / "formal")
            if cex:
                feedback += (
                    "\n\nA formal counterexample was found. Applying the following input stimulus "
                    "(one state per clock cycle) makes the candidate's outputs differ from the "
                    "baseline's:\n"
                    f"{cex}\n\n"
                    "Trace through the baseline RTL by hand for this exact input sequence, work out "
                    "what your proposed change would produce instead, identify the specific signal "
                    "that differs and why, and propose a corrected approach that fixes it."
                )
            continue

        print(f"[attempt {attempt}] {eq_result.summary}")
        print(f"[attempt {attempt}] Equivalent! Synthesizing + measuring candidate...")
        candidate_result = analyze_design(
            rtl_path=candidate_rtl_path,
            design_name=f"{DESIGN_NAME}_candidate",
            run_dir=attempt_dir / "candidate",
            timestamp=timestamp,
        )
        candidate_result.formal_checked = True
        candidate_result.formal_passed = True
        candidate_result.formal_summary = eq_result.summary
        candidate_result.formal_baseline_rtl_path = str(RTL_FILE)
        candidate_result.to_json(str(attempt_dir / "candidate" / "result.json"))

        accepted, reason = decide(baseline_result, candidate_result)
        compare_results(baseline_result, candidate_result)

        if accepted:
            print(f"\n[accepted] Attempt {attempt}: {reason}")
            print(f"\nAccepted candidate RTL: {candidate_rtl_path}")
            return baseline_result, candidate_result

        print(f"[attempt {attempt}] {reason}")
        feedback = (
            f"Attempt {attempt} passed formal equivalence but was rejected. {reason} "
            "Propose a different approach that actually improves area, power, or maximum frequency "
            "without significantly regressing the others."
        )

    print(f"\n[rejected] No improved candidate found after {MAX_ATTEMPTS} attempts. Keeping baseline.")
    return baseline_result, None


if __name__ == "__main__":
    optimize()