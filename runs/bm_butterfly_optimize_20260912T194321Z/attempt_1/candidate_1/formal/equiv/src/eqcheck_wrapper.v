module __eqcheck_top (
    input wire clk,
    input wire rst,
    input wire in_valid,
    input wire [9:0] ar,
    input wire [9:0] ai,
    input wire [9:0] br,
    input wire [9:0] bi
);

    wire gold_out_valid;
    wire gate_out_valid;
    wire [23:0] gold_cr;
    wire [23:0] gate_cr;
    wire [23:0] gold_ci;
    wire [23:0] gate_ci;

    gold gold_inst (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .ar(ar),
        .ai(ai),
        .br(br),
        .bi(bi),
        .out_valid(gold_out_valid),
        .cr(gold_cr),
        .ci(gold_ci)
    );

    gate gate_inst (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .ar(ar),
        .ai(ai),
        .br(br),
        .bi(bi),
        .out_valid(gate_out_valid),
        .cr(gate_cr),
        .ci(gate_ci)
    );

    // Latency offset of 1 cycle(s): the candidate produces its
    // outputs later than the baseline (added pipeline stages), so the baseline's
    // outputs are delayed by that many cycles before being compared.
    reg gold_out_valid_d1;
    reg [23:0] gold_cr_d1;
    reg [23:0] gold_ci_d1;

    always @(posedge clk) begin
        gold_out_valid_d1 <= gold_out_valid;
        gold_cr_d1 <= gold_cr;
        gold_ci_d1 <= gold_ci;
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
            if (warmup >= 8'd1) assert (gold_out_valid_d1 == gate_out_valid && gold_cr_d1 == gate_cr && gold_ci_d1 == gate_ci);
        end
    end

endmodule