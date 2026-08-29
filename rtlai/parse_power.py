# rtlai/parse_power.py

import re
from rtlai.schema import PowerResult

# Matches the "Total" row of OpenSTA's report_power table, e.g.:
#   Total                  4.93e-06   0.00e+00   1.02e-06   5.95e-06 100.0%
# Columns are: internal, switching, leakage, total (all in Watts).
TOTAL_ROW_RE = re.compile(
    r"^Total\s+"
    r"([0-9.eE+-]+)\s+"
    r"([0-9.eE+-]+)\s+"
    r"([0-9.eE+-]+)\s+"
    r"([0-9.eE+-]+)",
    re.MULTILINE,
)


def parse_power_report(report_text: str) -> PowerResult:
    result = PowerResult()

    m = TOTAL_ROW_RE.search(report_text)
    if m:
        internal_w, switching_w, leakage_w, total_w = (float(x) for x in m.groups())
        result.internal_uw = internal_w * 1e6
        result.switching_uw = switching_w * 1e6
        result.leakage_uw = leakage_w * 1e6
        result.total_uw = total_w * 1e6

    return result