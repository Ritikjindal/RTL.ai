create_clock -name clk -period 10 [get_ports clk]

set_input_delay 0 -clock clk [get_ports rst]
set_input_delay 0 -clock clk [get_ports a]
set_input_delay 0 -clock clk [get_ports b]
set_input_delay 0 -clock clk [get_ports opcode]

set_output_delay 0 -clock clk [get_ports result]
set_output_delay 0 -clock clk [get_ports zero]
set_output_delay 0 -clock clk [get_ports carry]

set_clock_uncertainty 0.1 [get_clocks clk]