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
    reg        valid_reg2;

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

    // Pipeline registers for products
    reg [15:0] prod0_r, prod1_r, prod2_r, prod3_r;

    always @(posedge clk) begin
        if (rst) begin
            prod0_r   <= 16'd0;
            prod1_r   <= 16'd0;
            prod2_r   <= 16'd0;
            prod3_r   <= 16'd0;
            valid_reg2 <= 1'b0;
        end else begin
            prod0_r   <= prod0;
            prod1_r   <= prod1;
            prod2_r   <= prod2;
            prod3_r   <= prod3;
            valid_reg2 <= valid_reg;
        end
    end

    // Adder tree using registered products
    wire [16:0] sum01 = prod0_r + prod1_r;
    wire [16:0] sum23 = prod2_r + prod3_r;
    wire [17:0] sum   = sum01 + sum23;

    always @(posedge clk) begin
        if (rst) begin
            acc       <= 24'd0;
            acc_valid <= 1'b0;
        end else if (valid_reg2) begin
            acc       <= acc + {6'd0, sum};
            acc_valid <= 1'b1;
        end else begin
            acc_valid <= 1'b0;
        end
    end

endmodule