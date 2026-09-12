# constraints/ddc_fir.sdc — timing constraints for the DDC's 15-tap FIR block.
#
# Period is set below to put the block slightly inside violation, so the optimizer
# has a genuine timing target. See the note at the bottom for how it was chosen.

create_clock -name clk -period 1.48 [get_ports clk]

set_false_path -from [get_ports rst]

set_input_delay  0.2 -clock clk [get_ports {in_valid in_data}]
set_output_delay 0.2 -clock clk [get_ports {out_valid out_data}]