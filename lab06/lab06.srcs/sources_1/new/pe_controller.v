`timescale 1ns / 1ps

module pe_controller # (
    parameter integer DATA_WIDTH = 32, // size of data (int8, fp32, etc)
    parameter integer BRAM_ADDR_WIDTH = 15, // BRAM_SIZE == 2 ** BRAM_ADDR_WIDTH
    parameter integer BRAM_DATA_WIDTH = 32, // read BRAM_DATA_WIDTH bits per cycle
    parameter integer GBUF_SIZE = 16, // 2 GBUFs
    parameter integer DONE_STATE_CYCLE = 5, // wait some cycles
    parameter integer CNT_WIDTH = 4
)(
    // start
    input start,
    // reset/clk
    input reset,
    input clk,
    // read
    output reg [BRAM_ADDR_WIDTH - 1 : 0] rdaddr,
    input [BRAM_DATA_WIDTH - 1 : 0] rddata,
    // output
    output reg [DATA_WIDTH - 1 : 0] out,
    output reg done
);
    // FSM states
    localparam [2 : 0] IDLE = 3'd0, LOAD1 = 3'd1, LOAD2 = 3'd2;
    localparam [2 : 0] CALC1 = 3'd3, CALC2 = 3'd4, DONE = 3'd5;
    reg [2 : 0] state;
    
    // global buffer
    reg [DATA_WIDTH - 1 : 0] gbuf1 [0 : GBUF_SIZE - 1];
    reg [DATA_WIDTH - 1 : 0] gbuf2 [0 : GBUF_SIZE - 1];
    
    // counter
    reg [CNT_WIDTH - 1 : 0] cnt;
    
    // ain, bin
    wire [DATA_WIDTH - 1 : 0] ain = gbuf1[cnt];
    wire [DATA_WIDTH - 1 : 0] bin = gbuf2[cnt];

    // valid
    reg valid;
    
    // output
    wire dvalid;
    wire [DATA_WIDTH - 1 : 0] dout;
    
    always @ (posedge clk) begin
        if (reset) begin // synchronous reset
            done <= 0;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE:
                    if (start) begin
                        state <= LOAD1;
                        rdaddr <= 0;
                        cnt <= 0;
                    end
                    
                LOAD1: begin
                    gbuf1[cnt] <= rddata;
                    rdaddr <= rdaddr + 1;
                    if (cnt == GBUF_SIZE - 1) begin
                        state <= LOAD2;
                        cnt <= 0;
                    end
                    else
                        cnt <= cnt + 1;
                end
                
                LOAD2: begin
                    gbuf2[cnt] <= rddata;
                    if (cnt == GBUF_SIZE - 1) begin
                        state <= CALC1;
                        cnt <= 0;
                        valid <= 1;
                    end
                    else begin
                        rdaddr <= rdaddr + 1;
                        cnt <= cnt + 1;
                    end
                end
                
                CALC1: begin
                    state <= CALC2;
                    valid <= 0;
                end
                
                DONE: begin
                    if (cnt == DONE_STATE_CYCLE) begin
                        state <= IDLE;
                        done <= 0;
                    end
                    else
                        cnt <= cnt + 1;
                end
            endcase
        end
    end
    
    always @ (negedge clk) begin
        if (state == CALC2 && dvalid) begin
            if(cnt == GBUF_SIZE - 1) begin
                state <= DONE;
                out <= dout;
                done <= 1;
                cnt <= 0;
            end
            else begin
                state <= CALC1;
                cnt <= cnt + 1;
                valid <= 1;
            end
        end
    end

    my_pe # (
        .DATA_WIDTH(DATA_WIDTH)
    ) PE (
        .aclk(clk),
        .aresetn(~(reset | done)),
        .ain(ain),
        .bin(bin),
        .valid(valid),
        .dvalid(dvalid),
        .dout(dout)
    );
    
endmodule
