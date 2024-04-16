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

module Wrapper (CLK100MHZ, CPU_RESETN, sevenseg, AN, manual_clock, SW, LED, JA, JB, JC, AUD_PWM, AUD_SD);
	input CLK100MHZ, CPU_RESETN;
	input[7:0] JA;
	output[7:0] JB, JC;
	output [15:0] LED;
	output[7:0] sevenseg, AN;
	output AUD_PWM, AUD_SD;
	wire reset = ~CPU_RESETN;
	
	reg clock50mhz, clk1khz;
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
	
	wire audio_clock, CLK_9600KHZ;
	AUDIO_CLOCK PLEASEPLEASEPLL(.audio_clock(CLK_9600KHZ), .reset(1'b0), .clk_in1(CLK100MHZ));
	// The frequency is divided by an extra factor of 2 when using sys_counter wide.
    sys_counter_wide #(3) downaudio(.clock(CLK_9600KHZ), .clr(1'b0), .down_clock(audio_clock));

	input manual_clock; 
	input[15:0] SW;

	wire debounced_man_clock;
	debouncer clock_debouncer(.debounced(debounced_man_clock), .sig(manual_clock), .clock(clock50mhz));

	wire clock = SW[0] ? debounced_man_clock : clock50mhz;

	wire rwe, mwe, mem_read_enable;
	wire[4:0] rd, rs1, rs2;
	wire[31:0] instAddr, instData, 
		rData, regA, regB,
		memAddr, memDataIn, memDataOut, memDataResult;
	wire sevenseg_writeEnable;
	wire[31:0] sevenseg_data;


	// ADD YOUR MEMORY FILE HERE
	localparam INSTR_FILE = "basic_midi";
	
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


	// ====seven-segment====
	sevenseg_controller sevenseg_ctrl(.downclock(clk1khz), .word(sevenseg_latch), .segments(sevenseg), .enables(AN));

	always @(posedge clock/*  or posedge reset */) begin
		if(reset) begin
			sevenseg_latch <= 32'd0;
		end else if(sevenseg_writeEnable) begin
			sevenseg_latch <= sevenseg_data; // FIX: temp debug values: wave_val
		end
	end

	// ====Memory-Mapped I/O (like a real computer)====
	wire do_mmio = mem_read_enable && (memAddr > 32'h1fff);
	wire [31:0] mmio_result;
	assign memDataResult = do_mmio ? mmio_result : memDataOut;

	wire[31:0] midi_result;
	wire midi_busy_reading;
	mmio mamma_mmio(.mmio_result(mmio_result), .midi_result(midi_result), .midi_busy_reading(midi_busy_reading),
		.clock(clock), .memAddr(memAddr), .mem_read_enable(mem_read_enable), .midi_data(JA[3])
	);

	wire[15:0] audio_data_test;
	wire word_clock_monitor;
	wire data_audio_out;
	wire wrise, wfall;

	i2s eyetwo(.sys_clock(clock), .reset(1'b0), .bit_clock(audio_clock),
    .audio_data(audio_data_test),
    .word_clock(word_clock_monitor), .data_bit(data_audio_out),
	.wrise(wrise), .wfall(wfall)
    );

	wire square_wave, bodge_pwm_out;

	// FIX: AUDIO BODGE
	wire[3:0] midi_status, midi_channel;
	wire[7:0] midi_note, midi_velocity;
	assign midi_status = midi_result[23:20];
	assign midi_note = midi_result[15:8];
	assign midi_velocity = midi_result[7:0];


	assign AUD_SD = 1'b1;
	reg[20:0] FREQs[95:0];
	initial begin
		$readmemh("freq_divs.mem", FREQs);
	end

	reg[28:0] inc_rates[95:0];
	initial begin
		$readmemh("inc_rates.mem", inc_rates);
	end

	// Lookup table bodge
	reg[15:0] wave_val;
	wire[15:0] square_val, saw_val, sin_val;
	reg[31:0] lut_index;
	reg[28:0] inc_rate;
	square_lut be_there_or_be_square(.value(square_val), .index(lut_index[31:16]));
	saw_lut see_what_you_saw(.value(saw_val), .index(lut_index[31:16]));
	sin_lut derogatory_slur(.value(sin_val), .index(lut_index[31:16]));
	
	wire wave_select = SW[15];
	wire double_word_clock;

	initial begin
		lut_index <= 32'b0;
		inc_rate <= 0;
		wave_val <= 0;
	end

	sys_counter_wide #(7) double_word_clock(~audio_clock, 1'b0, double_word_clock); //weird but its on the not, i know right
	always @(negedge double_word_clock) begin
		lut_index <= lut_index + inc_rate;
		wave_val <= wave_select ? saw_val : square_val;
	end
	

	reg[20:0] freq_div;
	reg[7:0] cur_midi_note;
	reg [15:0] wave_hi, wave_lo;

	always @(posedge clock) begin
		if(midi_status == 4'h9) begin // \note on
			freq_div <= FREQs[midi_note - 8'h15];
			inc_rate <= inc_rates[midi_note - 8'h15];
			cur_midi_note <= midi_note;
			wave_hi <= (midi_velocity[6:0] << 8);
			wave_lo <= 16'hffff - (midi_velocity[6:0] << 8);
		end else if (midi_status == 4'h8) begin // \note off
			if(midi_note == cur_midi_note) begin
				freq_div <= 0;
				inc_rate <= 0;
			end
		end
	end

	sys_counter_freq #(50000000) freq_counter(CLK100MHZ, 1'b0, freq_div, square_wave);

	wire[7:0] square_pwm = square_wave ? 8'h6f: 8'h10;
	sys_counter_pwm #(256) bodge_pwm(clock, 1'b0, square_pwm, bodge_pwm_out);
	assign AUD_PWM = bodge_pwm_out;
	assign audio_data_test = SW[14] ? wave_val[15:0] : sin_val;
	// assign audio_data_test = square_wave ? wave_hi : wave_lo;

	assign JB[0] = wrise;
	assign JB[1] = wfall;
	assign JB[2] = square_wave;
	assign JB[3] = double_word_clock;

	assign JC[0] = audio_clock;
	assign JC[1] = audio_clock;
	assign JC[2] = data_audio_out;
	assign JC[3] = word_clock_monitor;
	assign JC[4] = audio_clock;
	assign JC[5] = audio_clock;
	assign JC[6] = data_audio_out;
	assign JC[7] = word_clock_monitor;
endmodule
