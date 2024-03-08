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
    localparam NUM_CTRL = 12;


    // ========Fetch========
    wire[31:0] next_pc;

    cla_32 pc_increment(.A(address_imem), .B(32'b1), .Cin(1'b0), .Sum(next_pc));

    register #(32) pc(
        .clk(clock), .writeEnable(1'b1), .reset(reset), .dataIn(next_pc), .dataOut(address_imem)
    );

    wire[63:0] FDIR;
    register #(64) FDIRlatch(
        .clk(!clock), .writeEnable(1'b1), .reset(reset), .dataIn({next_pc, q_imem}), .dataOut(FDIR)
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

    //rtin = mem_we = Dctrlbus[4]
    assign ctrl_readRegB = Dctrlbus[4] ? rd : rt;

    // TODO: Change this when modifying Control!
    wire[NUM_CTRL-1:0] Dctrlbus;
	insn_decode #(NUM_CTRL) insn_decoder(.opcode(opcode), .ctrlbus(Dctrlbus));

    wire [NUM_CTRL+127:0] DXIR;
    register #(128 + NUM_CTRL) DXIRlatch(
        .clk(!clock), .writeEnable(1'b1), .reset(reset), .dataIn({Dctrlbus, data_readRegA, data_readRegB, FDIR}), .dataOut(DXIR)
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

    alu alu(
        .data_operandA(XA), .data_operandB(alu_inB), .ctrl_ALUopcode(ALUop), 
        .ctrl_shiftamt(Xshamt), .data_result(alu_result), 
        .isNotEqual(ALU_ne), .isLessThan(ALU_lt), .overflow(ALU_ovf)
    );

    wire[NUM_CTRL+95:0] XMIR;
    register #(NUM_CTRL + 96) XMIRlatch(
        .clk(!clock), .writeEnable(1'b1), .reset(reset), .dataIn({Xctrlbus, XB, alu_result, Xinsn}), .dataOut(XMIR)
    );
    
    // TODO: ========Memory========
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

    // Writeback
    wire [NUM_CTRL-1:0] Wctrlbus = MWIR[NUM_CTRL+63:64];
    wire [31:0] Winsn = MWIR[31:0];

    mux4 #(.WIDTH(5)) writeRegMux(ctrl_writeReg, Wctrlbus[1:0], Winsn[26:22], 5'bx, 5'd30, 5'd31);
    assign ctrl_writeEnable = Wctrlbus[2];
    assign data_writeReg = MWIR[63:32];

	/* END CODE */

endmodule
