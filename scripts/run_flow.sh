#!/bin/bash

set -e

echo "======================================"
echo "        RTL.ai AUTOMATED FLOW"
echo "======================================"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$PROJECT_ROOT/scripts"
REPORTS="$PROJECT_ROOT/reports"

mkdir -p "$REPORTS"

echo ""
echo "[1/4] Running Yosys synthesis..."
cd "$SCRIPTS"
yosys -s synth_counter.ys

echo ""
echo "[2/4] Area report generated..."
echo "--------------------------------------"
grep -A 30 "Number of cells" "$REPORTS/area.rpt" || true

echo ""
echo "[3/4] Running OpenSTA..."
sta -exit sta_counter.tcl > "$REPORTS/timing.rpt"

echo ""
echo "[4/4] Timing summary"
echo "--------------------------------------"

grep -E "wns|tns|slack" "$REPORTS/timing.rpt" || true

echo ""
echo "Timing report:"
echo "$REPORTS/timing.rpt"

echo ""
echo "======================================"
echo "          FLOW COMPLETED"
echo "======================================"