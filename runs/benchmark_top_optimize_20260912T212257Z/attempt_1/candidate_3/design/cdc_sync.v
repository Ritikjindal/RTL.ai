// Two-flop synchronizer for a single control bit crossing clock domains.
// The standard structure a CDC checker expects to see on a control crossing.
module cdc_sync (
    input  wire clk_dst,
    input  wire rst,
    input  wire sig_src,
    output wire sig_dst
);

    reg meta, stable;

    always @(posedge clk_dst) begin
        if (rst) begin
            meta   <= 1'b0;
            stable <= 1'b0;
        end else begin
            meta   <= sig_src;
            stable <= meta;
        end
    end

    assign sig_dst = stable;

endmodule