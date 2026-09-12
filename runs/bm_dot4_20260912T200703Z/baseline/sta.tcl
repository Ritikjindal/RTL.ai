read_liberty /Users/ritikjindal/rtl-ai-project/lib/NangateOpenCellLibrary_typical.lib
read_verilog /Users/ritikjindal/rtl-ai-project/runs/bm_dot4_20260912T200703Z/baseline/netlist/bm_dot4_netlist.v
link_design bm_dot4
read_sdc /Users/ritikjindal/rtl-ai-project/constraints/ddc_fir.sdc

set clk_groups {}
foreach c [all_clocks] { lappend clk_groups [get_name $c] }
report_checks -path_delay max -path_group $clk_groups -format full_clock_expanded > /Users/ritikjindal/rtl-ai-project/runs/bm_dot4_20260912T200703Z/baseline/reports/timing.rpt

set_power_activity -input -activity 0.1
set_power_activity -input_ports clk -activity 1.0
set_power_activity -input_ports rst -activity 0.0
report_power > /Users/ritikjindal/rtl-ai-project/runs/bm_dot4_20260912T200703Z/baseline/reports/power.rpt
