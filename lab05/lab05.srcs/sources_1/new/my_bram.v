`timescale 1ns / 1ps

module my_bram # (
    parameter integer BRAM_ADDR_WIDTH = 15, // 4x8192
    parameter INIT_FILE = "input.txt",
    parameter  OUT_FILE = "output.txt"
)(
    input wire [BRAM_ADDR_WIDTH - 1 : 0] BRAM_ADDR,
    input wire BRAM_CLK,
    input wire [31 : 0] BRAM_WRDATA,
    output reg [31 : 0] BRAM_RDDATA,
    input wire BRAM_EN,
    input wire BRAM_RST,
    input wire [3 : 0] BRAM_WE,
    input wire done
);
    reg [31 : 0] mem [0 : 8191];
    wire [BRAM_ADDR_WIDTH - 3 : 0] addr = BRAM_ADDR[BRAM_ADDR_WIDTH - 1 : 2];
    reg [31 : 0] dout;
    
    // code for reading & writing
    initial begin
        if (INIT_FILE != "")
            // read data from INIT_FILE and store them into mem
            $readmemh(INIT_FILE, mem);
        wait (done)
            // write data stored in mem into OUT_FILE
            $writememh(OUT_FILE, mem);
    end
    
    // code for BRAM implementation
    always @(posedge BRAM_CLK) begin
        BRAM_RDDATA <= BRAM_RST ? 32'b0 : dout;
        if (BRAM_EN && BRAM_WE == 4'b0000)
            dout <= mem[addr];
    end
    
    // write part
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1)
        always @(posedge BRAM_CLK)
            if (BRAM_EN && BRAM_WE[i])
                mem[addr][8 * (i + 1) - 1 : 8 * i] <= BRAM_WRDATA[8 * (i + 1) - 1 : 8 * i];
    endgenerate
    
endmodule
