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

    reg [7:0] result_next;
    reg       carry_next;

    always @(*) begin
        case (opcode)
            OP_ADD:  {carry_next, result_next} = a + b;   // lets the synthesis tool pick the adder
            OP_SUB:  {carry_next, result_next} = a - b;
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