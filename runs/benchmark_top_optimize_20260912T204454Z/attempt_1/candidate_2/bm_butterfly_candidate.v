// This module owns the critical path of the full design (clock 'clk_e', worst slack -2.32 ns).
module bm_butterfly #(
    parameter integer DW   = 8,
    parameter integer PW   = 2 * DW,
    parameter integer ACCW = PW + 4
) (
    input  wire            clk,
    input  wire            rst,
    input  wire            in_valid,
    input  wire [DW-1:0]   ar,
    input  wire [DW-1:0]   ai,
    input  wire [DW-1:0]   br,
    input  wire [DW-1:0]   bi,
    output reg             out_valid,
    output reg  [ACCW-1:0] cr,
    output reg  [ACCW-1:0] ci
);

    reg [DW-1:0] ar_r, ai_r, br_r, bi_r;
    reg          vld;

    always @(posedge clk) begin
        if (rst) begin
            ar_r <= {DW{1'b0}};
            ai_r <= {DW{1'b0}};
            br_r <= {DW{1'b0}};
            bi_r <= {DW{1'b0}};
            vld  <= 1'b0;
        end else begin
            ar_r <= ar;
            ai_r <= ai;
            br_r <= br;
            bi_r <= bi;
            vld  <= in_valid;
        end
    end

    wire [PW-1:0] rr = ar_r * br_r;
    wire [PW-1:0] ii = ai_r * bi_r;
    wire [PW-1:0] ri = ar_r * bi_r;
    wire [PW-1:0] ir = ai_r * br_r;

    wire [PW:0] real_part = rr + ii;
    wire [PW:0] imag_part = ri + ir;

    reg [PW:0] real_part_r, imag_part_r;
    reg        vld2;

    always @(posedge clk) begin
        if (rst) begin
            real_part_r <= {(PW+1){1'b0}};
            imag_part_r <= {(PW+1){1'b0}};
            vld2        <= 1'b0;
        end else begin
            real_part_r <= real_part;
            imag_part_r <= imag_part;
            vld2        <= vld;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            cr        <= {ACCW{1'b0}};
            ci        <= {ACCW{1'b0}};
            out_valid <= 1'b0;
        end else begin
            if (vld2) begin
                cr <= cr + {{(ACCW-PW-1){1'b0}}, real_part_r};
                ci <= ci + {{(ACCW-PW-1){1'b0}}, imag_part_r};
            end
            out_valid <= vld2;
        end
    end

endmodule