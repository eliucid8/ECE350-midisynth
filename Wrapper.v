`timescale 1ns / 1ps
/**
 * 
 * READ THIS DESCRIPTION:
 *
 * This is the Wrapper module that will serve as the header file combining your processor, 
 * RegFile and Memory elements together.
 *
 * This file will be used to generate the bitstream to upload to the FPGA.
 * We have provided a sibling file, Wrapper_tb.v so that you can test your processor's functionality.
 * 
 * We will be using our own separate Wrapper_tb.v to test your code. You are allowed to make changes to the Wrapper files 
 * for your own individual testing, but we expect your final processor.v and memory modules to work with the 
 * provided Wrapper interface.
 * 
 * Refer to Lab 5 documents for detailed instructions on how to interface 
 * with the memory elements. Each imem and dmem modules will take 12-bit 
 * addresses and will allow for storing of 32-bit values at each address. 
 * Each memory module should receive a single clock. At which edges, is 
 * purely a design choice (and thereby up to you). 
 * 
 * You must change line 36 to add the memory file of the test you created using the assembler
 * For example, you would add sample inside of the quotes on line 38 after assembling sample.s
 *
 **/

module Wrapper (CLK100MHZ, CPU_RESETN, sevenseg, AN, manual_clock, SW, LED, JA, AUDIO_CLOCK);
	input CLK100MHZ, CPU_RESETN, AUDIO_CLOCK;
	input[11:0] JA;
	output [15:0] LED;
	output[7:0] sevenseg, AN;
	wire reset = ~CPU_RESETN;
	
	reg clock50mhz, clk1khz, clock_audio;
	reg clk50_divider;
	reg[16:0] clock_div16_counter;
	localparam clock_div16_limit = 17'd100000;
	always @(posedge CLK100MHZ) begin
		clock50mhz <= ~clock50mhz;
		if(clock_div16_counter < clock_div16_limit) begin
			clock_div16_counter <= clock_div16_counter + 1;
		end else begin
			clock_div16_counter <= 17'd0;
			clk1khz <= ~clk1khz;
		end
	end

	assign LED[0] = clk1khz;

	input manual_clock, SW;

	wire debounced_man_clock;
	debouncer clock_debouncer(.debounced(debounced_man_clock), .sig(manual_clock), .clock(clock50mhz));
	assign LED[1] = debounced_man_clock;

	wire clock = SW ? debounced_man_clock : clock50mhz;

	wire rwe, mwe, mem_read_enable;
	wire[4:0] rd, rs1, rs2;
	wire[31:0] instAddr, instData, 
		rData, regA, regB,
		memAddr, memDataIn, memDataOut, memDataResult;
	wire sevenseg_writeEnable;
	wire[31:0] sevenseg_data;


	// ADD YOUR MEMORY FILE HERE
	localparam INSTR_FILE = "matmul";
	
	// Main Processing Unit
	processor CPU(.clock(clock), .reset(reset), 
								
		// ROM
		.address_imem(instAddr), .q_imem(instData),
									
		// Regfile
		.ctrl_writeEnable(rwe),     .ctrl_writeReg(rd),
		.ctrl_readRegA(rs1),     .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB),
									
		// RAM
		.wren(mwe), .address_dmem(memAddr), .mem_ren(mem_read_enable),
		.data(memDataIn), .q_dmem(/* memDataOut */memDataResult),
		
		.sevenseg_writeEnable(sevenseg_writeEnable), .sevenseg_data(sevenseg_data)); 
	
	// Instruction Memory (ROM)
	ROM #(.MEMFILE({INSTR_FILE, ".mem"}))
	InstMem(.clk(clock), 
		.addr(instAddr[11:0]), 
		.dataOut(instData));
	
	// Register File
	regfile RegisterFile(.clock(clock), 
		.ctrl_writeEnable(rwe), .ctrl_reset(reset), 
		.ctrl_writeReg(rd),
		.ctrl_readRegA(rs1), .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB));
						
	// Processor Memory (RAM)
	RAM ProcMem(.clk(clock), 
		.wEn(mwe), 
		.addr(memAddr[11:0]), 
		.dataIn(memDataIn), 
		.dataOut(memDataOut));

	// ====io====
	reg[31:0] sevenseg_latch;
	initial begin
		sevenseg_latch = 32'd0;
	end

	sevenseg_controller sevenseg_ctrl(.downclock(clk1khz), .word(sevenseg_latch), .segments(sevenseg), .enables(AN));

	always @(posedge clock or posedge reset) begin
		if(reset) begin
			sevenseg_latch <= 32'd0;
		end else if(sevenseg_writeEnable) begin
			sevenseg_latch <= sevenseg_data;
		end
	end

	// ====Memory-Mapped I/O (like a real computer)====
	wire do_mmio = mem_read_enable && (memAddr > 32'h1fff);
	wire [31:0] mmio_result;
	assign memDataResult = do_mmio ? mmio_result : memDataOut;

	localparam 
		MMIO_XORSHIFT = 32'h2328; // 9000

	// xorshift
	wire[31:0] rng_result;
	wire next_rng = mem_read_enable && memAddr == MMIO_XORSHIFT; // hex address 1388
	xorshift #(.SEED(32'hdeadbeef)) xorshift_rng(.rand(rng_result), .next(next_rng), .clock(clock));
	assign mmio_result = next_rng ? rng_result : 32'hfbadc0de; // FIX: will get ugly pretty soon. behavioral base/bounds? CAM?

endmodule
