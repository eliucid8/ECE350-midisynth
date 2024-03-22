module div(
    dividend, divisor,
    reset, clk,
    quot, ready, div0
);

    input[31:0] dividend, divisor;
    input reset, clk;
    output[31:0] quot;
    output ready, div0;

    wire[31:0] negDiv, dvdIn, negQ, negInput, negOutput;
    // reuse negator hardware at end, mux between inputs/outputs based on reset signal.
    assign negInput = reset ? dividend : Q;
    assign negDiv = negOutput;
    assign negQ = negOutput;

    negator neg(negOutput, negInput);
    assign dvdIn = dividend[31] ? negDiv : dividend;

    wire[31:0] dvd, dvs; // latched values for dividend and divisor
    register #(32) dvdReg(
        .clk(clk), .writeEnable(reset), .reset(1'b0), .dataIn(dvdIn), .dataOut(dvd)
    );
    register #(32) dvsReg(
        .clk(clk), .writeEnable(reset), .reset(1'b0), .dataIn(divisor), .dataOut(dvs)
    );
    assign div0 = ~|{dvs};
    
    wire dvdSign, dvsSign;
    assign dvsSign = dvs[31];
    // latch dvd sign, because we always make dvd positive
    register #(1) dvdSignReg(
        .clk(clk), .writeEnable(reset), .reset(1'b0), .dataIn(dividend[31]), .dataOut(dvdSign)
    );

    wire[5:0] cycle;
    counter #(6) county_dude(.count(cycle), .clr(reset), .clk(clk));
    assign ready = cycle[5];

    wire[31:0] R, Q;
    wire[63:0] rqIn, afterSub;
    assign rqIn = reset ? {32'b0, dividend} : afterSub; 

    // basically just do a synchronous reset
    initRegister #(64) RQreg(
        .dataOut({R, Q}), .dataIn(rqIn),
        .clk(clk), .writeEnable(!ready), .reset(reset), .init({32'b0, dvdIn})
    );

    wire cla_sub = !R[31] ^ dvsSign;
    // if MSB = 0, add negative dvs.
    wire[31:0] cla_vin = cla_sub ? ~dvs : dvs;
    // if MSB = 0, subtract (put 1 in cin)
    cla_32 cla(
        .A({R[30:0], Q[31]}), .B(cla_vin), .Cin(cla_sub),
        .Sum(afterSub[63:32])
    );
    assign afterSub[31:1] = Q[30:0];
    assign afterSub[0] = ~afterSub[63];

    assign quot = (dvdSign ^ dvsSign) ? negQ : Q;
    // Requires a final add if we want the remainder to be correct, i.e. if we want a modulo operation
endmodule
