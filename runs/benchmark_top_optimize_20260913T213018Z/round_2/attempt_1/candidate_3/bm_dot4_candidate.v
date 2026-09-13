// This module owns the critical path of the full design (clock 'clk_c', worst slack -1.32 ns).
module bm_dot4 #(
    parameter integer DW   = 8,
    parameter integer PW   = 2 * DW,
    parameter integer ACCW = PW + 4
) (
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   in_valid,
    input  wire [4*DW-1:0]        a_vec,
    input  wire [4*DW-1:0]        b_vec,
    output reg                    out_valid,
    output reg  signed [ACCW-1:0] acc
);

    reg [4*DW-1:0] a_reg, b_reg;
    reg            vld;
    reg signed [PW+1:0] sum_reg;
    reg            vld2;

    always @(posedge clk) begin
        if (rst) begin
            a_reg <= {(4*DW){1'b0}};
            b_reg <= {(4*DW){1'b0}};
            vld   <= 1'b0;
            sum_reg <= {(PW+2){1'b0}};
            vld2  <= 1'b0;
        end else begin
            a_reg <= a_vec;
            b_reg <= b_vec;
            vld   <= in_valid;
            sum_reg <= sum;
            vld2  <= vld;
        end
    end

    wire signed [DW-1:0] a0 = a_reg[1*DW-1:0*DW];
    wire signed [DW-1:0] a1 = a_reg[2*DW-1:1*DW];
    wire signed [DW-1:0] a2 = a_reg[3*DW-1:2*DW];
    wire signed [DW-1:0] a3 = a_reg[4*DW-1:3*DW];

    wire signed [DW-1:0] b0 = b_reg[1*DW-1:0*DW];
    wire signed [DW-1:0] b1 = b_reg[2*DW-1:1*DW];
    wire signed [DW-1:0] b2 = b_reg[3*DW-1:2*DW];
    wire signed [DW-1:0] b3 = b_reg[4*DW-1:3*DW];

    wire signed [PW-1:0] m0 = a0 * b0;
    wire signed [PW-1:0] m1 = a1 * b1;
    wire signed [PW-1:0] m2 = a2 * b2;
    wire signed [PW-1:0] m3 = a3 * b3;

    wire signed [PW:0]   h0  = m0 + m1;
    wire signed [PW:0]   h1  = m2 + m3;
    wire signed [PW+1:0] sum = h0 + h1;

    always @(posedge clk) begin
        if (rst) begin
            acc       <= {ACCW{1'b0}};
            out_valid <= 1'b0;
        end else begin
            if (vld2) acc <= acc + {{(ACCW-PW-2){sum_reg[PW+1]}}, sum_reg};
            out_valid <= vld2;
        end
    end

endmodule