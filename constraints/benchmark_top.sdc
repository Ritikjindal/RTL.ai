# RTL.ai benchmark circuit constraints.
#
# Five independent asynchronous master clocks, each with one generated clock
# from its divider. Periods are set just BELOW each payload block's achievable
# frequency (measured by LogikBench on a 45nm library), so the design fails
# timing out of the box - that is the scenario the optimizer exists to fix.

# ---------------- master clocks ----------------
# picorv32 achieves ~403 MHz (2.48 ns); constrain to 2.2 ns
create_clock -name clk_a -period 2.20 [get_ports clk_a]
# ddc achieves ~519 MHz (1.93 ns); constrain to 1.7 ns
create_clock -name clk_b -period 1.70 [get_ports clk_b]
# sha256 achieves ~469 MHz (2.13 ns); constrain to 1.9 ns
create_clock -name clk_c -period 1.90 [get_ports clk_c]
# sad8x8 achieves ~477 MHz (2.10 ns); constrain to 1.85 ns
create_clock -name clk_d -period 1.85 [get_ports clk_d]
# crc32 achieves ~460 MHz (2.17 ns); constrain to 1.9 ns
create_clock -name clk_e -period 1.90 [get_ports clk_e]

# ---------------- generated clocks ----------------
create_generated_clock -name clk_a_div -source [get_ports clk_a] -divide_by 2 \
    [get_ports clk_a_div]
create_generated_clock -name clk_b_div -source [get_ports clk_b] -divide_by 4 \
    [get_ports clk_b_div]
create_generated_clock -name clk_c_div -source [get_ports clk_c] -divide_by 6 \
    [get_ports clk_c_div]
create_generated_clock -name clk_d_div -source [get_ports clk_d] -divide_by 8 \
    [get_ports clk_d_div]
create_generated_clock -name clk_e_div -source [get_ports clk_e] -divide_by 10 \
    [get_ports clk_e_div]

# ---------------- domain independence ----------------
# Each master is synchronous to its OWN divided clock, and asynchronous to every
# other domain. Without this, STA would try to time the CDC paths between
# domains and report meaningless violations.
set_clock_groups -asynchronous \
    -group {clk_a clk_a_div} \
    -group {clk_b clk_b_div} \
    -group {clk_c clk_c_div} \
    -group {clk_d clk_d_div} \
    -group {clk_e clk_e_div}

# ---------------- I/O ----------------
set_input_delay  0.2 -clock clk_a [get_ports {rst_async stim}]
set_output_delay 0.2 -clock clk_a [get_ports status_a]
set_output_delay 0.2 -clock clk_b [get_ports status_b]
set_output_delay 0.2 -clock clk_c [get_ports status_c]
set_output_delay 0.2 -clock clk_d [get_ports status_d]
set_output_delay 0.2 -clock clk_e [get_ports status_e]

set_clock_uncertainty 0.05 [all_clocks]