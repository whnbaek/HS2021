`timescale 1ns / 1ps

module my_pe # (
    parameter integer DATA_WIDTH = 32
)(
    // clk/reset
    input aclk,
    input aresetn,
    // port A
    input [DATA_WIDTH - 1 : 0] ain,
    // port B
    input [DATA_WIDTH - 1 : 0] bin,
    // integrated valid signal
    input valid,
    // computation result
    output dvalid,
    output [DATA_WIDTH - 1 : 0] dout
);
    
    reg [DATA_WIDTH - 1 : 0] psum;
    wire [DATA_WIDTH - 1 : 0] res;
    
    assign dout = dvalid ? res : 0;
    
    always @ (posedge aclk)
        if (!aresetn)
            psum <= 0;
            
    always @ (negedge aclk)
        if (dvalid)
            psum <= res;
    
    fp32_fma FMA (
        .s_axis_a_tdata(ain),
        .s_axis_a_tvalid(valid),
        .s_axis_b_tdata(bin),
        .s_axis_b_tvalid(valid),
        .s_axis_c_tdata(psum),
        .s_axis_c_tvalid(valid),
        .aclk(aclk),
        .aresetn(aresetn),
        .m_axis_result_tdata(res),
        .m_axis_result_tvalid(dvalid)
    );
    
endmodule
