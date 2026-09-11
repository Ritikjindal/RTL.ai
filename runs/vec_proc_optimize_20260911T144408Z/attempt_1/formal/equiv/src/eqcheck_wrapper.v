module __eqcheck_top (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [2:0] op,
    input wire [127:0] a_vec,
    input wire [127:0] b_vec
);

    wire [127:0] gold_result_vec;
    wire [127:0] gate_result_vec;
    wire gold_done;
    wire gate_done;

    gold gold_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .op(op),
        .a_vec(a_vec),
        .b_vec(b_vec),
        .result_vec(gold_result_vec),
        .done(gold_done)
    );

    gate gate_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .op(op),
        .a_vec(a_vec),
        .b_vec(b_vec),
        .result_vec(gate_result_vec),
        .done(gate_done)
    );

    // First cycle: force a real reset via $initstate before comparing,
    // so the proof isn't defeated by unconstrained initial register state.
    always @(posedge clk) begin
        if ($initstate) begin
            assume (rst);
        end else begin
            assert (gold_result_vec == gate_result_vec && gold_done == gate_done);
        end
    end

endmodule