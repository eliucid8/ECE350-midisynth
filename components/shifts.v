module lshift
    #(
        parameter WIDTH = 32,
        parameter SHAMT = 1
    )
    // non-parameters
    (
        output[WIDTH-1:0] dout,
        input[WIDTH-1:0] din
    );
    
    // concatenates SHAMT constant binary 0s together
    assign dout[SHAMT - 1:0] = {SHAMT{1'b0}};
    // wires up rest of circuit!
    assign dout[WIDTH - 1: SHAMT] = din[WIDTH- 1 - SHAMT:0];
endmodule

module rshift
    #(
        parameter WIDTH = 32,
        parameter SHAMT = 1
    )
    // non-parameters
    (
        input[WIDTH-1:0] din,
        output[WIDTH-1:0] dout
    );
    
    // this assigns exactly SHAMT wires to be sexed (sign extended)
    assign dout[WIDTH-1 : WIDTH - SHAMT] = {SHAMT{din[WIDTH-1]}};
    // wires up rest of shifter!
    assign dout[WIDTH - SHAMT - 1 : 0] = din[WIDTH-1:SHAMT];
endmodule