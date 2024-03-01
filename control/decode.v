module insn_decode(
    opcode, ctrlbus
);
    localparam num_ctrl = 10;

    input [4:0] opcode;
    /** Ideally, we order these so that the last ctrl signals used are the smallest just to avoid awkward shifts in the IR regs.
     * ctrlbus[1:0]:    wb_dst (writeback destination)
     * ctrlbus[2]:      reg_WE
     * ctrlbus[3]:      alu_imm (alu_inb)
     * ctrlbus[8:4]:    calcALUop
     * ctrlbus[9]:      use_calc_ALUop
     */
    output[num_ctrl-1:0] ctrlbus;

    // may be better to do this with combinational after cpu is largely built up.
    wire[31:0] insns;
    decoder32 insn_decoder (.out(insns), .select(opcode), .enable(1'b1));

    // writeback destination
    assign ctrlbus[0] = |{insns[1], insns[2], insns[3], insns[4], insns[6], insns[22]};
    assign ctrlbus[1] = |{insns[3], insns[21]};
    
    // reg_WE: 
    assign ctrlbus[2] = |{insns[0], insns[3], insns[5], insns[8], insns[21]};

    // alu_imm (use something other than rt for alu input b)
    assign ctrlbus[3] = |{insns[5], insns[7], insns[8]};

    // ALU_op
    assign ctrlbus[4] = |{insns[2], insns[6]};
    assign ctrlbus[8:5] = 4'b0;
    
    // use aluop
    assign ctrlbus[9] = |{insns[5], insns[7], insns[8], insns[2], insns[6]};

endmodule