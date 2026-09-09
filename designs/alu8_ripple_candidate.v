module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule

module alu8 (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [2:0] opcode,
    output reg  [7:0] result,
    output reg        zero,
    output reg        carry
);

    localparam [2:0] OP_ADD  = 3'b000;
    localparam [2:0] OP_SUB  = 3'b001;
    localparam [2:0] OP_AND  = 3'b010;
    localparam [2:0] OP_OR   = 3'b011;
    localparam [2:0] OP_XOR  = 3'b100;
    localparam [2:0] OP_SHL  = 3'b101;
    localparam [2:0] OP_SHR  = 3'b110;
    localparam [2:0] OP_PASS = 3'b111;

    // Hand-rolled ripple-carry adder/subtractor: for SUB, b is inverted
    // and carry-in forced to 1 (the standard two's-complement trick),
    // built explicitly from 8 chained full adders instead of using `+`/`-`.
    wire       sub_mode  = (opcode == OP_SUB);
    wire [7:0] b_operand = b ^ {8{sub_mode}};
    wire [8:0] carry_chain;
    wire [7:0] adder_sum;

    assign carry_chain[0] = sub_mode;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : ripple
            full_adder fa (
                .a    (a[i]),
                .b    (b_operand[i]),
                .cin  (carry_chain[i]),
                .sum  (adder_sum[i]),
                .cout (carry_chain[i+1])
            );
        end
    endgenerate

    wire adder_carry_out = carry_chain[8] ^ sub_mode;  // flip back to borrow-sense for SUB

    reg [7:0] result_next;
    reg       carry_next;

    always @(*) begin
        case (opcode)
            OP_ADD:  begin result_next = adder_sum; carry_next = adder_carry_out; end
            OP_SUB:  begin result_next = adder_sum; carry_next = adder_carry_out; end
            OP_AND:  begin result_next = a & b;  carry_next = 1'b0; end
            OP_OR:   begin result_next = a | b;  carry_next = 1'b0; end
            OP_XOR:  begin result_next = a ^ b;  carry_next = 1'b0; end
            OP_SHL:  begin result_next = a << 1; carry_next = a[7]; end
            OP_SHR:  begin result_next = a >> 1; carry_next = a[0]; end
            OP_PASS: begin result_next = a;      carry_next = 1'b0; end
            default: begin result_next = 8'b0;   carry_next = 1'b0; end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            result <= 8'b0;
            carry  <= 1'b0;
            zero   <= 1'b1;
        end else begin
            result <= result_next;
            carry  <= carry_next;
            zero   <= (result_next == 8'b0);
        end
    end

endmodule