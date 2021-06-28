`timescale 1ns / 1ps

module tb_my_pe # (
        parameter L_RAM_SIZE = 6
    );
    
    // global buffer
    reg [31 : 0] gb1 [0 : 2 ** L_RAM_SIZE - 1];
    reg [31 : 0] gb2 [0 : 2 ** L_RAM_SIZE - 1];
    
    reg aclk;
    reg aresetn;
    wire [31 : 0] ain;
    wire [31 : 0] bin;
    integer n;
    reg valid;
    wire dvalid;
    wire [31 : 0] dout;
    
    integer i;
    
    initial begin
        aclk = 1;
        aresetn = 1;
        valid = 0;
        
        for (i = 0; i < 16; i = i + 1) begin
            gb1[i][31 : 23] = 9'b010000000;
            gb1[i][22 :  0] = $urandom%(2 ** 23);
            gb2[i][31 : 23] = 9'b010000000;
            gb2[i][22 :  0] = $urandom%(2 ** 23);
        end
        
        #1;
        aresetn = 0;
        #10;
        aresetn = 1;
        #10;
        n = 0;
        valid = 1;
        #10;
        valid = 0;
    end
    
    assign ain = gb1[n];
    assign bin = gb2[n];
    
    always @ (negedge aclk)
        if (dvalid && n < 15) begin
            n = n + 1;
            valid = 1;
            #6;
            valid = 0;
        end
    
    my_pe PE (
        .aclk(aclk),
        .aresetn(aresetn),
        .ain(ain),
        .bin(bin),
        .valid(valid),
        .dvalid(dvalid),
        .dout(dout)
    );
    
    always #5 aclk = ~aclk;

endmodule
