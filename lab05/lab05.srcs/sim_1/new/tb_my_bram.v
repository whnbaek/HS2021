`timescale 1ns / 1ps

module tb_my_bram();
    parameter integer BRAM_ADDR_WIDTH = 15;
    
    reg BRAM_CLK;
    reg [BRAM_ADDR_WIDTH - 1 : 0] BRAM_ADDR;
    wire [31 : 0] BRAM_DATA;
    reg [3 : 0] BRAM2_WE;
    reg done;
    
    integer i;

    initial begin
        BRAM_CLK = 1'b1;
        BRAM2_WE = 4'b0000;
        done <= 0;
        #1; // give some delay
        for (i = 0; i < 8192; i = i + 1) begin
            BRAM2_WE = 4'b0000;
            BRAM_ADDR = 4 * i;
            #20;
            BRAM2_WE = 4'b1111;
            #10;
        end
        done = 1'b1;
    end

    my_bram BRAM1 (
        .BRAM_ADDR(BRAM_ADDR),
        .BRAM_CLK(BRAM_CLK),
        .BRAM_WRDATA(32'b0),
        .BRAM_RDDATA(BRAM_DATA),
        .BRAM_EN(1'b1),
        .BRAM_RST(1'b0),
        .BRAM_WE(4'b0000),
        .done(1'b0)
    );
    
    my_bram # (.INIT_FILE("")) BRAM2 (
        .BRAM_ADDR(BRAM_ADDR),
        .BRAM_CLK(BRAM_CLK),
        .BRAM_WRDATA(BRAM_DATA),
        .BRAM_EN(1'b1),
        .BRAM_RST(1'b0),
        .BRAM_WE(BRAM2_WE),
        .done(done)
    );
    
    always #5 BRAM_CLK = ~BRAM_CLK;
    
endmodule
