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

    // Stage 0: Opcode decode to one-hot signals
    reg [7:0] op_sel;
    
    always @(*) begin
        op_sel = 8'b0;
        case (opcode)
            OP_ADD:  op_sel = 8'b00000001;
            OP_SUB:  op_sel = 8'b00000010;
            OP_AND:  op_sel = 8'b00000100;
            OP_OR:   op_sel = 8'b00001000;
            OP_XOR:  op_sel = 8'b00010000;
            OP_SHL:  op_sel = 8'b00100000;
            OP_SHR:  op_sel = 8'b01000000;
            OP_PASS: op_sel = 8'b10000000;
            default: op_sel = 8'b0;
        endcase
    end

    // Stage 1: Selective operation computation with gated inputs
    
    // ADD/SUB shared adder with gated inputs
    wire [7:0] add_a = (op_sel[0] || op_sel[1]) ? a : 8'b0;
    wire [7:0] add_b = op_sel[0] ? b : (op_sel[1] ? ~b : 8'b0);
    wire [8:0] add_result = add_a + add_b;
    
    // AND operation with gated inputs
    wire [7:0] and_result = (op_sel[2] != 1'b0) ? (a & b) : 8'b0;
    
    // OR operation with gated inputs
    wire [7:0] or_result = (op_sel[3] != 1'b0) ? (a | b) : 8'b0;
    
    // XOR operation with gated inputs
    wire [7:0] xor_result = (op_sel[4] != 1'b0) ? (a ^ b) : 8'b0;
    
    // SHL operation with gated inputs
    wire [7:0] shl_result = (op_sel[5] != 1'b0) ? (a << 1) : 8'b0;
    wire shl_carry = (op_sel[5] != 1'b0) ? a[7] : 1'b0;
    
    // SHR operation with gated inputs
    wire [7:0] shr_result = (op_sel[6] != 1'b0) ? (a >> 1) : 8'b0;
    wire shr_carry = (op_sel[6] != 1'b0) ? a[0] : 1'b0;
    
    // PASS operation with gated inputs
    wire [7:0] pass_result = (op_sel[7] != 1'b0) ? a : 8'b0;
    
    // Combine results and carry outputs
    reg [7:0] result_next;
    reg       carry_next;
    
    always @(*) begin
        result_next = add_result[7:0] | and_result | or_result | xor_result | shl_result | shr_result | pass_result;
        
        if (op_sel[0] || op_sel[1]) begin
            carry_next = add_result[8];
        end else if (op_sel[5]) begin
            carry_next = shl_carry;
        end else if (op_sel[6]) begin
            carry_next = shr_carry;
        end else begin
            carry_next = 1'b0;
        end
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