module alu(
    data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, 
    data_result, isNotEqual, isLessThan, overflow, 
    clock, result_rdy
);
    input [31:0] data_operandA, data_operandB;
    input [4:0] ctrl_ALUopcode, ctrl_shiftamt;
    input clock;

    output [31:0] data_result;
    output isNotEqual, isLessThan, overflow, result_rdy;

    wire Cout;
    wire[7:0] alu_ctrl;
    /* 000 - add
     * 001 - subtract
     * 010 - and
     * 011 - or
     * 100 - sll
     * 101 - sra
     * 110 - mul
     * 111 - div
     */

    wire[31:0] B_not, B_adder_input;
    // outputs right before big mux at end
    wire[31:0] add_output, and_output, or_output, sll_output, sra_output;

    // instruction decoding: liable to change with more additions to ISA?
    // We technically only need to know alu_ctrl atm... but perhaps that will change.
    decoder_8 insn_dec(alu_ctrl, ctrl_ALUopcode[2:0]);

    // creating negative b
    bitwise_not bitnot(B_not, data_operandB);
    mux_2 negative_decider(B_adder_input, alu_ctrl[1], data_operandB, B_not);

    // the main event: adder, ander, and orer
    cla_32 adder(
        .A(data_operandA), .B(B_adder_input), .Cin(alu_ctrl[1]),
        .Sum(add_output), .Cout(Cout),
        .BAnd(and_output), .BOr(or_output)
        );

    wire[31:0] md_result;
    wire md_except, md_ready, div_pulsed, ctrl_div;
    // edgedetector div_edge(.out(divide_pulse), .clock(clock), .sig(alu_ctrl[7]));
    dffe_ref div_pulse_latch(.q(div_pulsed), .d(alu_ctrl[7] && !md_ready), .clk(clock), .en(1'b1), .clr(1'b0));
    assign ctrl_div = alu_ctrl[7] && !div_pulsed;

    multdiv multdiv(
        .data_operandA(data_operandA), .data_operandB(data_operandB),
        .ctrl_MULT(alu_ctrl[6]), .ctrl_DIV(ctrl_div), .shift16(ctrl_ALUopcode[3]),
        .clock(clock),
        .data_result(md_result), .data_exception(md_except), .data_resultRDY(md_ready)
    );

    // result_rdy: hardwired to on unless we are dividing.
    // shouldn't need to latch the fact that we are dividing if we stall the current insn.
    assign result_rdy = (!alu_ctrl[7]) || md_ready;

    // shifters!
    left_barrel_shifter     sll(sll_output, data_operandA, ctrl_shiftamt);
    right_barrel_shifter    sra(sra_output, data_operandA, ctrl_shiftamt);

    // mux everything back together!
    // could be done with tristates as well, because we've already used a decoder?
    mux_8 output_decider(
        data_result, ctrl_ALUopcode[2:0], 
        add_output, add_output, and_output, or_output, 
        sll_output, sra_output, md_result, md_result
        );

    // overflow checker
    // TODO: minimize boolean logic?
    wire Asign, Bsign, Csign;
    wire Asbar, Bsbar, Csbar, ovfSOP1, ovfSOP2, add_ovf;

    assign Asign = data_operandA[31];
    assign Bsign = B_adder_input[31];
    assign Csign = data_result[31];
    not ovfNot1(Asbar, Asign);
    not ovfNot2(Bsbar, Bsign);
    not ovfNot3(Csbar, Csign);

    and ovfAnd1(ovfSOP1, Csbar, Asign, Bsign);
    and ovfAnd2(ovfSOP2, Csign, Asbar, Bsbar);
    or  ovfOr(add_ovf, ovfSOP1, ovfSOP2);

    assign overflow = (alu_ctrl[6] || alu_ctrl[7]) ? md_except : add_ovf;

    // not equal: ie A - B != 0 => or all inputs of A-B together
    or_32 ne_check(isNotEqual, add_output);

    // less than: A < B => A - B < 0, so we are looking for a sign bit 1. However, if we overflow, that means the result is reversed, because the sign of the end result is opposite what it would actually be if we had extra room.
    xor le_check(isLessThan, add_output[31], add_ovf);
endmodule