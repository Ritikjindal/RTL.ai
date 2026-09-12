module __eqcheck_top (
    input wire clk,
    input wire reset_n,
    input wire cs,
    input wire we,
    input wire [7:0] address,
    input wire [31:0] write_data
);

    wire [31:0] gold_read_data;
    wire [31:0] gate_read_data;
    wire gold_error;
    wire gate_error;

    gold gold_inst (
        .clk(clk),
        .reset_n(reset_n),
        .cs(cs),
        .we(we),
        .address(address),
        .write_data(write_data),
        .read_data(gold_read_data),
        .error(gold_error)
    );

    gate gate_inst (
        .clk(clk),
        .reset_n(reset_n),
        .cs(cs),
        .we(we),
        .address(address),
        .write_data(write_data),
        .read_data(gate_read_data),
        .error(gate_error)
    );

    // First cycle: force a real reset via $initstate before comparing,
    // so the proof isn't defeated by unconstrained initial register state.
    always @(posedge clk) begin
        if ($initstate) begin
            assume (!reset_n);
        end else begin
            assert (gold_read_data == gate_read_data && gold_error == gate_error);
        end
    end

endmodule