module bitwise_not
    #(
        parameter WIDTH = 32
    )

    (
        output[WIDTH - 1:0] dout,
        input[WIDTH - 1:0] din
    );

    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin
            not bitnot(dout[i], din[i]);
        end
    endgenerate
endmodule

module or_32(output dout, input[31:0] din);
    wire[3:0] intermediates;
    
    or or0(intermediates[0], din[0], din[1], din[2], din[3], din[4], din[5], din[6], din[7]);
    or or1(intermediates[1], din[8], din[9], din[10], din[11], din[12], din[13], din[14], din[15]);
    or or2(intermediates[2], din[16], din[17], din[18], din[19], din[20], din[21], din[22], din[23]);
    or or3(intermediates[3], din[24], din[25], din[26], din[27], din[28], din[29], din[30], din[31]);

    or or4(dout, intermediates[0], intermediates[1], intermediates[2], intermediates[3]);
endmodule