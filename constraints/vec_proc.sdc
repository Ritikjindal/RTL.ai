create_clock -name clk -period 10.0 [get_ports clk]
set_input_delay  1.0 -clock clk [get_ports {rst start op a_vec b_vec}]
set_output_delay 1.0 -clock clk [get_ports {result_vec done}]
set_clock_uncertainty 0.1 [get_clocks clk]