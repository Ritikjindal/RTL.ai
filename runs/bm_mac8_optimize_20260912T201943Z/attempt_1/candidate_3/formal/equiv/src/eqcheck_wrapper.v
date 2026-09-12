module __eqcheck_top (
    input wire clk,
    input wire rst,
    input wire in_valid,
    input wire [63:0] a_vec,
    input wire [63:0] b_vec
);

    wire gold_out_valid;
    wire gate_out_valid;
    wire [20:0] gold_acc;
    wire [20:0] gate_acc;

    gold gold_inst (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .a_vec(a_vec),
        .b_vec(b_vec),
        .out_valid(gold_out_valid),
        .acc(gold_acc)
    );

    gate gate_inst (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .a_vec(a_vec),
        .b_vec(b_vec),
        .out_valid(gate_out_valid),
        .acc(gate_acc)
    );

    // First cycle: force a real reset via $initstate before comparing,
    // so the proof isn't defeated by unconstrained initial register state.
    always @(posedge clk) begin
        if ($initstate) begin
            assume (rst);
        end else begin
            assert (gold_out_valid == gate_out_valid && gold_acc == gate_acc);
        end
    end

endmodule