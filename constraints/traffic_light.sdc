create_clock -name clk -period 10 [get_ports clk]

set_input_delay 0 -clock clk [get_ports rst]
set_output_delay 0 -clock clk [get_ports red]
set_output_delay 0 -clock clk [get_ports green]
set_output_delay 0 -clock clk [get_ports yellow]

set_clock_uncertainty 0.1 [get_clocks clk]