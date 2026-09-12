# constraints/ddc.sdc — timing constraints for the DDC payload block.
#
# The DDC is NCO mixer -> CIC decimator (4 stages, R=8) -> 15-tap FIR. The 16x16
# signed multipliers in the mixer and the FIR tap accumulation are the expected
# critical paths, so the period below is set to put the design slightly inside
# violation and give the optimizer a real timing target.

create_clock -name clk -period 2.60 [get_ports clk]

# Reset is synchronous and released well before any real traffic; excluding it from
# timing keeps the reported critical path on the datapath rather than the reset fanout.
set_false_path -from [get_ports rst]

# Modest I/O timing so arrival/required times reflect the internal logic, not an
# arbitrary boundary assumption.
set_input_delay  0.2 -clock clk [get_ports {in_valid ftw in_data}]
set_output_delay 0.2 -clock clk [get_ports {out_valid iout qout}]