`timescale 1ns / 1ps

//BRAM as ROM

module BRAM(
    input  wire [10:0] addr,   // 0 to 1499
    output wire data_out
);
    reg rom [0:1499];

    // Load contents from memory file
    initial begin
        $readmemb("nav_bits.mem", rom);
    end

    assign data_out = rom[addr];

endmodule
