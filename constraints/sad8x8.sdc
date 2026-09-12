create_clock -name clk -period 7.00 [get_ports clk]
set_input_delay  0.3 -clock clk [get_ports {rst valid_in curblk refblk}]
set_output_delay 0.3 -clock clk [get_ports {valid_out sad}]
set_clock_uncertainty 0.05 [get_clocks clk]