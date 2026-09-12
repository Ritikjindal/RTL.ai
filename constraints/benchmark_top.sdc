# RTL.ai benchmark circuit constraints.
#
# Five independent asynchronous master clocks, each with one generated clock from its
# divider. Each period is set roughly 10% below the achievable period of that domain's
# payload block (measured standalone on the Nangate 45nm library), so the design fails
# timing out of the box -- that is the scenario the optimizer exists to fix.

# ---------------- master clocks ----------------
# A: mac_unit      x10, measured arrival 1.63 ns
create_clock -name clk_a -period 1.50 [get_ports clk_a]
# B: bm_fir6       x11, measured arrival 1.56 ns
create_clock -name clk_b -period 1.45 [get_ports clk_b]
# C: bm_dot4        x4, measured arrival ~1.90 ns
create_clock -name clk_c -period 1.75 [get_ports clk_c]
# D: bm_mac8 x5, measured arrival 1.91 ns  
create_clock -name clk_d -period 1.70 [get_ports clk_d]
# E: bm_fsm_ctrl x5, measured arrival 2.37 ns
create_clock -name clk_e -period 2.15 [get_ports clk_e]

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
# Each master is synchronous to its OWN divided clock, and asynchronous to every other
# domain. Without this, STA would try to time the CDC paths between domains and report
# meaningless violations.
set_clock_groups -asynchronous \
    -group {clk_a clk_a_div} \
    -group {clk_b clk_b_div} \
    -group {clk_c clk_c_div} \
    -group {clk_d clk_d_div} \
    -group {clk_e clk_e_div}

# ---------------- reset ----------------
# Resets are synchronized per domain and de-asserted once, many cycles before data
# flows, so timing them against the functional period is not meaningful. This matters
# here because the flow is unbuffered gate-level synthesis with no placement: Yosys
# builds no buffer trees, so a reset net's fanout alone costs several nanoseconds on a
# single inverter and hides the datapath logic entirely. Real flows buffer this; we
# exclude it instead.
set_false_path -through [get_nets *rst*]

# ---------------- I/O ----------------
set_input_delay  0.2 -clock clk_a [get_ports rst_async]

set_output_delay 0.2 -clock clk_a [get_ports out_a]
set_output_delay 0.2 -clock clk_b [get_ports out_b]
set_output_delay 0.2 -clock clk_c [get_ports out_c]
set_output_delay 0.2 -clock clk_d [get_ports out_d]
set_output_delay 0.2 -clock clk_e [get_ports out_e]

set_clock_uncertainty 0.05 [all_clocks]