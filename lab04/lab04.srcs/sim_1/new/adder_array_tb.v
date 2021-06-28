`timescale 1ns / 1ps

module adder_array_tb(

    );
    
    reg [31 : 0] ain [3:0];
    reg [31 : 0] bin [3:0];
    wire [31 : 0] dout[3:0];
    wire [3:0] overflow;
    
    integer i, j,cmd;
    
    initial begin
        for (cmd=0; cmd<=4; cmd=cmd+1) begin
            for (i=0; i<4; i=i+1) begin
                for (j=0; j<4; j=j+1) begin
                    ain[j] = $urandom%(2 ** 32-1);
                    bin[j] = $urandom%(2 ** 32-1);
                end
                #5;
            end
        end
    end
    
    adder_array ADDER_ARRAY(
        .cmd(cmd), .ain0(ain[0]), .ain1(ain[1]), .ain2(ain[2]), .ain3(ain[3]),
.bin0(bin[0]), .bin1(bin[1]), .bin2(bin[2]), .bin3(bin[3]),
 .dout0(dout[0]), .dout1(dout[1]), .dout2(dout[2]), .dout3(dout[3]), .overflow(overflow)
    );
    
endmodule
