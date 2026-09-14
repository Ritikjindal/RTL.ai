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

    // Pipeline stage registers (stage 1->2 split)
    reg [ACCW-1:0] d4_r;
    reg [ACCW-1:0] held_r;
    reg [ACCW-1:0] lenx_r;
    reg [ACCW-1:0] cntx_r;
    reg [ACCW-1:0] ext_r;
    reg             state8_r;
    reg             state9_r;
    reg             state10_r;
    reg             state11_r;
    reg             in_valid_r;

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

    // ---------------- per-state datapath decode - FIRST STAGE ----------------
    wire [ACCW-1:0] ext   = {{(ACCW-DW){1'b0}}, in_data};
    wire [ACCW-1:0] held  = {{(ACCW-DW){1'b0}}, hold};
    wire [ACCW-1:0] lenx  = {{(ACCW-DW){1'b0}}, length};
    wire [ACCW-1:0] cntx  = {{(ACCW-8){1'b0}}, count};

    wire [ACCW-1:0] d0 = acc ^ ext;
    wire [ACCW-1:0] d1 = state[3] ? (d0 + ext)            : d0;
    wire [ACCW-1:0] d2 = state[4] ? (d1 + {ext[ACCW-2:0], 1'b0}) : d1;
    wire [ACCW-1:0] d3 = state[5] ? (d2 + held)           : d2;
    wire [ACCW-1:0] d4 = state[6] ? (d3 + lenx)           : d3;

    // ---------------- per-state datapath decode - SECOND STAGE ----------------
    // Built from pipelined operands and delayed state bits
    wire [ACCW-1:0] d5 = state5_r ? (d4_r + lenx_r)           : d4_r;
    wire [ACCW-1:0] d6 = state8_r ? (d5 + ext_r + cntx_r)     : d5;
    wire [ACCW-1:0] d7 = state9_r ? (d6 ^ {ext_r[ACCW-9:0], 8'h7D}) : d6;
    wire [ACCW-1:0] d8 = state10_r ? (d7 + held_r + lenx_r)   : d7;
    wire [ACCW-1:0] d9 = state11_r ? (d8 ^ acc)           : d8;

    // Delayed state5 for second stage
    reg state5_r;

    // Delayed state12 for output control
    reg state12_r;
    reg state12_r2;

    // Delayed state[14] and state[15] for output control
    reg state14_r;
    reg state15_r;

    // Delayed state[0] for output control
    reg state0_r;

    // Delayed count and length
    reg [7:0] count_r;
    reg [DW-1:0] length_r;
    reg [DW-1:0] hold_r;

    // Delayed acc for second-stage operations
    reg [ACCW-1:0] acc_r;

    // Delayed in_valid for second stage
    reg in_valid_r_stage2;

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

            // Pipeline stage resets
            d4_r <= {ACCW{1'b0}};
            held_r <= {ACCW{1'b0}};
            lenx_r <= {ACCW{1'b0}};
            cntx_r <= {ACCW{1'b0}};
            ext_r <= {ACCW{1'b0}};
            state5_r <= 1'b0;
            state8_r <= 1'b0;
            state9_r <= 1'b0;
            state10_r <= 1'b0;
            state11_r <= 1'b0;
            in_valid_r <= 1'b0;
            state12_r <= 1'b0;
            state12_r2 <= 1'b0;
            state14_r <= 1'b0;
            state15_r <= 1'b0;
            state0_r <= 1'b0;
            count_r <= 8'd0;
            length_r <= {DW{1'b0}};
            hold_r <= {DW{1'b0}};
            acc_r <= {ACCW{1'b0}};
            in_valid_r_stage2 <= 1'b0;
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

            if (in_valid)
                acc <= d9;
            else if (state[12])
                acc <= {ACCW{1'b0}};

            // ===== PIPELINE STAGE 1 -> 2 BOUNDARY =====
            // Capture d4 and all operands needed by the second half
            d4_r <= d4;
            held_r <= held;
            lenx_r <= lenx;
            cntx_r <= cntx;
            ext_r <= ext;
            state5_r <= state[5];
            state8_r <= state[8];
            state9_r <= state[9];
            state10_r <= state[10];
            state11_r <= state[11];
            in_valid_r <= in_valid;
            state12_r <= state[12];
            state14_r <= state[14];
            state15_r <= state[15];
            state0_r <= state[0];
            count_r <= count;
            length_r <= length;
            hold_r <= hold;
            acc_r <= acc;

            // Second cycle: delayed output control
            state12_r2 <= state12_r;
            in_valid_r_stage2 <= in_valid_r;

            // Output signals now gated by delayed pipeline
            out_valid <= state12_r2;
            if (state12_r2)
                out_data <= acc_r;

            status <= {state14_r, state15_r, state8_r, state0_r};
        end
    end

endmodule