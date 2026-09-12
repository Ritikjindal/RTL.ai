create_clock -name clk -period 2.40 [get_ports clk]
set_input_delay  0.2 -clock clk [get_ports {rst in_valid in_data in_last in_bytes}]
set_output_delay 0.2 -clock clk [get_ports {out_valid out_crc}]
set_clock_uncertainty 0.05 [get_clocks clk]