module pe_controller # (
    parameter integer DATA_WIDTH = 32, // size of data (int8, fp32, etc)
    parameter integer BRAM_ADDR_WIDTH = 15, // BRAM_SIZE == 2 ** BRAM_ADDR_WIDTH
    parameter integer BRAM_DATA_WIDTH = 32, // read BRAM_DATA_WIDTH bits per cycle
    parameter integer LINE_SIZE = 8, // 2 gbufs
    parameter integer DONE_STATE_CYCLE = 5, // wait some cycles
    parameter integer CNT_WIDTH = 3,
    parameter integer BRAM_WE_WIDTH = 4
)(
    // start
    input start,
    // reset/clk
    input resetn,
    input clk,
    // read
    output reg [BRAM_ADDR_WIDTH - 1 : 0] bram_addr,
    input [BRAM_DATA_WIDTH - 1 : 0] bram_rddata,
    // output
    output reg [BRAM_DATA_WIDTH - 1 : 0] bram_wrdata,
    output reg [DATA_WIDTH / 8 - 1 : 0] bram_we, // bram_we: true -> write, false -> read
    output reg done
);
    localparam integer DATA_WIDTH_BYTE = DATA_WIDTH / 8;

    // FSM states
    localparam [2 : 0] IDLE = 3'd0, LOAD1 = 3'd1, LOAD2 = 3'd2, HARV = 3'd3, DONE = 3'd4, WAIT1 = 3'd5, WAIT2 = 3'd6;
    // CALC states not needed due to pipeline
    reg [2 : 0] state;
    
    // global buffer
    reg [DATA_WIDTH - 1 : 0] gbuf1 [0 : LINE_SIZE - 1], gbuf2 [0 : LINE_SIZE - 1];
    
    // write buffer
    reg [DATA_WIDTH - 1 : 0] wrbuf [0 : LINE_SIZE - 1][0 : LINE_SIZE - 1];
    
    // counter
    reg [CNT_WIDTH - 1 : 0] cnt1, cnt2;

    // valid
    reg valid; // if all 16 elements loaded, CALC becomes true in 1 cycle
    
    // output
    wire dvalid;
    wire [DATA_WIDTH - 1 : 0] dout [0 : LINE_SIZE - 1][0 : LINE_SIZE - 1];
    
    integer u, v;
   
    always @ (posedge clk) begin
        if (~resetn) begin // synchronous reset
            bram_addr <= 0;
            bram_wrdata <= 0;
            bram_we <= 0;
            done <= 0;
            state <= IDLE;
            cnt1 <= 0;
            cnt2 <= 0;
            valid <= 0;
            // do not need to initialize gbuf1, gbuf2, wrbuf
        end
        else begin
            if (valid) valid <= 0;
            case (state)
                IDLE:
                    if (start) begin
                        bram_addr <= 0;
                        state <= LOAD1;
                        cnt1 <= 0;
                        cnt2 <= 0;
                    end
                    
                LOAD1: begin
                    gbuf1[cnt2] <= bram_rddata;
                    if (cnt2 == LINE_SIZE - 1) begin
                        bram_addr <= (LINE_SIZE + cnt1) * LINE_SIZE * DATA_WIDTH_BYTE;
                        state <= LOAD2;
                        cnt2 <= 0;
                    end
                    else begin
                        bram_addr <= bram_addr + LINE_SIZE * DATA_WIDTH_BYTE;
                        cnt2 <= cnt2 + 1;
                    end
                end
                
                LOAD2: begin
                    gbuf2[cnt2] <= bram_rddata;
                    if (cnt2 == LINE_SIZE - 1) begin
                        valid <= 1;
                        if (cnt1 == LINE_SIZE - 1)
                            state <= WAIT1;
                        else begin
                            bram_addr <= (cnt1 + 1) * DATA_WIDTH_BYTE;
                            state <= LOAD1;
                            cnt1 <= cnt1 + 1;
                            cnt2 <= 0;
                        end
                    end
                    else begin
                        bram_addr <= bram_addr + DATA_WIDTH_BYTE;
                        cnt2 <= cnt2 + 1;
                    end
                end
                
                WAIT1: state <= WAIT2;
                
                WAIT2: begin
                    if (dvalid) begin
                        bram_addr <= 0;
                        bram_wrdata <= dout[0][0];
                        bram_we <= {DATA_WIDTH_BYTE{1'b1}};
                        state <= HARV;
                        cnt1 <= 0;
                        cnt2 <= 1;
                        for (u = 0; u < 8; u = u + 1)
                            for (v = 0; v < 8; v = v + 1)
                                wrbuf[u][v] <= dout[u][v];
                    end
                end
                
                HARV: begin
                    bram_addr <= bram_addr + DATA_WIDTH_BYTE;
                    bram_wrdata <= wrbuf[cnt1][cnt2];
                    if (cnt1 == LINE_SIZE - 1 && cnt2 == LINE_SIZE - 1) begin
                        bram_we <= 0;
                        done <= 1;
                        state <= DONE;
                        cnt1 <= 0;
                    end
                    else begin
                        if (cnt2 == LINE_SIZE - 1) begin
                            cnt1 <= cnt1 + 1;
                            cnt2 <= 0;
                        end
                        else
                            cnt2 <= cnt2 + 1;
                    end
                end
                
                DONE: begin
                    if (cnt1 == DONE_STATE_CYCLE) begin
                        done <= 0;
                        state <= IDLE;
                    end
                    else
                        cnt1 <= cnt1 + 1;
                end
            endcase
        end
    end

    my_pe # (
        .DATA_WIDTH(DATA_WIDTH)
    ) PE (
        .aclk(clk),
        .aresetn(resetn & ~done),
        .ain(gbuf1[0]),
        .bin(gbuf2[0]),
        .valid(valid),
        .dvalid(dvalid),
        .dout(dout[0][0])
    );

    genvar i;
    
    generate for (i = 1; i < 64; i = i + 1) begin
        my_pe # (
            .DATA_WIDTH(DATA_WIDTH)
        ) PE (
            .aclk(clk),
            .aresetn(resetn & ~done),
            .ain(gbuf1[i / 8]),
            .bin(gbuf2[i % 8]),
            .valid(valid),
            .dout(dout[i / 8][i % 8])
        );
    end endgenerate
    
endmodule
