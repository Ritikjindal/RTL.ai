# ============================================================
# RTL.ai - OpenSTA Timing + Power Analysis
# ============================================================

set project_root ".."

set netlist "../netlist/counter_netlist.v"
set sdc "../constraints/counter.sdc"
set lib "../lib/NangateOpenCellLibrary_typical.lib"

set timing_report "../reports/timing_auto.rpt"
set power_report "../reports/power_auto.rpt"

puts "=============================================="
puts "RTL.ai - OpenSTA Timing Analysis"
puts "=============================================="

puts "Project root : $project_root"
puts "Netlist      : $netlist"
puts "SDC          : $sdc"
puts "Library      : $lib"
puts "Report       : $timing_report"

# ============================================================
# Read library
# ============================================================

puts "\nReading Liberty library..."
read_liberty $lib

# ============================================================
# Read synthesized netlist
# ============================================================

puts "Reading netlist..."
read_verilog $netlist

link_design counter

# ============================================================
# Read constraints
# ============================================================

puts "Reading SDC..."
read_sdc $sdc

# ============================================================
# Timing analysis
# ============================================================

puts "\nRunning timing analysis..."

report_checks \
    -path_delay max \
    -format full_clock_expanded \
    > $timing_report

# ============================================================
# Power analysis
# ============================================================

puts "Running power analysis..."

# Set default switching activity for primary inputs
set_power_activity -input -activity 0.1

# Clock toggles every cycle
set_power_activity -input_ports clk -activity 1.0

# Reset is assumed inactive
set_power_activity -input_ports rst -activity 0.0

# Generate power report
report_power > $power_report

puts "\n=============================================="
puts "OpenSTA analysis completed successfully."
puts "=============================================="

puts "Generated timing report:"
puts $timing_report

puts "Generated power report:"
puts $power_report