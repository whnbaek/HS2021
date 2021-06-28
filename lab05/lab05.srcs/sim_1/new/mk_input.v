`timescale 1ns / 1ps

module mk_input();

    integer i;
    reg [31 : 0] data [0 : 8191];

    initial begin
        for (i = 0; i < 8192; i = i + 1)
            data[i] = i;
        $writememh("input.txt", data);
    end

endmodule
