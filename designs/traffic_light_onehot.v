module traffic_light (
    input  wire clk,
    input  wire rst,
    output wire red,
    output wire green,
    output wire yellow
);

    // One-hot encoding: one flip-flop per state, only one ever set.
    localparam [2:0] S_RED    = 3'b001;
    localparam [2:0] S_GREEN  = 3'b010;
    localparam [2:0] S_YELLOW = 3'b100;

    reg [2:0] state;

    always @(posedge clk) begin
        if (rst)
            state <= S_RED;
        else begin
            case (state)
                S_RED:    state <= S_GREEN;
                S_GREEN:  state <= S_YELLOW;
                S_YELLOW: state <= S_RED;
                default:  state <= S_RED;
            endcase
        end
    end

    assign red    = state[0];
    assign green  = state[1];
    assign yellow = state[2];

endmodule