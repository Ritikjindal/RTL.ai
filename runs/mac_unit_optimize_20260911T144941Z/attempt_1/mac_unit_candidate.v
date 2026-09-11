// Single-clock 4-lane multiply-accumulate unit with optimized carry-save adder tree.
//
// The critical path runs from the input registers, through an 8x8 multiply,
// through a carry-save reduction network and final carry-propagate adder,
// and into the accumulator. The carry-save stage reduces gate count and power
// compared to three sequential ripple-carry adds.
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

    // Carry-save reduction: 4:2 compressor using two cascaded 3:2 compressors
    // First stage: compress prod0, prod1, prod2 into sum_partial and carry_partial
    // Second stage: compress sum_partial, carry_partial, prod3 into sum_vec and carry_vec
    
    wire [17:0] sum_partial, carry_partial;
    wire [17:0] sum_vec, carry_vec;

    // First 3:2 compressor: prod0, prod1, prod2 → sum_partial, carry_partial
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : cs_stage1
            wire s, c;
            // Full adder: sum = a XOR b XOR cin, cout = (a AND b) OR (cin AND (a XOR b))
            assign s = prod0[i] ^ prod1[i] ^ prod2[i];
            assign c = (prod0[i] & prod1[i]) | (prod2[i] & (prod0[i] ^ prod1[i]));
            assign sum_partial[i] = s;
            assign carry_partial[i+1] = c;
        end
    endgenerate
    assign carry_partial[0] = 1'b0;
    assign sum_partial[17:16] = 2'b0;

    // Second 3:2 compressor: sum_partial, carry_partial, prod3 → sum_vec, carry_vec
    generate
        for (i = 0; i < 16; i = i + 1) begin : cs_stage2
            wire s, c;
            assign s = sum_partial[i] ^ carry_partial[i] ^ prod3[i];
            assign c = (sum_partial[i] & carry_partial[i]) | (prod3[i] & (sum_partial[i] ^ carry_partial[i]));
            assign sum_vec[i] = s;
            assign carry_vec[i+1] = c;
        end
    endgenerate
    assign carry_vec[0] = 1'b0;
    assign sum_vec[17:16] = sum_partial[17:16];

    // Final 18-bit carry-propagate adder
    wire [17:0] sum = sum_vec + carry_vec;

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