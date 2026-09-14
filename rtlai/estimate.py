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


def format_estimate(low, high) -> str:
    def m(s):
        return max(1, int(round(s / 60.0)))
    return f"{m(low)}-{m(high)} min"
