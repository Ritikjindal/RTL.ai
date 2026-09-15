module CA_gen
(
    input  wire       clk,
    input  wire       rst,
    input  wire [5:0] prn_id,

    output wire       ca_chip,
    output reg        prn_epoch
);

    //--------------------------------------------------
    // G1 / G2 Registers
    //--------------------------------------------------

    reg [10:1] g1;
    reg [10:1] g2;

    //--------------------------------------------------
    // Chip Counter
    //--------------------------------------------------

    reg [9:0] chip_count;

    //--------------------------------------------------
    // Feedback Logic
    //--------------------------------------------------

    wire g1_fbk;
    wire g2_fbk;

    assign g1_fbk = g1[3] ^ g1[10];

    assign g2_fbk =
        g2[2]  ^
        g2[3]  ^
        g2[6]  ^
        g2[8]  ^
        g2[9]  ^
        g2[10];

    //--------------------------------------------------
    // PRN Tap Selection
    //--------------------------------------------------

    reg g2_out;

    always @(*)
    begin
        case(prn_id)

            6'd1  : g2_out = g2[2] ^ g2[6];
            6'd2  : g2_out = g2[3] ^ g2[7];
            6'd3  : g2_out = g2[4] ^ g2[8];
            6'd4  : g2_out = g2[5] ^ g2[9];
            6'd5  : g2_out = g2[1] ^ g2[9];
            6'd6  : g2_out = g2[2] ^ g2[10];
            6'd7  : g2_out = g2[1] ^ g2[8];
            6'd8  : g2_out = g2[2] ^ g2[9];
            6'd9  : g2_out = g2[3] ^ g2[10];
            6'd10 : g2_out = g2[2] ^ g2[3];

            6'd11 : g2_out = g2[3] ^ g2[4];
            6'd12 : g2_out = g2[5] ^ g2[6];
            6'd13 : g2_out = g2[6] ^ g2[7];
            6'd14 : g2_out = g2[7] ^ g2[8];
            6'd15 : g2_out = g2[8] ^ g2[9];
            6'd16 : g2_out = g2[9] ^ g2[10];
            6'd17 : g2_out = g2[1] ^ g2[4];
            6'd18 : g2_out = g2[2] ^ g2[5];
            6'd19 : g2_out = g2[3] ^ g2[6];
            6'd20 : g2_out = g2[4] ^ g2[7];

            6'd21 : g2_out = g2[5] ^ g2[8];
            6'd22 : g2_out = g2[6] ^ g2[9];
            6'd23 : g2_out = g2[1] ^ g2[3];
            6'd24 : g2_out = g2[4] ^ g2[6];
            6'd25 : g2_out = g2[5] ^ g2[7];
            6'd26 : g2_out = g2[6] ^ g2[8];
            6'd27 : g2_out = g2[7] ^ g2[9];
            6'd28 : g2_out = g2[8] ^ g2[10];
            6'd29 : g2_out = g2[1] ^ g2[6];
            6'd30 : g2_out = g2[2] ^ g2[7];

            6'd31 : g2_out = g2[3] ^ g2[8];
            6'd32 : g2_out = g2[4] ^ g2[9];

            default : g2_out = g2[2] ^ g2[6]; // PRN1 default
        endcase
    end

    //--------------------------------------------------
    // C/A Chip Output
    //--------------------------------------------------

    assign ca_chip = g1[10] ^ g2_out;

    //--------------------------------------------------
    // Main Logic
    //--------------------------------------------------

    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            g1         <= 10'b1111111111;
            g2         <= 10'b1111111111;
            chip_count <= 10'd0;
            prn_epoch  <= 1'b0;
        end
        else
        begin

            //--------------------------------------------------
            // End of 1023-chip C/A period
            //--------------------------------------------------

            if (chip_count == 10'd1022)
            begin
                chip_count <= 10'd0;
                prn_epoch  <= 1'b1;

                // Restart code epoch
                g1 <= 10'b1111111111;
                g2 <= 10'b1111111111;
            end
            else
            begin
                chip_count <= chip_count + 10'd1;
                prn_epoch  <= 1'b0;

                g1 <= {g1_fbk, g1[10:2]};
                g2 <= {g2_fbk, g2[10:2]};
            end

        end
    end

endmodule