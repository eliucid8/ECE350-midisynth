module mux_2(out, select, in0, in1);
    input select;
    input [31:0] in0, in1;
    output [31:0] out;
    assign out = select ? in1 : in0;
endmodule

module mux_4(out, select, in0, in1, in2, in3);
    input   [1:0] select;
    input   [31:0] in0, in1, in2, in3;
    output  [31:0] out;
    wire    [31:0] w1, w2;
    
    mux_2 first_top(w1, select[0], in0, in1);
    mux_2 first_bot(w2, select[0], in2, in3);
    mux_2 second_out(out, select[1], w1, w2);
endmodule

module mux_8(out, select, in0, in1, in2, in3, in4, in5, in6, in7);
    input [2:0] select;
    input [31:0] in0, in1, in2, in3, in4, in5, in6, in7;
    output [31:0] out;

    wire [31:0] muxtop, muxbot;

    mux_4 first_top(muxtop, select[1:0], in0, in1, in2, in3);
    mux_4 first_bot(muxbot, select[1:0], in4, in5, in6, in7);
    mux_2 second(out, select[2], muxtop, muxbot);
endmodule

module decoder_8(dec, enc);
    // this would be paramaterized, but I'd need a shift to calculate how many outputs there should be.
    input[2:0] enc;

    output[7:0] dec;

    wire[31:0] shift_out;

    assign dec = shift_out[7:0];
    left_barrel_shifter lbs(shift_out, 32'b1, {2'b0, enc});
endmodule

module decoder32(out, select, enable);
    input [4:0] select;
    input enable;
    output [31:0] out;

    assign out = enable << select;
endmodule

//paramaterized for multdiv
module mux2 #(
    parameter WIDTH = 32
) (
    output[WIDTH-1:0] out,
    input sel,
    input[WIDTH-1:0] in0, in1
);

    assign out = sel ? in1 : in0;

endmodule

module mux4 #(
    parameter WIDTH = 32
) (
    output[WIDTH-1:0] out,
    input[1:0] sel,
    input[WIDTH-1:0] in0, in1, in2, in3
);
    
    assign out = sel[1] ? (
        sel[0] ? in3 : in2
    ) : (
        sel[0] ? in1 : in0
    );

endmodule