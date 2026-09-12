// Reset synchronizer: asynchronous assert, synchronous de-assert.
// One per clock domain. Without this, the de-assertion edge of a shared reset
// is asynchronous to each domain's clock and can put flops into metastability.
module reset_sync (
    input  wire clk,
    input  wire rst_async,   // active high, asynchronous
    output wire rst_sync     // active high, de-asserts synchronously to clk
);

    reg meta, stable;

    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            meta   <= 1'b1;
            stable <= 1'b1;
        end else begin
            meta   <= 1'b0;
            stable <= meta;
        end
    end

    assign rst_sync = stable;

endmodule