read_liberty /Users/ritikjindal/rtl-ai-project/lib/NangateOpenCellLibrary_typical.lib
read_verilog /Users/ritikjindal/rtl-ai-project/runs/traffic_light_optimize_20260910T175710Z/attempt_1/candidate/netlist/traffic_light_candidate_netlist.v
link_design traffic_light
read_sdc /Users/ritikjindal/rtl-ai-project/constraints/traffic_light.sdc

report_checks -path_delay max -format full_clock_expanded > /Users/ritikjindal/rtl-ai-project/runs/traffic_light_optimize_20260910T175710Z/attempt_1/candidate/reports/timing.rpt

set_power_activity -input -activity 0.1
set_power_activity -input_ports clk -activity 1.0
set_power_activity -input_ports rst -activity 0.0
report_power > /Users/ritikjindal/rtl-ai-project/runs/traffic_light_optimize_20260910T175710Z/attempt_1/candidate/reports/power.rpt
