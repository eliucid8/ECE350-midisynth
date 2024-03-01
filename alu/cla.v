module cla_64(A, B, Cin, Cout, Sum, BAnd, BOr);
    input[63:0] A, B;
    input Cin;

    output[63:0] Sum, BAnd, BOr;
    output Cout;

    wire[7:0] carry, G, P;

    assign carry[0] = Cin;

    genvar i;
    generate
        for(i = 0; i < 64; i = i + 8) begin
            cla_8 adder0(
                .A(A[i+7:i]), .B(B[i+7:i]), .Cin(carry[i>>3]), 
                .Sum(Sum[i+7:i]), .Gen(G[i>>3]), .Prop(P[i>>3]),
                .BAnd(BAnd[i+7:i]), .BOr(BOr[i+7:i])
            );
        end
    endgenerate

    wire [0:0] c1;
    wire [1:0] c2;
    wire [2:0] c3;
    wire [3:0] c4;
    wire [4:0] c5;
    wire [5:0] c6;
    wire [6:0] c7;
    wire [7:0] c8;

    assign c1[0] = &{P[0], Cin};
    assign carry[1] = |{G[0], c1[0]};

    assign c2[0] = &{P[1], P[0], Cin};
    assign c2[1] = &{P[1], G[0]};
    assign carry[2] = |{G[1], c2[1], c2[0]};

    assign c3[0] = &{P[2], P[1], P[0], Cin};
    assign c3[1] = &{P[2], P[1], G[0]};
    assign c3[2] = &{P[2], G[1]};
    assign carry[3] = |{G[2], c3[2], c3[1], c3[0]};

    assign c4[0] = &{P[3], P[2], P[1], P[0], Cin};
    assign c4[1] = &{P[3], P[2], P[1], G[0]};
    assign c4[2] = &{P[3], P[2], G[1]};
    assign c4[3] = &{P[3], G[2]};
    assign carry[4] = |{G[3], c4[3], c4[2], c4[1], c4[0]};

    assign c5[0] = &{P[4], P[3], P[2], P[1], P[0], Cin};
    assign c5[1] = &{P[4], P[3], P[2], P[1], G[0]};
    assign c5[2] = &{P[4], P[3], P[2], G[1]};
    assign c5[3] = &{P[4], P[3], G[2]};
    assign c5[4] = &{P[4], G[3]};
    assign carry[5] = |{G[4], c5[4], c5[3], c5[2], c5[1], c5[0]};

    assign c6[0] = &{P[5], P[4], P[3], P[2], P[1], P[0], Cin};
    assign c6[1] = &{P[5], P[4], P[3], P[2], P[1], G[0]};
    assign c6[2] = &{P[5], P[4], P[3], P[2], G[1]};
    assign c6[3] = &{P[5], P[4], P[3], G[2]};
    assign c6[4] = &{P[5], P[4], G[3]};
    assign c6[5] = &{P[5], G[4]};
    assign carry[6] = |{G[5], c6[5], c6[4], c6[3], c6[2], c6[1], c6[0]};

    assign c7[0] = &{P[6], P[5], P[4], P[3], P[2], P[1], P[0], Cin};
    assign c7[1] = &{P[6], P[5], P[4], P[3], P[2], P[1], G[0]};
    assign c7[2] = &{P[6], P[5], P[4], P[3], P[2], G[1]};
    assign c7[3] = &{P[6], P[5], P[4], P[3], G[2]};
    assign c7[4] = &{P[6], P[5], P[4], G[3]};
    assign c7[5] = &{P[6], P[5], G[4]};
    assign c7[6] = &{P[6], G[5]};
    assign carry[7] = |{G[6], c7[6], c7[5], c7[4], c7[3], c7[2], c7[1], c7[0]};

    assign c8[0] = &{P[7], P[6], P[5], P[4], P[3], P[2], P[1], P[0], Cin};
    assign c8[1] = &{P[7], P[6], P[5], P[4], P[3], P[2], P[1], G[0]};
    assign c8[2] = &{P[7], P[6], P[5], P[4], P[3], P[2], G[1]};
    assign c8[3] = &{P[7], P[6], P[5], P[4], P[3], G[2]};
    assign c8[4] = &{P[7], P[6], P[5], P[4], G[3]};
    assign c8[5] = &{P[7], P[6], P[5], G[4]};
    assign c8[6] = &{P[7], P[6], G[5]};
    assign c8[7] = &{P[7], G[6]};
    assign Cout = |{G[7], c8[7], c8[6], c8[5], c8[4], c8[3], c8[2], c8[1], c8[0]};

endmodule

module cla_32(A, B, Cin, Cout, Sum, BAnd, BOr);
    input[31:0] A, B;
    input Cin;

    output[31:0] Sum, BAnd, BOr;
    output Cout;

    wire[3:0] carry, G, P;

    assign carry[0] = Cin;

    cla_8 adder0(
        .A(A[7:0]), .B(B[7:0]), .Cin(carry[0]), 
        .Sum(Sum[7:0]), .Gen(G[0]), .Prop(P[0]),
        .BAnd(BAnd[7:0]), .BOr(BOr[7:0])
        );
    cla_8 adder1(
        .A(A[15:8]), .B(B[15:8]), .Cin(carry[1]),
        .Sum(Sum[15:8]), .Gen(G[1]), .Prop(P[1]),
        .BAnd(BAnd[15:8]), .BOr(BOr[15:8])
        );
    cla_8 adder2(
        .A(A[23:16]), .B(B[23:16]), .Cin(carry[2]), 
        .Sum(Sum[23:16]), .Gen(G[2]), .Prop(P[2]),
        .BAnd(BAnd[23:16]), .BOr(BOr[23:16])
        );
    cla_8 adder3(
        .A(A[31:24]), .B(B[31:24]), .Cin(carry[3]), 
        .Sum(Sum[31:24]), .Gen(G[3]), .Prop(P[3]),
        .BAnd(BAnd[31:24]), .BOr(BOr[31:24])
        );
    
    // carry lookahead logic
    wire c1;
    wire[1:0] c2;
    wire[2:0] c3;
    wire[3:0] c4;

    and and10(c1, P[0], Cin);
    or  or1(carry[1], G[0], c1);

    and and20(c2[0], P[1], P[0], Cin);
    and and21(c2[1], P[1], G[0]);
    or  or2(carry[2], G[1], c2[1], c2[0]);

    and and30(c3[0], P[2], P[1], P[0], Cin);
    and and31(c3[1], P[2], P[1], G[0]);
    and and32(c3[2], P[2], G[1]);
    or  or3(carry[3], G[2], c3[2], c3[1], c3[0]);

    and and40(c4[0], P[3], P[2], P[1], P[0], Cin);
    and and41(c4[1], P[3], P[2], P[1], G[0]);
    and and42(c4[2], P[3], P[2], G[1]);
    and and43(c4[3], P[3], G[2]);
    or  or4(Cout, G[3], c4[3], c4[2], c4[1], c4[0]);

endmodule

module cla_8(A, B, Cin, Sum, Gen, Prop, BAnd, BOr);
    // we don't need a Cout, because we lookahead for that!
    input[7:0] A, B;
    input Cin;

    output[7:0] Sum, BAnd, BOr;
    output Gen, Prop;

    wire[7:0] g, p;
    wire[7:0] carry;
    assign carry[0] = Cin;
    // assign Gen = g[7:0];
    // assign Prop = p[7:0];
    
    wire c1;
    wire[1:0] c2;
    wire[2:0] c3;
    wire[3:0] c4;
    wire[4:0] c5;
    wire[5:0] c6;
    wire[6:0] c7;
    wire[7:0] c8; // used for top level gen & Prop

    genvar i;
    generate
        for(i = 0; i < 8; i = i + 1) begin
            and gand(g[i], A[i], B[i]);
            or  por(p[i], A[i], B[i]);
        end
    endgenerate

    // Carry generation
    // no clue how to use a genvar for this part... I think you need behavioral?
    and and10(c1, p[0], Cin);
    or  or1(carry[1], g[0], c1);

    and and20(c2[0], p[1], p[0], Cin);
    and and21(c2[1], p[1], g[0]);
    or  or2(carry[2], g[1], c2[1], c2[0]);

    and and30(c3[0], p[2], p[1], p[0], Cin);
    and and31(c3[1], p[2], p[1], g[0]);
    and and32(c3[2], p[2], g[1]);
    or  or3(carry[3], g[2], c3[2], c3[1], c3[0]);
    
    and and40(c4[0], p[3], p[2], p[1], p[0], Cin);
    and and41(c4[1], p[3], p[2], p[1], g[0]);
    and and42(c4[2], p[3], p[2], g[1]);
    and and43(c4[3], p[3], g[2]);
    or  or4(carry[4], g[3], c4[3], c4[2], c4[1], c4[0]);

    and and50(c5[0], p[4], p[3], p[2], p[1], p[0], Cin);
    and and51(c5[1], p[4], p[3], p[2], p[1], g[0]);
    and and52(c5[2], p[4], p[3], p[2], g[1]);
    and and53(c5[3], p[4], p[3], g[2]);
    and and54(c5[4], p[4], g[3]);
    or  or5(carry[5], g[4], c5[4], c5[3], c5[2], c5[1], c5[0]);

    and and60(c6[0], p[5], p[4], p[3], p[2], p[1], p[0], Cin);
    and and61(c6[1], p[5], p[4], p[3], p[2], p[1], g[0]);
    and and62(c6[2], p[5], p[4], p[3], p[2], g[1]);
    and and63(c6[3], p[5], p[4], p[3], g[2]);
    and and64(c6[4], p[5], p[4], g[3]);
    and and65(c6[5], p[5], g[4]);
    or  or6(carry[6], g[5], c6[5], c6[4], c6[3], c6[2], c6[1], c6[0]);

    and and70(c7[0], p[6], p[5], p[4], p[3], p[2], p[1], p[0], Cin);
    and and71(c7[1], p[6], p[5], p[4], p[3], p[2], p[1], g[0]);
    and and72(c7[2], p[6], p[5], p[4], p[3], p[2], g[1]);
    and and73(c7[3], p[6], p[5], p[4], p[3], g[2]);
    and and74(c7[4], p[6], p[5], p[4], g[3]);
    and and75(c7[5], p[6], p[5], g[4]);
    and and76(c7[6], p[6], g[5]);
    or  or7(carry[7], g[6], c7[6], c7[5], c7[4], c7[3], c7[2], c7[1], c7[0]);

    // top level gen and Prop
    and and80(c8[0], p[7], p[6], p[5], p[4], p[3], p[2], p[1], p[0], Cin);
    and and81(c8[1], p[7], p[6], p[5], p[4], p[3], p[2], p[1], g[0]);
    and and82(c8[2], p[7], p[6], p[5], p[4], p[3], p[2], g[1]);
    and and83(c8[3], p[7], p[6], p[5], p[4], p[3], g[2]);
    and and84(c8[4], p[7], p[6], p[5], p[4], g[3]);
    and and85(c8[5], p[7], p[6], p[5], g[4]);
    and and86(c8[6], p[7], p[6], g[5]);
    and and87(c8[7], p[7], g[6]);
    or  or8(Gen, g[7], c8[7], c8[6], c8[5], c8[4], c8[3], c8[2], c8[1], c8[0]);
    and PropAnd(Prop, p[7], p[6], p[5], p[4], p[3], p[2], p[1], p[0]);

    // reuse g,p for bitwise and & or
    assign BAnd[7:0] = {g[7], g[6], g[5], g[4], g[3], g[2], g[1], g[0]};
    assign BOr[7:0] = {p[7], p[6], p[5], p[4], p[3], p[2], p[1], p[0]};

    generate
        for(i = 0; i < 8; i = i + 1) begin
            xor sumxor(Sum[i], A[i], B[i], carry[i]);
        end
    endgenerate

endmodule

module negator(dataOut, dataIn);
    output[31:0] dataOut;
    input[31:0] dataIn;

    cla_32 cla(.A(~dataIn), .B(32'b0), .Cin(1'b1), .Sum(dataOut));
endmodule

module full_adder(S, Cout, A, B, Cin);
    input A, B, Cin;
    output S, Cout;
    wire w1, w2, w3;
    
    xor sum(S, A, B, Cin);
    and AND1(w1, A, B);
    and AND2(w2, B, Cin);
    and AND3(w3, Cin, A);
    or carry(Cout, w1, w2, w3);
endmodule

module half_adder(S, Cout, A, B);
    input A, B;
    output S, Cout;

    and(Cout, A, B);
    xor(S, A, B);
endmodule