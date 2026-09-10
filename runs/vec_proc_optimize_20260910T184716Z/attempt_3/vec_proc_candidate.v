// Single-clock 8-lane vector processing unit.
//
// Optimized FSM: collapsed from 12 states to 4 states by removing
// delay-only states that provided no functional purpose.

module vec_proc (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [2:0]   op,
    input  wire [127:0] a_vec,
    input  wire [127:0] b_vec,
    output reg  [127:0] result_vec,
    output reg          done
);

    localparam [2:0] OP_ADD = 3'd0,
                     OP_SUB = 3'd1,
                     OP_MIN = 3'd2,
                     OP_MAX = 3'd3,
                     OP_SHL = 3'd4,
                     OP_SHR = 3'd5,
                     OP_AND = 3'd6,
                     OP_XOR = 3'd7;

    localparam [1:0] S_IDLE  = 2'b00,
                     S_LOAD  = 2'b01,
                     S_CALC  = 2'b10,
                     S_DONE  = 2'b11;

    reg [1:0]   state;
    reg [127:0] a_reg, b_reg;
    reg [2:0]   op_reg;
    wire [127:0] lane_result;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : lanes
            wire [15:0] a_i = a_reg[i*16 +: 16];
            wire [15:0] b_i = b_reg[i*16 +: 16];
            reg  [15:0] r_i;

            always @(*) begin
                case (op_reg)
                    OP_ADD:  r_i = a_i + b_i;
                    OP_SUB:  r_i = a_i - b_i;
                    OP_MIN:  r_i = (a_i < b_i) ? a_i : b_i;
                    OP_MAX:  r_i = (a_i > b_i) ? a_i : b_i;
                    OP_SHL:  r_i = a_i << b_i[3:0];
                    OP_SHR:  r_i = a_i >> b_i[3:0];
                    OP_AND:  r_i = a_i & b_i;
                    OP_XOR:  r_i = a_i ^ b_i;
                    default: r_i = 16'd0;
                endcase
            end

            assign lane_result[i*16 +: 16] = r_i;
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            state      <= S_IDLE;
            a_reg      <= 128'd0;
            b_reg      <= 128'd0;
            op_reg     <= 3'd0;
            result_vec <= 128'd0;
            done       <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        a_reg  <= a_vec;
                        b_reg  <= b_vec;
                        op_reg <= op;
                        state  <= S_CALC;
                    end
                end
                S_CALC: begin
                    result_vec <= lane_result;
                    state      <= S_DONE;
                end
                S_DONE: begin
                    done  <= 1'b1;
                    state <= S_IDLE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule