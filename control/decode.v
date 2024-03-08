module insn_decode #(
    parameter NUM_CTRL = 12
) 
(
    opcode, ctrlbus
);
    // localparam NUM_CTRL = 12;

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

    // mem_WE:
    assign ctrlbus[4] = insns[7];

    // alu_imm (use something other than rt for alu input b)
    assign ctrlbus[5] = |{insns[5], insns[7], insns[8]};

    // ALU_op
    assign ctrlbus[6] = |{insns[2], insns[6]};
    assign ctrlbus[10:7] = 4'b0;
    
    // use aluop
    assign ctrlbus[11] = |{insns[5], insns[7], insns[8], insns[2], insns[6]};

endmodule