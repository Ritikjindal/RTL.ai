// Single-clock 4-lane multiply-accumulate unit.
//
// The critical path runs from the input registers, through an 8x8 multiply,
// through the adder tree, and into the accumulator - deliberately unpipelined,
// so it is long. This is the block that should fail a tight clock constraint.
module mac_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire        valid,
    input  wire [31:0] a_vec,   // 4 lanes x 8 bits
    input  wire [31:0] b_vec,
    output reg  [23:0] acc,
    output reg         acc_valid
);

    reg [31:0] a_reg, b_reg;
    reg        valid_reg;

    always @(posedge clk) begin
        if (rst) begin
            a_reg     <= 32'd0;
            b_reg     <= 32'd0;
            valid_reg <= 1'b0;
        end else begin
            a_reg     <= a_vec;
            b_reg     <= b_vec;
            valid_reg <= valid;
        end
    end

    // 4 parallel 8x8 multiplies
    wire [15:0] prod0 = a_reg[7:0]   * b_reg[7:0];
    wire [15:0] prod1 = a_reg[15:8]  * b_reg[15:8];
    wire [15:0] prod2 = a_reg[23:16] * b_reg[23:16];
    wire [15:0] prod3 = a_reg[31:24] * b_reg[31:24];

    // First CSA layer: reduce prod0, prod1, prod2 to sum + carry
    wire [15:0] csa1_sum;
    wire [16:0] csa1_carry;
    
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : csa_layer1
            wire a = prod0[i];
            wire b = prod1[i];
            wire c = prod2[i];
            assign csa1_sum[i] = a ^ b ^ c;
            assign csa1_carry[i+1] = (a & b) | (b & c) | (c & a);
        end
        assign csa1_carry[0] = 1'b0;
    endgenerate

    // Second CSA layer: reduce csa1_sum, csa1_carry, prod3 to final sum + carry
    wire [17:0] sum_s;
    wire [17:0] sum_c;
    
    generate
        for (i = 0; i < 17; i = i + 1) begin : csa_layer2
            wire a = (i < 16) ? csa1_sum[i] : 1'b0;
            wire b = csa1_carry[i];
            wire c = (i < 16) ? prod3[i] : 1'b0;
            assign sum_s[i] = a ^ b ^ c;
            assign sum_c[i+1] = (a & b) | (b & c) | (c & a);
        end
        assign sum_c[0] = 1'b0;
    endgenerate

    // Final carry-propagate add: sum_s + sum_c
    wire [17:0] sum = sum_s + sum_c;

    always @(posedge clk) begin
        if (rst) begin
            acc       <= 24'd0;
            acc_valid <= 1'b0;
        end else if (valid_reg) begin
            acc       <= acc + {6'd0, sum};
            acc_valid <= 1'b1;
        end else begin
            acc_valid <= 1'b0;
        end
    end

endmodule