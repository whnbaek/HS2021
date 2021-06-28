`timescale 1ns / 1ps

module one_sec_checker(
    input GCLK,
    input BTNC,
    output reg [7 : 0] LD
    );
    
    integer down_counter;
    
    always @ (posedge GCLK) begin
        if (BTNC) begin
            down_counter <= 100000000;
            LD <= 8'b0;
        end
        else begin
            if (down_counter)
                down_counter <= down_counter - 1;
            else begin
                down_counter <= 100000000;
                LD <= LD + 1;
            end
        end
    end
    
endmodule
