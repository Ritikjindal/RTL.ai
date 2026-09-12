// designs/bm_butterfly.v — complex multiply plus accumulate (FFT radix-2 style).
// Four real multiplies and two adds feed an accumulator in a single clock.
`default_nettype wire

module bm_butterfly #(
    parameter integer DW   = 8,
    parameter integer PW   = 2 * DW,
    parameter integer ACCW = PW + 4
) (
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   in_valid,
    input  wire signed [DW-1:0]   ar,
    input  wire signed [DW-1:0]   ai,
    input  wire signed [DW-1:0]   br,
    input  wire signed [DW-1:0]   bi,
    output reg                    out_valid,
    output reg  signed [ACCW-1:0] cr,
    output reg  signed [ACCW-1:0] ci
);

    reg signed [DW-1:0] ar_r, ai_r, br_r, bi_r;
    reg                 vld;
    
    reg signed [PW-1:0] rr_r, ii_r, ri_r, ir_r;
    reg                 vld2;

    always @(posedge clk) begin
        if (rst) begin
            ar_r <= {DW{1'b0}}; ai_r <= {DW{1'b0}};
            br_r <= {DW{1'b0}}; bi_r <= {DW{1'b0}};
            vld  <= 1'b0;
        end else begin
            ar_r <= ar; ai_r <= ai; br_r <= br; bi_r <= bi;
            vld  <= in_valid;
        end
    end

    wire signed [PW-1:0] rr = ar_r * br_r;
    wire signed [PW-1:0] ii = ai_r * bi_r;
    wire signed [PW-1:0] ri = ar_r * bi_r;
    wire signed [PW-1:0] ir = ai_r * br_r;

    always @(posedge clk) begin
        if (rst) begin
            rr_r <= {PW{1'b0}};
            ii_r <= {PW{1'b0}};
            ri_r <= {PW{1'b0}};
            ir_r <= {PW{1'b0}};
            vld2 <= 1'b0;
        end else begin
            rr_r <= rr;
            ii_r <= ii;
            ri_r <= ri;
            ir_r <= ir;
            vld2 <= vld;
        end
    end

    wire signed [PW:0] real_part = rr_r - ii_r;
    wire signed [PW:0] imag_part = ri_r + ir_r;

    always @(posedge clk) begin
        if (rst) begin
            cr        <= {ACCW{1'b0}};
            ci        <= {ACCW{1'b0}};
            out_valid <= 1'b0;
        end else begin
            if (vld2) begin
                cr <= cr + {{(ACCW-PW-1){real_part[PW]}}, real_part};
                ci <= ci + {{(ACCW-PW-1){imag_part[PW]}}, imag_part};
            end
            out_valid <= vld2;
        end
    end

endmodule