module led_array #( parameter ROWS = 4, COLS = 8) (
    input [$clog2(ROWS * COLS) - 1 :0] idx,
    input [23:0] RGBval,
    input wren,
    output out_signal,
);

    

endmodule