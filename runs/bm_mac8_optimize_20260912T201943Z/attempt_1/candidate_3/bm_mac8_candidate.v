// designs/bm_mac8.v — 8-lane 8x8 MAC whose products are summed in a BALANCED TREE.
`default_nettype wire

module bm_mac8 #(
    parameter integer DW   = 8,
    parameter integer PW   = 2 * DW,
    parameter integer ACCW = PW + 5
) (
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   in_valid,
    input  wire [8*DW-1:0]        a_vec,
    input  wire [8*DW-1:0]        b_vec,
    output reg                    out_valid,
    output reg  [ACCW-1:0]        acc
);

    reg [8*DW-1:0] a_reg, b_reg;
    reg            vld;

    always @(posedge clk) begin
        if (rst) begin
            a_reg <= {(8*DW){1'b0}};
            b_reg <= {(8*DW){1'b0}};
            vld   <= 1'b0;
        end else begin
            a_reg <= a_vec;
            b_reg <= b_vec;
            vld   <= in_valid;
        end
    end

    wire [PW-1:0] m0 = a_reg[1*DW-1:0*DW] * b_reg[1*DW-1:0*DW];
    wire [PW-1:0] m1 = a_reg[2*DW-1:1*DW] * b_reg[2*DW-1:1*DW];
    wire [PW-1:0] m2 = a_reg[3*DW-1:2*DW] * b_reg[3*DW-1:2*DW];
    wire [PW-1:0] m3 = a_reg[4*DW-1:3*DW] * b_reg[4*DW-1:3*DW];
    wire [PW-1:0] m4 = a_reg[5*DW-1:4*DW] * b_reg[5*DW-1:4*DW];
    wire [PW-1:0] m5 = a_reg[6*DW-1:5*DW] * b_reg[6*DW-1:5*DW];
    wire [PW-1:0] m6 = a_reg[7*DW-1:6*DW] * b_reg[7*DW-1:6*DW];
    wire [PW-1:0] m7 = a_reg[8*DW-1:7*DW] * b_reg[8*DW-1:7*DW];

    // Balanced binary reduction tree for accumulation
    // Level 1: Four parallel additions
    wire [ACCW-1:0] s0 = m0 + m1;
    wire [ACCW-1:0] s1 = m2 + m3;
    wire [ACCW-1:0] s2 = m4 + m5;
    wire [ACCW-1:0] s3 = m6 + m7;

    // Level 2: Two parallel additions
    wire [ACCW-1:0] t0 = s0 + s1;
    wire [ACCW-1:0] t1 = s2 + s3;

    // Level 3: Final addition
    wire [ACCW-1:0] acc_comb = t0 + t1;

    always @(posedge clk) begin
        if (rst) begin
            acc       <= {ACCW{1'b0}};
            out_valid <= 1'b0;
        end else begin
            acc       <= acc_comb;
            out_valid <= vld;
        end
    end

endmodule