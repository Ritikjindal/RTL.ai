// This module owns the critical path of the full design (clock 'clk_b', worst slack -0.71 ns).
module bm_fir6 #(
    parameter integer DW   = 8,
    parameter integer CW   = 8,
    parameter integer ACCW = DW + CW + 3
) (
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   in_valid,
    input  wire signed [DW-1:0]   in_data,
    output reg                    out_valid,
    output reg  signed [ACCW-1:0] out_data
);

    // Real coefficients. Nothing here is zero, so every tap survives synthesis.
    localparam signed [CW-1:0] C0 = 8'sd23;
    localparam signed [CW-1:0] C1 = -8'sd47;
    localparam signed [CW-1:0] C2 = 8'sd81;
    localparam signed [CW-1:0] C3 = 8'sd81;
    localparam signed [CW-1:0] C4 = -8'sd47;
    localparam signed [CW-1:0] C5 = 8'sd23;

    reg signed [DW-1:0] t0, t1, t2, t3, t4, t5;
    reg                 vld;

    always @(posedge clk) begin
        if (rst) begin
            t0 <= {DW{1'b0}}; t1 <= {DW{1'b0}}; t2 <= {DW{1'b0}};
            t3 <= {DW{1'b0}}; t4 <= {DW{1'b0}}; t5 <= {DW{1'b0}};
            vld <= 1'b0;
        end else begin
            if (in_valid) begin
                t5 <= t4; t4 <= t3; t3 <= t2; t2 <= t1; t1 <= t0; t0 <= in_data;
            end
            vld <= in_valid;
        end
    end

    wire signed [ACCW-1:0] p0 = t0 * C0;
    wire signed [ACCW-1:0] p1 = t1 * C1;
    wire signed [ACCW-1:0] p2 = t2 * C2;
    wire signed [ACCW-1:0] p3 = t3 * C3;
    wire signed [ACCW-1:0] p4 = t4 * C4;
    wire signed [ACCW-1:0] p5 = t5 * C5;

    // Balanced binary tree instead of serial ripple chain
    // Level 1 (parallel): pair products
    wire signed [ACCW-1:0] s1 = p0 + p1;
    wire signed [ACCW-1:0] s2 = p2 + p3;
    wire signed [ACCW-1:0] s3 = p4 + p5;
    
    // Level 2: combine first two pairs
    wire signed [ACCW-1:0] s4 = s1 + s2;
    
    // Level 3: combine with final pair
    wire signed [ACCW-1:0] s5 = s4 + s3;

    always @(posedge clk) begin
        if (rst) begin
            out_data  <= {ACCW{1'b0}};
            out_valid <= 1'b0;
        end else begin
            out_data  <= s5;
            out_valid <= vld;
        end
    end

endmodule