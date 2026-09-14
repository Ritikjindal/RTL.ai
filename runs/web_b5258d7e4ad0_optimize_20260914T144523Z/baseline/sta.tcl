read_liberty /mnt/d/tushar/Downloads/RTL.ai/lib/NangateOpenCellLibrary_typical.lib
read_verilog /mnt/d/tushar/Downloads/RTL.ai/runs/web_b5258d7e4ad0_optimize_20260914T144523Z/baseline/netlist/web_b5258d7e4ad0_netlist.v
link_design benchmark_top
read_sdc /mnt/d/tushar/Downloads/RTL.ai/constraints/benchmark_top.sdc

set clk_groups {}
foreach c [all_clocks] { lappend clk_groups [get_name $c] }
report_checks -path_delay max -path_group $clk_groups -format full_clock_expanded > /mnt/d/tushar/Downloads/RTL.ai/runs/web_b5258d7e4ad0_optimize_20260914T144523Z/baseline/reports/timing.rpt

set_power_activity -input -activity 0.1
foreach p [all_inputs] {
    set n [get_name $p]
    if {[string match -nocase *clk* $n] || [string match -nocase *clock* $n]} {
        set_power_activity -input_ports $p -activity 1.0
    } elseif {[string match -nocase *rst* $n] || [string match -nocase *reset* $n]} {
        set_power_activity -input_ports $p -activity 0.0
    }
}
report_power > /mnt/d/tushar/Downloads/RTL.ai/runs/web_b5258d7e4ad0_optimize_20260914T144523Z/baseline/reports/power.rpt
