`timescale 1ns / 1ps

module tb_pe_controller();
    parameter integer DATA_WIDTH = 32; // size of data (int8, fp32, etc)
    parameter integer BRAM_ADDR_WIDTH = 15; // BRAM_SIZE == 2 ** BRAM_ADDR_WIDTH
    parameter integer BRAM_DATA_WIDTH = 32; // read BRAM_DATA_WIDTH bits per cycle
    parameter integer GBUF_SIZE = 16; // 2 GBUFs
    parameter integer DONE_STATE_CYCLE = 5; // wait some cycles
    parameter integer MEMORY_WIDTH = 5;
    
    // start
    reg start;
    // reset/clk
    reg reset;
    reg clk;
    // read
    wire [BRAM_ADDR_WIDTH - 1 : 0] rdaddr;
    
    // global buffer
    reg [DATA_WIDTH - 1 : 0] memory [0 : 2 * GBUF_SIZE - 1];
    wire [DATA_WIDTH - 1 : 0] rddata = memory[rdaddr[MEMORY_WIDTH - 1 : 0]];
    
    // output
    wire [DATA_WIDTH - 1 : 0] out;
    wire done;
    
    integer i;
    
    initial begin
        start = 0;
        reset = 0;
        clk = 1;
        for (i = 0; i < 2 * GBUF_SIZE; i = i + 1) begin
            memory[i][31 : 25] = 7'b0100000;
            memory[i][24 :  0] = $urandom%(2 ** 25);
        end
        #1;
        
        reset = 1;
        #10; // reset on
        
        reset = 0;
        #10; // reset off and wait one more cycle
        
        start = 1;
        #10; // start on
        
        start = 0; // start off
    end
    
    pe_controller # (
        .DATA_WIDTH(DATA_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .GBUF_SIZE(GBUF_SIZE),
        .DONE_STATE_CYCLE(DONE_STATE_CYCLE),
        .CNT_WIDTH(MEMORY_WIDTH - 1)
    ) PE_CONTROLLER (
        .start(start),
        .reset(reset),
        .clk(clk),
        .rdaddr(rdaddr),
        .rddata(rddata),
        .out(out),
        .done(done)
    );
    
    always #5 clk = ~clk;
    
endmodule
