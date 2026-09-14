// designs/bm_fsm_ctrl.v — packet framing controller.
//
// A 16-state protocol FSM, deliberately ONE-HOT encoded, driving a datapath whose
// update is decoded per state. Two things make this a target rather than filler:
//
//   * One-hot costs 16 flip-flops to encode 16 states that 4 bits would hold. Binary
//     re-encoding with an output decode is a real area/power/frequency win -- the
//     optimizer already found exactly this on traffic_light (area -20.3%, FFs -33.3%,
//     power -32.8%, frequency +23.1%, attempt 1).
//   * The per-state datapath decode is an unbalanced chain of conditional adds, so
//     there is a genuine critical path to restructure as well.
//
// No multipliers anywhere, so formal equivalence is cheap -- unlike the arithmetic
// payloads, where wide multiply logic is what defeats the solver.

`default_nettype wire

// This module owns the critical path of the full design (clock 'clk_e', worst slack -1.3 ns).
module bm_fsm_ctrl #(
    parameter integer DW   = 16,
    parameter integer ACCW = 24
) (
    input  wire            clk,
    input  wire            rst,
    input  wire            in_valid,
    input  wire [DW-1:0]   in_data,
    input  wire [3:0]      cmd,
    output reg             out_valid,
    output reg  [ACCW-1:0] out_data,
    output reg  [3:0]      status
);

    // ---------------- one-hot state encoding ----------------
    localparam [15:0] S_IDLE    = 16'b0000_0000_0000_0001;
    localparam [15:0] S_SYNC1   = 16'b0000_0000_0000_0010;
    localparam [15:0] S_SYNC2   = 16'b0000_0000_0000_0100;
    localparam [15:0] S_HDR0    = 16'b0000_0000_0000_1000;
    localparam [15:0] S_HDR1    = 16'b0000_0000_0001_0000;
    localparam [15:0] S_HDR2    = 16'b0000_0000_0010_0000;
    localparam [15:0] S_HDR3    = 16'b0000_0000_0100_0000;
    localparam [15:0] S_LEN     = 16'b0000_0000_1000_0000;
    localparam [15:0] S_PAYLOAD = 16'b0000_0001_0000_0000;
    localparam [15:0] S_ESCAPE  = 16'b0000_0010_0000_0000;
    localparam [15:0] S_CHK0    = 16'b0000_0100_0000_0000;
    localparam [15:0] S_CHK1    = 16'b0000_1000_0000_0000;
    localparam [15:0] S_FLUSH   = 16'b0001_0000_0000_0000;
    localparam [15:0] S_WAIT    = 16'b0010_0000_0000_0000;
    localparam [15:0] S_ERROR   = 16'b0100_0000_0000_0000;
    localparam [15:0] S_DONE    = 16'b1000_0000_0000_0000;

    localparam [DW-1:0] SYNC_A = 16'h55AA;
    localparam [DW-1:0] SYNC_B = 16'hA55A;
    localparam [DW-1:0] ESC_CH = 16'h7D7D;

    reg [15:0]    state;
    reg [ACCW-1:0] acc;
    reg [DW-1:0]  hold;
    reg [7:0]     count;
    reg [DW-1:0]  length;

    // Pipeline stage 1 registers (midpoint split)
    reg [ACCW-1:0] d4_r;
    reg [ACCW-1:0] held_r;
    reg [ACCW-1:0] lenx_r;
    reg [ACCW-1:0] cntx_r;
    reg [ACCW-1:0] ext_r;
    reg             state5_delayed;
    reg             state8_delayed;
    reg             state9_delayed;
    reg             state10_delayed;
    reg             state11_delayed;
    reg             in_valid_r;
    reg             state12_r;

    // Pipeline stage 2 registers (delayed state/control for output assignments)
    reg             state12_r2;

    // ---------------- next state ----------------
    reg [15:0] next;

    always @* begin
        next = state;
        case (1'b1)                       // one-hot case
            state[0]:  next = (in_valid && in_data == SYNC_A) ? S_SYNC1 : S_IDLE;
            state[1]:  next = !in_valid ? S_SYNC1
                            : (in_data == SYNC_B) ? S_SYNC2 : S_IDLE;
            state[2]:  next = in_valid ? S_HDR0 : S_SYNC2;
            state[3]:  next = in_valid ? S_HDR1 : S_HDR0;
            state[4]:  next = in_valid ? S_HDR2 : S_HDR1;
            state[5]:  next = in_valid ? S_HDR3 : S_HDR2;
            state[6]:  next = in_valid ? S_LEN  : S_HDR3;
            state[7]:  next = !in_valid ? S_LEN
                            : (in_data == 16'd0) ? S_ERROR : S_PAYLOAD;
            state[8]:  next = !in_valid ? S_PAYLOAD
                            : (in_data == ESC_CH) ? S_ESCAPE
                            : (count + 8'd1 >= length[7:0]) ? S_CHK0 : S_PAYLOAD;
            state[9]:  next = in_valid ? S_PAYLOAD : S_ESCAPE;
            state[10]: next = in_valid ? S_CHK1 : S_CHK0;
            state[11]: next = !in_valid ? S_CHK1
                            : (in_data == acc[DW-1:0]) ? S_FLUSH : S_ERROR;
            state[12]: next = S_WAIT;
            state[13]: next = (cmd == 4'hF) ? S_DONE : S_WAIT;
            state[14]: next = (cmd == 4'h0) ? S_IDLE : S_ERROR;
            state[15]: next = S_IDLE;
            default:   next = S_IDLE;
        endcase
    end

    // ---------------- per-state datapath decode - STAGE 1 (combinational) ----------------
    // First half: d0 through d4
    wire [ACCW-1:0] ext   = {{(ACCW-DW){1'b0}}, in_data};
    wire [ACCW-1:0] held  = {{(ACCW-DW){1'b0}}, hold};
    wire [ACCW-1:0] lenx  = {{(ACCW-DW){1'b0}}, length};
    wire [ACCW-1:0] cntx  = {{(ACCW-8){1'b0}}, count};

    wire [ACCW-1:0] d0 = acc ^ ext;
    wire [ACCW-1:0] d1 = state[3] ? (d0 + ext)            : d0;
    wire [ACCW-1:0] d2 = state[4] ? (d1 + {ext[ACCW-2:0], 1'b0}) : d1;
    wire [ACCW-1:0] d3 = state[5] ? (d2 + held)           : d2;
    wire [ACCW-1:0] d4 = state[6] ? (d3 + lenx)           : d3;

    // ---------------- per-state datapath decode - STAGE 2 (combinational after pipeline) ----------------
    // Second half: d5 through d9, using pipelined operands and delayed state bits
    wire [ACCW-1:0] d5 = state5_delayed ? (d4_r + lenx_r)           : d4_r;
    wire [ACCW-1:0] d6 = state8_delayed ? (d5 + ext_r + cntx_r)     : d5;
    wire [ACCW-1:0] d7 = state9_delayed ? (d6 ^ {ext_r[ACCW-9:0], 8'h7D}) : d6;
    wire [ACCW-1:0] d8 = state10_delayed ? (d7 + held_r + lenx_r)   : d7;
    wire [ACCW-1:0] d9 = state11_delayed ? (d8 ^ acc)               : d8;

    // ---------------- sequential ----------------
    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            acc       <= {ACCW{1'b0}};
            hold      <= {DW{1'b0}};
            count     <= 8'd0;
            length    <= {DW{1'b0}};
            out_data  <= {ACCW{1'b0}};
            out_valid <= 1'b0;
            status    <= 4'd0;

            d4_r      <= {ACCW{1'b0}};
            held_r    <= {ACCW{1'b0}};
            lenx_r    <= {ACCW{1'b0}};
            cntx_r    <= {ACCW{1'b0}};
            ext_r     <= {ACCW{1'b0}};
            state5_delayed <= 1'b0;
            state8_delayed <= 1'b0;
            state9_delayed <= 1'b0;
            state10_delayed <= 1'b0;
            state11_delayed <= 1'b0;
            in_valid_r <= 1'b0;
            state12_r <= 1'b0;
            state12_r2 <= 1'b0;
        end else begin
            state <= next;

            if (in_valid)
                hold <= in_data;

            if (state[7] && in_valid)
                length <= in_data;

            if (state[8] && in_valid)
                count <= count + 8'd1;
            else if (state[0] || state[15])
                count <= 8'd0;

            // Pipeline stage 1: capture d4 and operands for stage 2
            d4_r <= d4;
            held_r <= held;
            lenx_r <= lenx;
            cntx_r <= cntx;
            ext_r <= ext;
            state5_delayed <= state[5];
            state8_delayed <= state[8];
            state9_delayed <= state[9];
            state10_delayed <= state[10];
            state11_delayed <= state[11];
            in_valid_r <= in_valid;
            state12_r <= state[12];

            // Pipeline stage 2: delayed state for output assignment
            state12_r2 <= state12_r;

            // Update accumulator from second-stage result (pipelined)
            if (in_valid_r)
                acc <= d9;
            else if (state12_r)
                acc <= {ACCW{1'b0}};

            // Output assignments: one cycle delayed due to pipeline
            out_valid <= state12_r2;
            if (state12_r2)
                out_data <= acc;

            status <= {state[14], state[15], state[8], state[0]};
        end
    end

endmodule