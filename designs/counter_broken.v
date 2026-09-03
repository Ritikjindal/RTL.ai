// designs/counter_broken.v — for testing formal.py only, not a real optimization candidate
module counter (
    input  wire       clk,
    input  wire       rst,
    output reg  [7:0] count
);

always @(posedge clk) begin
    if (rst)
        count <= 8'b1;          // BUG: resets to 1, not 0 — should be caught
    else
        count <= count + 1'b1;
end

endmodule