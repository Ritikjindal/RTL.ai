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
    
    // Signals for shared adder
    wire [7:0] b_mux;           // Muxed b operand (normal or inverted)
    wire       carry_in;         // Carry in for adder (0 for ADD, 1 for SUB)
    wire [8:0] adder_result;     // 9-bit result from adder (includes carry out)

    // Mux control: opcode[0] distinguishes ADD (0) from SUB (1)
    assign b_mux = (opcode[0] == 1'b1) ? ~b : b;
    assign carry_in = opcode[0];
    
    // Explicit ripple-carry adder
    assign adder_result = a + b_mux + carry_in;

    always @(*) begin
        case (opcode)
            OP_ADD:  begin 
                result_next = adder_result[7:0];
                carry_next = adder_result[8];
            end
            OP_SUB:  begin 
                result_next = adder_result[7:0];
                carry_next = adder_result[8];
            end
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