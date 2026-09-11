module __eqcheck_top (
    input wire clk,
    input wire rst,
    input wire valid,
    input wire [31:0] a_vec,
    input wire [31:0] b_vec
);

    wire [23:0] gold_acc;
    wire [23:0] gate_acc;
    wire gold_acc_valid;
    wire gate_acc_valid;

    gold gold_inst (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .a_vec(a_vec),
        .b_vec(b_vec),
        .acc(gold_acc),
        .acc_valid(gold_acc_valid)
    );

    gate gate_inst (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .a_vec(a_vec),
        .b_vec(b_vec),
        .acc(gate_acc),
        .acc_valid(gate_acc_valid)
    );

    // First cycle: force a real reset via $initstate before comparing,
    // so the proof isn't defeated by unconstrained initial register state.
    always @(posedge clk) begin
        if ($initstate) begin
            assume (rst);
        end else begin
            assert (gold_acc == gate_acc && gold_acc_valid == gate_acc_valid);
        end
    end

endmodule