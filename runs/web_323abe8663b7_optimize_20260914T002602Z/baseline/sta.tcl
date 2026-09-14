read_liberty /mnt/d/tushar/Downloads/RTL.ai/lib/NangateOpenCellLibrary_typical.lib
read_verilog /mnt/d/tushar/Downloads/RTL.ai/runs/web_323abe8663b7_optimize_20260914T002602Z/baseline/netlist/web_323abe8663b7_netlist.v
link_design bm_mac8
read_sdc /mnt/d/tushar/Downloads/RTL.ai/constraints/bm_mac8.sdc

set clk_groups {}
foreach c [all_clocks] { lappend clk_groups [get_name $c] }
report_checks -path_delay max -path_group $clk_groups -format full_clock_expanded > /mnt/d/tushar/Downloads/RTL.ai/runs/web_323abe8663b7_optimize_20260914T002602Z/baseline/reports/timing.rpt

set_power_activity -input -activity 0.1
foreach p [all_inputs] {
    set n [get_name $p]
    if {[string match -nocase *clk* $n] || [string match -nocase *clock* $n]} {
        set_power_activity -input_ports $p -activity 1.0
    } elseif {[string match -nocase *rst* $n] || [string match -nocase *reset* $n]} {
        set_power_activity -input_ports $p -activity 0.0
    }
}
report_power > /mnt/d/tushar/Downloads/RTL.ai/runs/web_323abe8663b7_optimize_20260914T002602Z/baseline/reports/power.rpt
