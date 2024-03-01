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
    // Fetch
    wire[31:0] next_pc;

    cla_32 pc_increment(.A(address_imem), .B(32'b1), .Cin(1'b0), .Sum(next_pc));

    register #(32) pc(
        .clk(clock), .writeEnable(1'b1), .reset(reset), .dataIn(next_pc), .dataOut(address_imem)
    );


    // Decode
    wire[4:0] opcode, rd, rs, rt, shamt, insnALUop;
    wire[31:0] immed;
    wire[26:0] jump_target;
    assign opcode =         q_imem[31:27];
    assign rd =             q_imem[26:22];
    assign rs =             q_imem[21:17];
    assign rt =             q_imem[16:12];
    assign shamt =          q_imem[11:7];
    assign insnALUop =          q_imem[6:2];
    assign immed =          {{15{q_imem[16]}}, {q_imem[16:0]}};
    assign jump_target =    {5'b0, q_imem[26:0]};

    assign ctrl_readRegA = rs;
    assign ctrl_readRegB = rt;

    // TODO: Change this when modifying ISA!
    wire[9:0] ctrlbus;
	insn_decode insn_decoder(.opcode(opcode), .ctrlbus(ctrlbus));

    // eXecute
    wire[31:0] alu_inB;
    assign alu_inB = ctrlbus[3] ? immed : data_readRegB;

    wire[31:0] alu_result;
    wire ALU_ne, ALU_lt, ALU_ovf;

    // select between aluop in insn, or aluop provided by control.
    wire[4:0] ALUop;
    assign ALUop = ctrlbus[9] ? ctrlbus[8:4] : insnALUop;

    alu alu(
        .data_operandA(data_readRegA), .data_operandB(alu_inB), .ctrl_ALUopcode(ALUop), 
        .ctrl_shiftamt(shamt), .data_result(alu_result), 
        .isNotEqual(ALU_ne), .isLessThan(ALU_lt), .overflow(ALU_ovf)
    );

    // TODO: Memory


    // Writeback
    mux4 #(.WIDTH(5)) writeRegMux(ctrl_writeReg, ctrlbus[1:0], rd, 5'bx, 5'd30, 5'd31);
    assign ctrl_writeEnable = ctrlbus[2];
    assign data_writeReg = alu_result;

	/* END CODE */

endmodule
