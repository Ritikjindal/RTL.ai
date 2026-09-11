create_clock -name clk -period 1.5 [get_ports clk]
set_input_delay  0.2 -clock clk [get_ports {rst valid a_vec b_vec}]
set_output_delay 0.2 -clock clk [get_ports {acc acc_valid}]
set_clock_uncertainty 0.05 [get_clocks clk]