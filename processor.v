/**
 * READ THIS DESCRIPTION!
 *
 * This is your processor module that will contain the bulk of your code submission. You are to implement
 * a 5-stage pipelined processor in this module, accounting for hazards and implementing bypasses as
 * necessary.
 *
 * Ultimately, your processor will be tested by a master skeleton, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file, Wrapper.v, acts as a small wrapper around your processor for this purpose. Refer to Wrapper.v
 * for more details.
 *
 * As a result, this module will NOT contain the RegFile nor the memory modules. Study the inputs 
 * very carefully - the RegFile-related I/Os are merely signals to be sent to the RegFile instantiated
 * in your Wrapper module. This is the same for your memory elements. 
 *
 *
 */

/**
 * Ye Olde TODO List
 * TODO: j
 * TODO: jr
 * TODO: jal
 * TODO: mul
 * TODO: div
 * TODO: bne
 * TODO: blt
 * TODO: setx
 * TODO: bex
 */

module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for RegFile
    ctrl_writeReg,                  // O: Register to write to in RegFile
    ctrl_readRegA,                  // O: Register to read from port A of RegFile
    ctrl_readRegB,                  // O: Register to read from port B of RegFile
    data_writeReg,                  // O: Data to write to for RegFile
    data_readRegA,                  // I: Data from port A of RegFile
    data_readRegB                   // I: Data from port B of RegFile
	);

	// Control signals
	input clock, reset;
	
	// Imem
    output [31:0] address_imem;
	input [31:0] q_imem;

	// Dmem
	output [31:0] address_dmem, data;
	output wren;
	input [31:0] q_dmem;

	// Regfile
	output ctrl_writeEnable;
	output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	output [31:0] data_writeReg;
	input [31:0] data_readRegA, data_readRegB;

	/* YOUR CODE STARTS HERE */
    // TODO: Change this when modifying Control!
    localparam NUM_CTRL = 17;
    localparam
        wb_dst =            1,
        reg_WE =            2,
        use_mem =           3,
        mem_WE =            4,
        alu_imm =           5,
        calcALUop =         10,
        use_calc_ALUop =    11,
        rtin =              12,
        jr =                13,
        branch =            14,
        use_non_PC =        15,
        jal =               16;

    // ========Fetch========
    wire[31:0] pcp1, next_pc; // pc plus 1
    wire stall_fetch, stall_decode, stall_execute;

    cla_32 pc_increment(.A(address_imem), .B(32'b1), .Cin(1'b0), .Sum(pcp1));

    register #(32) pc(
        .clk(clock), .writeEnable(!stall_fetch), .reset(reset), .dataIn(next_pc), .dataOut(address_imem)
    );

    wire[63:0] FDIR, FDIRin;
    wire flush_FD;
    assign FDIRin = flush_FD ? 64'b0 : {address_imem, q_imem}; // We don't use pc+1 here bc idk, non blocking assignments.
    register #(64) FDIRlatch(
        .clk(!clock), .writeEnable(1'b1), .reset(reset), .dataIn(FDIRin), .dataOut(FDIR)
    );

    // ========Decode========
    wire[31:0] D_insn;
    assign D_insn = FDIR[31:0];
    wire[4:0] opcode, rd, rs, rt, shamt, insnALUop;
    wire[31:0] immed;
    wire[26:0] jump_target;
    assign opcode =         D_insn[31:27];
    assign rd =             D_insn[26:22];
    assign rs =             D_insn[21:17];
    assign rt =             D_insn[16:12];
    assign shamt =          D_insn[11:7];
    assign insnALUop =      D_insn[6:2];
    assign immed =          {{15{D_insn[16]}}, {D_insn[16:0]}};
    assign jump_target =    {5'b0, D_insn[26:0]};

    // rs = 30 when bex.
    assign ctrl_readRegA = rs;

    //rtin 
    assign ctrl_readRegB = Dctrlbus[12] ? rd : rt;

    wire[NUM_CTRL-1:0] Dctrlbus;
	insn_decode #(NUM_CTRL) insn_decoder(.opcode(opcode), .ctrlbus(Dctrlbus));

    wire [NUM_CTRL+127:0] DXIR, DXIRin;
    wire flush_DX;
    assign DXIRin = flush_DX ? {NUM_CTRL+128{1'b0}} : {Dctrlbus, data_readRegA, data_readRegB, FDIR};
    register #(128 + NUM_CTRL) DXIRlatch(
        .clk(!clock), .writeEnable(!stall_decode), .reset(reset), .dataIn(DXIRin), .dataOut(DXIR)
    );

    // ========eXecute========
    wire [NUM_CTRL-1:0] Xctrlbus;
    assign Xctrlbus = DXIR[NUM_CTRL + 127:128];
    wire [31:0] Xinsn;
    assign Xinsn = DXIR[31:0];

    wire[31:0] XA, XB, Ximmed;
    assign XA = DXIR[127:96];
    assign XB = DXIR[95:64];
    assign Ximmed = {{15{Xinsn[16]}}, {Xinsn[16:0]}};

    wire[31:0] alu_inB;
    assign alu_inB = Xctrlbus[5] ? Ximmed : XB;

    wire[31:0] alu_result;
    wire ALU_ne, ALU_lt, ALU_ovf;

    // select between aluop in insn, or aluop provided by control.
    wire[4:0] ALUop, XinsnALUop;
    assign XinsnALUop = Xinsn[6:2];
    assign ALUop = Xctrlbus[11] ? Xctrlbus[10:6] : XinsnALUop;

    wire[4:0] Xshamt;
    assign Xshamt = Xinsn[11:7];
    wire alu_result_ready;

    alu alu(
        .data_operandA(XA), .data_operandB(alu_inB), .ctrl_ALUopcode(ALUop), 
        .ctrl_shiftamt(Xshamt), .data_result(alu_result), 
        .isNotEqual(ALU_ne), .isLessThan(ALU_lt), .overflow(ALU_ovf),
        .clock(clock), .result_rdy(alu_result_ready)
    );

    wire div_stall;
    assign div_stall = (ALUop == 5'b00111) && !alu_result_ready;
    assign stall_fetch = div_stall;
    assign stall_decode = div_stall;
    assign stall_execute = div_stall;


    // ========Branchland========
    wire[31:0] Tsx, jump_addr;
    assign Tsx = {5'b0, {Xinsn[26:0]}};
    assign jump_addr = Xctrlbus[13] ? XB : Tsx;


    wire[31:0] cflow_addr; // control flow address
    assign cflow_addr = Xctrlbus[14] ? 32'b0 : jump_addr;

    wire[31:0] next_no_stall;
    assign next_pc = Xctrlbus[use_non_PC] ? cflow_addr : pcp1;
    assign next_pc = stall_fetch ? address_imem : next_no_stall;

    assign flush_FD = Xctrlbus[use_non_PC];
    assign flush_DX = Xctrlbus[use_non_PC];

    wire[31:0] executeOut;
    assign executeOut = Xctrlbus[jal] ? DXIR[63:32] : alu_result;

    wire[NUM_CTRL+95:0] XMIR, XMIRout, XMIRnop;
    assign XMIRnop = {(NUM_CTRL + 96){1'b0}};

    register #(NUM_CTRL + 96) XMIRlatch(
        .clk(!clock), .writeEnable(!stall_execute), .reset(reset), .dataIn({Xctrlbus, XB, executeOut, Xinsn}), .dataOut(XMIRout)
    );

    assign XMIR = stall_execute ? XMIRnop : XMIRout;
    
    // ========Memory========
    wire[NUM_CTRL-1:0] Mctrlbus;
    assign Mctrlbus = XMIR[NUM_CTRL+95:96];

    assign address_dmem = XMIR[63:32];
    assign wren = Mctrlbus[4];
    assign data = XMIR[95:64];

    wire[31:0] Mresult;
    assign Mresult = Mctrlbus[3] ? q_dmem : address_dmem; // decide between memory result and alu result

    wire[NUM_CTRL + 63:0] MWIR;
    register #(NUM_CTRL + 64) MWIRlatch(
        .clk(!clock), .writeEnable(1'b1), .reset(reset), .dataIn({Mctrlbus, Mresult, XMIR[31:0]}), .dataOut(MWIR)
    );

    // ========Writeback========
    wire [NUM_CTRL-1:0] Wctrlbus = MWIR[NUM_CTRL+63:64];
    wire [31:0] Winsn = MWIR[31:0];

    mux4 #(.WIDTH(5)) writeRegMux(ctrl_writeReg, Wctrlbus[1:0], Winsn[26:22], 5'bx, 5'd30, 5'd31);
    assign ctrl_writeEnable = Wctrlbus[2];
    assign data_writeReg = MWIR[63:32];

	/* END CODE */
endmodule
