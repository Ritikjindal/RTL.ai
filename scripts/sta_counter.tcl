read_liberty ../lib/NangateOpenCellLibrary_typical.lib

read_verilog ../netlist/counter_synth.v

link_design counter

read_sdc ../constraints/counter.sdc

report_checks -path_delay max -fields {slew cap input_pins} -digits 3

report_wns
report_tns

report_clock_skew