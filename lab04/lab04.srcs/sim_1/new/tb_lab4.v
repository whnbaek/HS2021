`timescale 1ns / 1ps

module tb_fp();

    // for my IP
    reg [32 - 1 : 0] ain;
    reg [32 - 1 : 0] bin;
    reg [32 - 1 : 0] cin;
    reg rst;
    reg clk;
    wire [32 - 1 : 0] res;
    wire dvalid;
    reg [7 : 0] exp1;
    reg [7 : 0] exp2;
    reg [7 : 0] exp3;
    reg [22 : 0] man1;
    reg [22 : 0] man2;
    reg [22 : 0] man3;
    
    // for test
    integer i;
    // random test vector generation
    initial begin
        clk <= 0;
        rst <= 0;
        for(i = 0; i < 32; i = i + 1) begin
            exp1 = $urandom%(2 ** 7) + 8'd127; // 127 ~ 254
            exp2 = $urandom%(2 ** 7);          //   0 ~ 127
            exp3 = exp1 + exp2 - 8'd127;       //   0 ~ 254
            man1 = $urandom%(2 ** 23);
            man2 = $urandom%(2 ** 23);
            man3 = $urandom%(2 ** 23);
            
            ain = {1'b0, exp1, man1};
            bin = {1'b0, exp2, man2};
            cin = {1'b0, exp3, man3};
            #20;
        end
    end
    
    always #5 clk = ~clk;
    
    floating_point_MAC UUT(
        .aclk(clk),
        .aresetn(~rst),
        .s_axis_a_tvalid(1'b1),
        .s_axis_b_tvalid(1'b1),
        .s_axis_c_tvalid(1'b1),
        .s_axis_a_tdata(ain),
        .s_axis_b_tdata(bin),
        .s_axis_c_tdata(cin),
        .m_axis_result_tvalid(dvalid),
        .m_axis_result_tdata(res)
    );
    
endmodule

module tb_int();

    // for my IP
    reg [32 - 1 : 0] ain;
    reg [32 - 1 : 0] bin;
    reg [32 - 1 : 0] cin;
    reg rst;
    reg clk;
    wire [32 - 1 : 0] res;
    
    // for test
    integer i;
    // random test vector generation
    initial begin
        clk <= 0;
        rst <= 1;
        #20;
        rst <= 0;
        for(i = 0; i < 32; i = i + 1) begin            
            ain <= $urandom%(2 ** 16);
            bin <= $urandom%(2 ** 16);
            cin <= $urandom%(2 ** 31);
            #20;
        end
    end
    
    always #5 clk <= ~clk;
    
    integer_MAC UDT(
        .CLK(clk),
        .CE(1'b1),
        .SCLR(rst),
        .A(ain),
        .B(bin),
        .C(cin),
        .SUBTRACT(1'b0),
        .P(res)
    );
    
endmodule
