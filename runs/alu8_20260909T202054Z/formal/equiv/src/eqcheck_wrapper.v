module __eqcheck_top (
    input wire clk,
    input wire rst,
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [2:0] opcode
);

    wire [7:0] gold_result;
    wire [7:0] gate_result;
    wire gold_zero;
    wire gate_zero;
    wire gold_carry;
    wire gate_carry;

    gold gold_inst (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .opcode(opcode),
        .result(gold_result),
        .zero(gold_zero),
        .carry(gold_carry)
    );

    gate gate_inst (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .opcode(opcode),
        .result(gate_result),
        .zero(gate_zero),
        .carry(gate_carry)
    );

    // First cycle: force a real reset via $initstate before comparing,
    // so the proof isn't defeated by unconstrained initial register state.
    always @(posedge clk) begin
        if ($initstate) begin
            assume (rst);
        end else begin
            assert (gold_result == gate_result && gold_zero == gate_zero && gold_carry == gate_carry);
        end
    end

endmodule