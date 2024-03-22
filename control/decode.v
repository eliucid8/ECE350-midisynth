module insn_decode #(
    parameter NUM_CTRL = 12
) 
(
    opcode, ctrlbus
);
    // TODO: Fold ALUOP into this as well???
    localparam 
        ADD = 0,
        J = 1,
        BNE = 2,
        JAL = 3,
        JR = 4,
        ADDI = 5,
        BLT = 6,
        SW = 7,
        LW = 8,
        SETX = 21,
        BEX = 22;

    input [4:0] opcode;
    /** Ideally, we order these so that the last ctrl signals used are the smallest just to avoid awkward shifts in the IR regs.
     * ctrlbus[1:0]:    wb_dst (writeback destination)
     * ctrlbus[2]:      reg_WE
     * ctrlbus[3]:      use_mem
     * ctrlbus[4]:      mem_WE
     * ctrlbus[5]:      alu_imm (alu_inb)
     * ctrlbus[10:6]:   calcALUop
     * ctrlbus[11]:     use_calc_ALUop
     * ctrlbus[12]:     rtin (use rd if high)
     * ctrlbus[13]:     jr
     * ctrlbus[14]:     branch
     * ctrlbus[15]:     use_non_PC 
     * ctrlbus[16]:     jal
     */
    output[NUM_CTRL-1:0] ctrlbus;

    // may be better to do this with combinational after cpu is largely built up.
    wire[31:0] insns;
    decoder32 insn_decoder (.out(insns), .select(opcode), .enable(1'b1));

    // writeback destination
    assign ctrlbus[0] = |{insns[1], insns[2], insns[3], insns[4], insns[6], insns[22]};
    assign ctrlbus[1] = |{insns[3], insns[21]};
    
    // reg_WE: 
    assign ctrlbus[2] = |{insns[0], insns[3], insns[5], insns[8], insns[21]};

    // use_mem:
    assign ctrlbus[3] = insns[8];

    // SW (mem_WE, bypass_WM):
    assign ctrlbus[4] = insns[SW];

    // alu_imm (use something other than rt for alu input b)
    assign ctrlbus[5] = |{insns[5], insns[7], insns[8]};

    // ALU_op
    assign ctrlbus[6] = |{insns[2], insns[6]};
    assign ctrlbus[10:7] = 4'b0;
    
    // use aluop
    assign ctrlbus[11] = |{insns[5], insns[7], insns[8], insns[2], insns[6]};

    // rtin:
    assign ctrlbus[12] = |{insns[SW], insns[JR], insns[BLT], insns[BNE]};

    // jr:
    assign ctrlbus[13] = insns[JR];

    // branch:
    assign ctrlbus[14] = |{insns[BNE], insns[BLT]};

    // use_non_PC:
    assign ctrlbus[15] = |{insns[J], insns[BNE], insns[JAL], insns[JR], insns[BLT], insns[BEX]};

    // jal:
    assign ctrlbus[16] = insns[JAL];

    // blt:
    assign ctrlbus[17] = insns[BLT];

    // bex:
    assign ctrlbus[18] = insns[BEX];
    
    // setx:
    assign ctrlbus[19] = insns[SETX];

    // add_insn:
    assign ctrlbus[20] = |{insns[ADD], insns[ADDI]};

    // addi:
    assign ctrlbus[21] = insns[ADDI];

    // bypassA
    assign ctrlbus[22] = ~|{insns[J], insns[JAL], insns[JR], insns[SETX]};
    
    // bypassB
    assign ctrlbus[23] = |{insns[ADD], insns[ADDI], insns[BNE], insns[JR], insns[BLT], insns[SW]};

    // lw
    assign ctrlbus[24] = insns[LW];
endmodule

// TODO: Is it bad to have these unecessary wires hardwired to 0???
module exceptionmap(rstatus, ALUop, addi, allow_except);
    input[4:0] ALUop;
    input addi;
    output[31:0] rstatus;
    output allow_except;

    assign rstatus[31:3] = 29'b0;
    assign rstatus[0] = (!(ALUop[2]) || (ALUop[1] && ALUop[0])) && !addi;
    assign rstatus[1] = (!(ALUop[1]) && ALUop[0]) || addi;
    assign rstatus[2] = ALUop[1];
    assign allow_except = (!ALUop[1] || ALUop[2]) && (ALUop[0] || ALUop[1] || !ALUop[2]);
endmodule