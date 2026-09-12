read_liberty /mnt/d/tushar/Downloads/RTL.ai/lib/NangateOpenCellLibrary_typical.lib
read_verilog /mnt/d/tushar/Downloads/RTL.ai/runs/benchmark_top_20260911T194844Z/baseline/netlist/benchmark_top_netlist.v
link_design benchmark_top
read_sdc /mnt/d/tushar/Downloads/RTL.ai/constraints/benchmark_top.sdc

report_checks -path_delay max -format full_clock_expanded > /mnt/d/tushar/Downloads/RTL.ai/runs/benchmark_top_20260911T194844Z/baseline/reports/timing.rpt

set_power_activity -input -activity 0.1
set_power_activity -input_ports clk -activity 1.0
set_power_activity -input_ports rst -activity 0.0
report_power > /mnt/d/tushar/Downloads/RTL.ai/runs/benchmark_top_20260911T194844Z/baseline/reports/power.rpt
