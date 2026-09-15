// =============================================================
// Module : nco_cordic_top
// Description : Top-level wrapper
//               Clk  = 100 MHz
//               Fout = 4.092 MHz cosine  (Q1.15, 16-bit signed)
//
//  ┌──────────────────┐        ┌───────────────────┐
//  │  nco_phase_acc   │        │    cordic_cos      │
//  │  (32-bit accum)  │──16b──▶│  (16 iter pipeline)│──▶ cos_out
//  │  PhaseInc=       │ phase  │                   │
//  │  175_921_860     │        │  latency = 17 clk  │
//  └──────────────────┘        └───────────────────┘
//
// Total pipeline latency = 17 clock cycles (NCO is combinatorial
// on the output; CORDIC adds 16+1 = 17 registered stages).
// =============================================================
module nco_cordic_top (
    input  wire          clk,
    input  wire          rst_n,   // active-low synchronous reset
    input  wire          en,      // global clock enable
    output wire [15:0]   cos_out  // Q1.15 signed cosine @ 4.092 MHz
);

    wire [15:0] phase_w;

    // ---- NCO Phase Accumulator ----
    nco_phase_acc #(
        .ACCUM_W   (32),
        .PHASE_W   (16),
        .PHASE_INC (32'd175_921_860)
    ) u_nco (
        .clk       (clk),
        .rst_n     (rst_n),
        .en        (en),
        .phase_out (phase_w)
    );

    // ---- CORDIC Cosine Generator ----
    cordic_cos #(
        .DATA_W     (16),
        .ITERATIONS (16),
        .PHASE_W    (16)
    ) u_cordic (
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (en),
        .phase_in (phase_w),
        .cos_out  (cos_out)
    );

endmodule
