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

    // Latency offset of 1 cycle(s): the candidate produces its
    // outputs later than the baseline (added pipeline stages), so the baseline's
    // outputs are delayed by that many cycles before being compared.
    reg [23:0] gold_acc_d1;
    reg gold_acc_valid_d1;

    always @(posedge clk) begin
        gold_acc_d1 <= gold_acc;
        gold_acc_valid_d1 <= gold_acc_valid;
    end

    // Comparison is suppressed until the delay pipeline has filled.
    reg [7:0] warmup = 8'd0;
    always @(posedge clk) begin
        if (rst) warmup <= 8'd0;
        else if (warmup < 8'd1) warmup <= warmup + 8'd1;
    end

    // First cycle: force a real reset via $initstate before comparing,
    // so the proof isn't defeated by unconstrained initial register state.
    always @(posedge clk) begin
        if ($initstate) begin
            assume (rst);
        end else begin
            if (warmup >= 8'd1) assert (gold_acc_d1 == gate_acc && gold_acc_valid_d1 == gate_acc_valid);
        end
    end

endmodule