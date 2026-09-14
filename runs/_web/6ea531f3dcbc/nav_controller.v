module nav_controller
(
    input  wire clk,
    input  wire rst,

    // Pulse from PRN generator every 1023 chips
    input  wire prn_epoch,

    // Address sent to navigation ROM
    output reg [10:0] nav_addr
);

    reg [4:0] repeat_count;

    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            repeat_count <= 5'd0;
            nav_addr     <= 11'd0;
        end
        else if (prn_epoch)
        begin

            // 20 repetitions completed
            if (repeat_count == 5'd19)
            begin
                repeat_count <= 5'd0;

                // End of 1500-bit frame
                if (nav_addr == 11'd1499)
                    nav_addr <= 11'd0;
                else
                    nav_addr <= nav_addr + 11'd1;
            end
            else
            begin
                repeat_count <= repeat_count + 5'd1;
            end

        end
    end

endmodule