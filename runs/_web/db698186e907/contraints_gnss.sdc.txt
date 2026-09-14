# ============================================================
# GPS L1 C/A Signal Generator - Timing Constraints
# Spartan-7 FPGA
# ============================================================

# ------------------------------------------------------------
# 1. Primary system clock
# 100 MHz = 10 ns period
# ------------------------------------------------------------

create_clock -name sys_clk \
    -period 10.000 \
    -waveform {0.000 5.000} \
    [get_ports clk]


# ------------------------------------------------------------
# 2. Input delays
# ------------------------------------------------------------
# Initial constraints for functional timing analysis.
# Adjust these values later if actual external interface
# timing is known.

set_input_delay -clock sys_clk -max 0.000 [get_ports rst]
set_input_delay -clock sys_clk -min 0.000 [get_ports rst]

set_input_delay -clock sys_clk -max 0.000 [get_ports {prn_id[*]}]
set_input_delay -clock sys_clk -min 0.000 [get_ports {prn_id[*]}]

set_input_delay -clock sys_clk -max 0.000 [get_ports {tuning_word[*]}]
set_input_delay -clock sys_clk -min 0.000 [get_ports {tuning_word[*]}]


# ------------------------------------------------------------
# 3. Output delays
# ------------------------------------------------------------

set_output_delay -clock sys_clk -max 0.000 [get_ports {tx_sample[*]}]
set_output_delay -clock sys_clk -min 0.000 [get_ports {tx_sample[*]}]

set_output_delay -clock sys_clk -max 0.000 [get_ports tx_valid]
set_output_delay -clock sys_clk -min 0.000 [get_ports tx_valid]


# ------------------------------------------------------------
# 4. Reset
# ------------------------------------------------------------
# If reset is asynchronous in the RTL, don't use the
# input-delay constraints above for reset.
# Instead, the reset path can be treated separately.