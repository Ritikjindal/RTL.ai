module __eqcheck_top (
    input wire clk,
    input wire rst,
    input wire in_valid,
    input wire [15:0] in_data,
    input wire [3:0] cmd
);

    wire gold_out_valid;
    wire gate_out_valid;
    wire [23:0] gold_out_data;
    wire [23:0] gate_out_data;
    wire [3:0] gold_status;
    wire [3:0] gate_status;

    gold gold_inst (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_data(in_data),
        .cmd(cmd),
        .out_valid(gold_out_valid),
        .out_data(gold_out_data),
        .status(gold_status)
    );

    gate gate_inst (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_data(in_data),
        .cmd(cmd),
        .out_valid(gate_out_valid),
        .out_data(gate_out_data),
        .status(gate_status)
    );

    // First cycle: force a real reset via $initstate before comparing,
    // so the proof isn't defeated by unconstrained initial register state.
    always @(posedge clk) begin
        if ($initstate) begin
            assume (rst);
        end else begin
            assert (gold_out_valid == gate_out_valid && gold_out_data == gate_out_data && gold_status == gate_status);
        end
    end

endmodule