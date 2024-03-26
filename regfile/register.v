module register
#(
    parameter WIDTH = 32
)
(
    clk,
    writeEnable, reset,
    dataIn, dataOut
);

    input   clk, writeEnable, reset;
    input   [WIDTH-1:0] dataIn;
    output  [WIDTH-1:0] dataOut;

    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin
            wire dff_out;
            dffe_ref r_dff(
                .clk(clk), .d(dataIn[i]), .q(dff_out),
                .en(writeEnable), .clr(reset)
            );
            // tristate buffer
            assign dataOut[i] = dff_out;
        end
    endgenerate
endmodule

module initRegister #(
    parameter WIDTH = 32
) (
    clk,
    writeEnable, reset, init,
    dataIn, dataOut
);
    input   clk, writeEnable, reset;
    input   [WIDTH-1:0] dataIn, init;
    output  [WIDTH-1:0] dataOut;

    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin
            wire dff_out;
            dffe_init r_dff(
                .clk(clk), .d(dataIn[i]), .q(dff_out),
                .en(writeEnable), .clr(reset), .init(init[i])
            );
            // tristate buffer
            assign dataOut[i] = dff_out;
        end
    endgenerate
endmodule