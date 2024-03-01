module left_barrel_shifter(dout, din, shamt);
    input[31:0] din;
    input[4:0] shamt;
    output[31:0] dout;

    wire[31:0] shift1, shift2, shift4, shift8, shift16, in2, in4, in8, in16;


    lshift #(.WIDTH(32), .SHAMT(1)) sll1(.dout(shift1), .din(din));
    lshift #(.WIDTH(32), .SHAMT(2)) sll2(.dout(shift2), .din(in2));
    lshift #(.WIDTH(32), .SHAMT(4)) sll4(.dout(shift4), .din(in4));
    lshift #(.WIDTH(32), .SHAMT(8)) sll8(.dout(shift8), .din(in8));
    lshift #(.WIDTH(32), .SHAMT(16)) sll16(.dout(shift16), .din(in16));

    mux_2 choose1(.out(in2), .select(shamt[0]), .in0(din), .in1(shift1));
    mux_2 choose2(.out(in4), .select(shamt[1]), .in0(in2), .in1(shift2));
    mux_2 choose4(.out(in8), .select(shamt[2]), .in0(in4), .in1(shift4));
    mux_2 choose8(.out(in16), .select(shamt[3]), .in0(in8), .in1(shift8));
    mux_2 choose16(.out(dout), .select(shamt[4]), .in0(in16), .in1(shift16));
endmodule

module right_barrel_shifter(dout, din, shamt);
    input[31:0] din;
    input[4:0] shamt;
    output[31:0] dout;

    wire[31:0] shift1, shift2, shift4, shift8, shift16, in2, in4, in8, in16;


    rshift #(.WIDTH(32), .SHAMT(1)) sra1(.dout(shift1), .din(din));
    rshift #(.WIDTH(32), .SHAMT(2)) sra2(.dout(shift2), .din(in2));
    rshift #(.WIDTH(32), .SHAMT(4)) sra4(.dout(shift4), .din(in4));
    rshift #(.WIDTH(32), .SHAMT(8)) sra8(.dout(shift8), .din(in8));
    rshift #(.WIDTH(32), .SHAMT(16)) sra16(.dout(shift16), .din(in16));

    mux_2 choose1(.out(in2), .select(shamt[0]), .in0(din), .in1(shift1));
    mux_2 choose2(.out(in4), .select(shamt[1]), .in0(in2), .in1(shift2));
    mux_2 choose4(.out(in8), .select(shamt[2]), .in0(in4), .in1(shift4));
    mux_2 choose8(.out(in16), .select(shamt[3]), .in0(in8), .in1(shift8));
    mux_2 choose16(.out(dout), .select(shamt[4]), .in0(in16), .in1(shift16));
endmodule