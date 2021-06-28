module my_pe # (
    parameter integer DATA_WIDTH = 8,
    parameter integer RESULT_WIDTH = 32
)(
    // clk/reset
    input aclk,
    input aresetn,
    // port A
    input signed [DATA_WIDTH - 1 : 0] ain,
    // port B
    input signed [DATA_WIDTH - 1 : 0] bin,
    // integrated valid signal
    input valid,
    // computation result
    output reg dvalid,
    output reg signed [RESULT_WIDTH - 1 : 0] dout
);
    always @ (posedge aclk) begin
        if (!aresetn) begin
            dvalid <= 0;
            dout <= 0;
        end
        else if (valid) begin
            dvalid <= 1;
            dout <= dout + ain * bin;
        end
        else if (dvalid) dvalid <= 0;
    end
    
endmodule
