// module led_array #( parameter ROWS = 4, COLS = 8) (
//     input [$clog2(ROWS * COLS) - 1 :0] idx,
//     input [23:0] RGBval,
//     input wren,
//     output out_signal
// );

    

// endmodule


module led_index(
    input [23:0] rgb_color,
    input [3:0] col, input [2:0] place, //col is 0-15, place is 0-7 with 0 being closest to ground
    input clk100,
    output [671:0] buff0, buff1, buff2, buff3
);

wire col_index;

always @(negedge clk100) begin
clk0 <= (col == 0) ? 1 : 0;
clk1 <= (col == 1) ? 1 : 0;
clk2 <= (col == 2) ? 1 : 0;
clk3 <= (col == 3) ? 1 : 0;
clk4 <= (col == 4) ? 1 : 0;
clk5 <= (col == 5) ? 1 : 0;
clk6 <= (col == 6) ? 1 : 0;
clk7 <= (col == 7) ? 1 : 0;
clk8 <= (col == 8) ? 1 : 0;
clk9 <= (col == 9) ? 1 : 0;
clk10 <= (col == 10) ? 1 : 0;
clk11 <= (col == 11) ? 1 : 0;
clk12 <= (col == 12) ? 1 : 0;
clk13 <= (col == 13) ? 1 : 0;
clk14 <= (col == 14) ? 1 : 0;
clk15 <= (col == 15) ? 1 : 0;
end

reg clk0, clk1, clk2, clk3, clk4, clk5, clk6, clk7, clk8, clk9, clk10, clk11, clk12, clk13, clk14, clk15;

minibuff col0(rgb_color, place, 1'b0, clk0, buff0[167:0]);
minibuff col1(rgb_color, place, 1'b1, clk1, buff0[335:168]);
minibuff col2(rgb_color, place, 1'b0, clk2, buff0[503:336]);
minibuff col3(rgb_color, place, 1'b1, clk3, buff0[671:504]);

minibuff col4(rgb_color, place, 1'b0, clk4, buff1[167:0]);
minibuff col5(rgb_color, place, 1'b1, clk5, buff1[335:168]);
minibuff col6(rgb_color, place, 1'b0, clk6, buff1[503:336]);
minibuff col7(rgb_color, place, 1'b1, clk7, buff1[671:504]);

minibuff col8(rgb_color, place, 1'b0, clk8, buff2[167:0]);
minibuff col9(rgb_color, place, 1'b1, clk9, buff2[335:168]);
minibuff col10(rgb_color, place, 1'b0, clk10, buff2[503:336]);
minibuff col11(rgb_color, place, 1'b1, clk11, buff2[671:504]);

minibuff col12(rgb_color, place, 1'b0, clk12, buff3[167:0]);
minibuff col13(rgb_color, place, 1'b1, clk13, buff3[335:168]);
minibuff col14(rgb_color, place, 1'b0, clk14, buff3[503:336]);
minibuff col15(rgb_color, place, 1'b1, clk15, buff3[671:504]);





endmodule


module minibuff(input [23:0] rgb, input [2:0] index, input flip, clk, output reg [167:0] buff);

reg [23:0] pix0, pix1, pix2, pix3, pix4, pix5, pix6, pix7;

initial begin 
    pix0 = 0;
    pix1 = 0;
    pix2 = 0;
    pix3 = 0;
    pix4 = 0;
    pix5 = 0;
    pix6 = 0;
    pix7 = 0;
    buff = 0;
end

always @(posedge clk) begin

    case (index)
        3'd0: pix0 = rgb;
        3'd1: pix1 = rgb;
        3'd2: pix2 = rgb;
        3'd3: pix3 = rgb;
        3'd4: pix4 = rgb;
        3'd5: pix5 = rgb;
        3'd6: pix6 = rgb;
        3'd7: pix7 = rgb;
    endcase

        buff = flip ? {pix7, pix6, pix5, pix4, pix3, pix2, pix1, pix0} : {pix0, pix1, pix2, pix3, pix4, pix5, pix6, pix7};

end

//assign buff = flip ? {pix7, pix6, pix5, pix4, pix3, pix2, pix1, pix0} : {pix0, pix1, pix2, pix3, pix4, pix5, pix6, pix7};

endmodule