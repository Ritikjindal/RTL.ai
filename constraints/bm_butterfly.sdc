# constraints/bm_butterfly.sdc — complex MAC (FFT radix-2) payload block.
#
# Period matches the benchmark's clk_e (1.65 ns), which is ~10% inside the block's
# measured 1.82 ns arrival, so the standalone violation mirrors the one it causes in
# benchmark_top.

create_clock -name clk -period 1.35 [get_ports clk]

set_false_path -from [get_ports rst]

set_input_delay  0.2 -clock clk [get_ports {in_valid ar ai br bi}]
set_output_delay 0.2 -clock clk [get_ports {out_valid cr ci}]

set_clock_uncertainty 0.05 [all_clocks]