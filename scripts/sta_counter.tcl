# ============================================================
# RTL.ai - OpenSTA Timing Analysis
# ============================================================

# Get the directory containing this TCL script
set SCRIPT_DIR [file dirname [file normalize [info script]]]

# Project root = parent of scripts/
set PROJECT_ROOT [file normalize [file join $SCRIPT_DIR ".."]]

# Project paths
set NETLIST [file join $PROJECT_ROOT "netlist" "counter_netlist.v"]
set SDC     [file join $PROJECT_ROOT "constraints" "counter.sdc"]
set LIB     [file join $PROJECT_ROOT "lib" "NangateOpenCellLibrary_typical.lib"]
set REPORT  [file join $PROJECT_ROOT "reports" "timing_auto.rpt"]

puts "=============================================="
puts "RTL.ai - OpenSTA Timing Analysis"
puts "=============================================="

puts "Project root : $PROJECT_ROOT"
puts "Netlist      : $NETLIST"
puts "SDC          : $SDC"
puts "Library      : $LIB"
puts "Report       : $REPORT"
puts ""

# ------------------------------------------------------------
# Read library
# ------------------------------------------------------------

puts "Reading Liberty library..."

read_liberty $LIB

# ------------------------------------------------------------
# Read synthesized netlist
# ------------------------------------------------------------

puts "Reading netlist..."

read_verilog $NETLIST

link_design counter

# ------------------------------------------------------------
# Read timing constraints
# ------------------------------------------------------------

puts "Reading SDC..."

read_sdc $SDC

# ------------------------------------------------------------
# Timing analysis
# ------------------------------------------------------------

puts ""
puts "Running timing analysis..."
puts ""

report_checks -path_delay max -fields {slew cap input_pins nets fanout} > $REPORT

# Also print timing summary to terminal
report_checks -path_delay max

puts ""
puts "=============================================="
puts "OpenSTA timing analysis completed successfully."
puts "=============================================="
puts ""
puts "Generated timing report:"
puts $REPORT