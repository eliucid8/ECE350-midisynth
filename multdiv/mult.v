module mult(
    multiplicand, multiplier,
    reset, clk,
    prod, ovf, ready
);
    // mpc = multiplicand, mpl = multiplier
    input[31:0] multiplicand, multiplier;
    input reset, clk;
    output[31:0] prod;
    output ovf;
    output ready;

    wire[31:0] mpc, mpl; // latched multiplicand and multiplier

    wire do_neg_mpc, do_neg_mpl;
    wire[31:0] neg_prod, neg_mpc, neg_mpl, mult_mpc_in, mult_mpl_in;
    wire[63:0] mult_out;

    register #(32) mpcReg(.clk(clk), .writeEnable(reset), .reset(1'b0), .dataIn(multiplicand), .dataOut(mpc)); // enable write only on ctrl_MULT
    register #(32) multiplierReg(.clk(clk), .writeEnable(reset), .reset(1'b0), .dataIn(multiplier), .dataOut(mpl));
    
    assign do_neg_mpc = mpc[31];
    assign do_neg_mpl = mpl[31];
    
    negator negmpc(neg_mpc, mpc);
    negator negmpl(neg_mpl, mpl);

    assign mult_mpc_in = do_neg_mpc ? neg_mpc : mpc;
    assign mult_mpl_in = do_neg_mpl ? neg_mpl : mpl;

    dadda_mult luigi(.Product(mult_out), .A(mult_mpc_in), .B(mult_mpl_in));

    negator negprod(neg_prod, mult_out[31:0]);
    assign prod = do_neg_mpc^do_neg_mpl ? neg_prod: mult_out[31:0];

    wire[5:0] count;
    counter #(6) multCounter(.count(count), .clr(reset), .clk(clk));
    assign ready = count[3]; // delay for 5 cycles?

    // If we allowed 64-bit outputs, we would not overflow at all. I think. What causes overflow here is the fact that we truncate the multiplication result down to 32 bits. If we have non-zero components of the result in the upper accumulator (taking into account sign extension), this indicates an overflown value, even if signs are correct.
    // All bits in the upper accumulator (ie final adder result) should be equal to the sign of the lower register's result. Thus, we OR the bits together for a positive product, and NAND the bits for a negative one.

    // assuming reduction operators are optimized here...
    wire notAllZero, notAllOne;
    // assign notAllZero = |{|accOut[31:24],  |accOut[23:16], |accOut[15:8], |accOut[7:0]};
    assign notAllZero = |mult_out[63:32]; // all zeroes
    // assign notAllOne = |{~&accOut[31:24],  ~&accOut[23:16], ~&accOut[15:8], ~&accOut[7:0]};
    assign notAllOne = ~&mult_out[63:32]; // all 1s

    wire upperOvf;
    // assign upperOvf = prod[31] ? notAllOne : notAllZero;
    assign upperOvf = (notAllOne && notAllZero); // if the upper register is neither all zeroes nor all ones

    // or you could just look at lecture slides and see that you also have to accoun for answers that don't make sense (ie signs don't line up ie xor the operands and product)
    // sign of multiplier is in last spot of shift reg.

    wire signOvf;
    xor sovf(signOvf, mpc[31], mpl[31], prod[31]);

    // and also if either operand is 0 it's physically impossible to overflow?
    wire Azero, Bzero;
    assign Azero = ~|mpc;
    assign Bzero = ~|mpl;

    // if we have nonzero operands, and either sign or upper accumulator signals overflow, signal an overflow.
    assign ovf = !Azero && !Bzero && (signOvf || upperOvf);

endmodule