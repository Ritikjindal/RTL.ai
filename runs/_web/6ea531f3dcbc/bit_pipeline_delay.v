`timescale 1ns/1ps

// Delays a one-bit sideband signal by a fixed number of registered stages.
// STAGES must be at least 1.  A value sampled at an active clock edge appears
// at dout immediately after the STAGES-th register edge, matching an equally
// deep registered datapath.
module bit_pipeline_delay #(
    parameter integer STAGES = 1
) (
    input  wire clk,
    input  wire rst,
    input  wire din,
    output wire dout
);
    reg [STAGES-1:0] pipe;
    integer i;

    initial begin
        if (STAGES < 1) begin
            $display("bit_pipeline_delay: STAGES must be >= 1");
            $finish;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            pipe <= {STAGES{1'b0}};
        end else begin
            pipe[0] <= din;
            for (i = 1; i < STAGES; i = i + 1)
                pipe[i] <= pipe[i-1];
        end
    end

    assign dout = pipe[STAGES-1];
endmodule
