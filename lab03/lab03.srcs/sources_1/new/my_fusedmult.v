`timescale 1ns / 1ps

module my_fusedmult #(
    parameter BITWIDTH = 32
)
(
    input [BITWIDTH - 1 : 0] ain,
    input [BITWIDTH - 1 : 0] bin,
    input en,
    input clk,
    output [2 * BITWIDTH - 1 : 0] dout
);

    reg [2 * BITWIDTH - 1 : 0] acc;
    
    initial begin
        acc <= 0;
    end
    
    always @(posedge clk) begin
        if(~en) begin
            acc <= 0;
        end
        else begin
            acc <= ain * bin + acc;
        end
    end
    
    assign dout = acc;


endmodule
