# rtlai/estimate.py — runtime estimation for an optimization run.
#
# A single number would be dishonest: formal verification time varies by two orders of
# magnitude between a fast proof and a double timeout, so this returns a (low, high)
# range that starts wide (priors only) and tightens as real rounds complete.

import re
from pathlib import Path

# Calibration constants (seconds). Tune these from your own runs.
T_PLAN      = 35.0    # planner call
T_CODE      = 25.0    # one coder call
T_FORMAL_OK = 20.0    # a formal check that closes quickly
T_SYNTH_DEF = 90.0    # fallback baseline synth+STA if not yet measured

# Rough hours a human engineer would need to hand-rewrite one module-level transform
# and re-verify it (read the timing report, plan a change, edit the RTL, re-run
# synthesis/STA, convince themselves it's still equivalent). Deliberately a wide,
# round range rather than a false-precision single number -- this is a comparison
# point, not a measurement.
MANUAL_HOURS_PER_TRANSFORM = (3.0, 4.0)


def count_clocks(sdc_path) -> int:
    """Rounds = number of master clocks in the SDC."""
    try:
        text = Path(sdc_path).read_text(errors="ignore")
    except OSError:
        return 1
    return max(1, len(re.findall(r"^\s*create_clock", text, re.M)))


def estimate_seconds(sdc_path, cfg, baseline_seconds=None, round_seconds=None):
    """Return (low, high) wall-clock seconds for the whole run.

    baseline_seconds: measured duration of the baseline synth+STA, if known.
    round_seconds:    list of measured durations of completed rounds.
    """
    rounds = count_clocks(sdc_path)
    n = getattr(cfg, "CANDIDATES_PER_ATTEMPT", 3)
    formal_timeout = getattr(cfg, "FORMAL_TIMEOUT_S", 300)

    # If we have real rounds, extrapolate from them -- far better than priors.
    if round_seconds:
        done = len(round_seconds)
        avg = sum(round_seconds) / done
        remaining = max(0, rounds - done)
        best = sum(round_seconds) + remaining * avg * 0.6
        worst = sum(round_seconds) + remaining * avg * 1.8
        return best, worst

    t_synth = baseline_seconds if baseline_seconds else T_SYNTH_DEF

    # Best case: one plan, N samples, all verify fast, all re-synthesized.
    per_round_low = T_PLAN + n * (T_CODE + T_FORMAL_OK + t_synth)

    # Worst case: two plans abandoned on timeout. Samples are skipped after the
    # first timeout, and each timeout costs prove + bounded fallback.
    per_round_high = 2 * (T_PLAN + T_CODE + 2 * formal_timeout)

    low = t_synth + rounds * per_round_low
    high = t_synth + rounds * per_round_high
    return low, high


def estimate_analyze_seconds(baseline_seconds=None):
    """
    Return (low, high) wall-clock seconds for an analyze-only run: one Yosys
    synthesis + OpenSTA pass, nothing else -- no planner, no coder, no formal
    verification, no per-clock rounds. Much shorter and much tighter than an
    optimize run, so it gets its own narrow estimate rather than sharing
    estimate_seconds' optimize-loop math.
    """
    t_synth = baseline_seconds if baseline_seconds else T_SYNTH_DEF
    return t_synth * 0.6, t_synth * 1.6


def format_estimate(low, high) -> str:
    def m(s):
        return max(1, int(round(s / 60.0)))
    return f"{m(low)}-{m(high)} min"


def manual_equivalent_hours(accepted_rounds: int):
    """
    (low, high) hours a human engineer would need to hand-produce what `accepted_rounds`
    accepted transforms did -- one manual rewrite-and-reverify per round. A constant
    per-transform range, not derived from anything the run measured, so it stays valid
    even for a stopped or zero-round run (accepted_rounds=0 -> (0, 0)).
    """
    low, high = MANUAL_HOURS_PER_TRANSFORM
    return accepted_rounds * low, accepted_rounds * high


def format_hours(low, high) -> str:
    def h(x):
        return f"{x:g}"
    return f"{h(low)}-{h(high)} h"


def format_duration(seconds) -> str:
    """A single measured duration (e.g. '14 min', '1h 12m') -- distinct from
    format_estimate's (low, high) range, since this is a fact, not a guess."""
    if seconds is None:
        return "—"
    minutes = seconds / 60.0
    if minutes < 60:
        return f"{minutes:.0f} min"
    h = int(minutes // 60)
    m = int(round(minutes % 60))
    return f"{h}h {m}m" if m else f"{h}h"
