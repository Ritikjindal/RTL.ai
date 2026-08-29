# rtlai/parse_timing.py

import re
from rtlai.schema import TimingResult

# A "cell delay" line looks like:
#    0.08    0.17 ^ _30_/ZN (AND4_X1)
# A clock-network line looks like:
#    0.00    0.00   clock clk (rise edge)
#    0.00   10.00   clock network delay (ideal)
# We tell them apart because only real cell lines contain "instance/pin (CELLTYPE)".
CELL_LINE_RE = re.compile(r"^\s*[-\d.]+\s+[-\d.]+\s+[\^v]?\s*\S+/\S+\s+\(\S+\)")

STARTPOINT_RE = re.compile(r"^Startpoint:\s*(\S+)")
ENDPOINT_RE = re.compile(r"^Endpoint:\s*(\S+)")
PATH_GROUP_RE = re.compile(r"^Path Group:\s*(\S+)")
PATH_TYPE_RE = re.compile(r"^Path Type:\s*(\S+)")

ARRIVAL_RE = re.compile(r"([-+]?\d+\.\d+)\s+data arrival time")
REQUIRED_RE = re.compile(r"([-+]?\d+\.\d+)\s+data required time")
SLACK_RE = re.compile(r"([-+]?\d+\.\d+)\s+slack\s+\((MET|VIOLATED)\)")

# Picks up the clock period from a line like:
#   10.00   10.00   clock clk (rise edge)
# There are usually two such lines (launch edge at 0.00, capture edge at
# the period); we take the largest value seen as the period.
CLOCK_EDGE_RE = re.compile(r"^\s*([\d.]+)\s+[\d.]+\s+clock\s+\S+\s+\(rise edge\)")


def parse_timing_report(report_text: str) -> TimingResult:
    result = TimingResult()
    logic_depth = 0
    clock_period_ns = None

    for line in report_text.splitlines():
        if m := STARTPOINT_RE.match(line):
            result.startpoint = m.group(1)
        elif m := ENDPOINT_RE.match(line):
            result.endpoint = m.group(1)
        elif m := PATH_GROUP_RE.match(line):
            result.clock = m.group(1)
        elif m := PATH_TYPE_RE.match(line):
            result.path_type = m.group(1)
        elif m := CLOCK_EDGE_RE.match(line):
            edge_time = float(m.group(1))
            if clock_period_ns is None or edge_time > clock_period_ns:
                clock_period_ns = edge_time
        elif CELL_LINE_RE.match(line):
            logic_depth += 1
        elif m := ARRIVAL_RE.search(line):
            # The report repeats "data arrival time" in a later summary
            # block as a subtraction display (e.g. "-0.30  data arrival
            # time"), which is not a real value — only the first
            # occurrence, from the detailed path listing, is genuine.
            if result.data_arrival_time_ns is None:
                result.data_arrival_time_ns = float(m.group(1))
        elif m := REQUIRED_RE.search(line):
            if result.data_required_time_ns is None:
                result.data_required_time_ns = float(m.group(1))
        elif m := SLACK_RE.search(line):
            if result.worst_slack_ns is None:
                result.worst_slack_ns = float(m.group(1))

    result.logic_depth = logic_depth if logic_depth > 0 else None

    if clock_period_ns is not None and result.worst_slack_ns is not None:
        min_period_ns = clock_period_ns - result.worst_slack_ns
        if min_period_ns > 0:
            result.max_frequency_mhz = 1000.0 / min_period_ns

    return result