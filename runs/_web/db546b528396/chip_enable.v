module chip_rate_generator
(
    input  wire clk,

    output reg chip_enable
);

    //--------------------------------------------------
    // 32-bit Phase Accumulator
    //--------------------------------------------------

    reg [31:0] phase_acc = 32'd0;

    // Phase increment for 1.023 MHz from 100 MHz clock
    localparam [31:0] PHASE_INC = 32'd43937515;

    wire [32:0] phase_next;

    assign phase_next = {1'b0, phase_acc} + PHASE_INC;

    //--------------------------------------------------
    // NCO
    //--------------------------------------------------

    always @(posedge clk)
    begin
        phase_acc   <= phase_next[31:0];

        // One-clock pulse on overflow
        chip_enable <= phase_next[32];
    end

endmodule