# rtlai/optimizer/config.py

# For now, both stages use Haiku (cheap/fast) to get the pipeline working end-to-end.
# Once we're testing on a bigger benchmark design (roughly 10-15k+ cells), switch
# PLANNER_MODEL to "claude-sonnet-5" for stronger reasoning on the planning step.
PLANNER_MODEL = "claude-sonnet-5"
CODER_MODEL = "claude-haiku-4-5-20251001"

MAX_ATTEMPTS = 3
MAX_ROUNDS = 8
CANDIDATES_PER_ATTEMPT = 3