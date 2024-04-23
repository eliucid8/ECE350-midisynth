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

module Wrapper (CLK100MHZ, CPU_RESETN, sevenseg, AN, manual_clock, SW, LED, JA, JB, JC, JD, AUD_PWM, AUD_SD);
	input CLK100MHZ, CPU_RESETN;
	input[7:0] JA;
	inout[7:0] JC;
	output[7:0] JB, JD;
	input[15:0] SW;
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

	wire debounced_man_clock;
	debouncer clock_debouncer(.debounced(debounced_man_clock), .sig(manual_clock), .clock(clock50mhz));

	wire clock = /* SW[0] ? debounced_man_clock : */ clock50mhz;

	wire rwe, mwe, mem_read_enable;
	wire[4:0] rd, rs1, rs2;
	wire[31:0] instAddr, instData, 
		rData, regA, regB,
		mem_addr, memDataIn, memDataOut, memDataResult;
	wire sevenseg_writeEnable;
	wire[31:0] sevenseg_data;


	// ADD YOUR MEMORY FILE HERE
	localparam INSTR_FILE = "dct";
	
	// Main Processing Unit
	processor CPU(.clock(clock), .reset(reset), 
								
		// ROM
		.address_imem(instAddr), .q_imem(instData),
									
		// Regfile
		.ctrl_writeEnable(rwe),     .ctrl_writeReg(rd),
		.ctrl_readRegA(rs1),     .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB),
									
		// RAM
		.wren(mwe), .address_dmem(mem_addr), .mem_ren(mem_read_enable),
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
		.addr(mem_addr[11:0]), 
		.dataIn(memDataIn), 
		.dataOut(memDataOut));

	// ====io====
	reg[31:0] sevenseg_latch;
	initial begin
		sevenseg_latch = 32'd0;
	end


	// ====seven-segment====
	sevenseg_controller sevenseg_ctrl(.downclock(clk1khz), .word(sevenseg_latch), .segments(sevenseg), .enables(AN));
	wire[31:0] sevenseg_override;
	always @(posedge clock/*  or posedge reset */) begin
		if(reset) begin
			sevenseg_latch <= 32'd0;
		end else if(/* sevenseg_writeEnable */ 0 == 0) begin
			sevenseg_latch <= /* sevenseg_data */ sevenseg_override ; // FIX: temp debug values
		end
	end

	// ====Memory-Mapped I/O (like a real computer)====
	wire do_mmio = mem_read_enable && (mem_addr > 32'h1fff);
	wire [31:0] mmio_result;
	assign memDataResult = do_mmio ? mmio_result : memDataOut;

	wire[31:0] midi_result;
	wire midi_in_port;
	wire midi_busy_reading;
	wire[15:0] audio_buffer_write_val;
	wire write_audio_buffer;
	mmio mamma_mmio(
		.mmio_result(mmio_result), .midi_result(midi_result), .midi_busy_reading(midi_busy_reading),
		.clock(clock), .mem_addr(mem_addr), .mem_read_enable(mem_read_enable),
		.midi_data(midi_in_port), .audio_buffer_write_val(audio_buffer_write_val), .write_audio_buffer(write_audio_buffer),
		.audio_buff_ready(JA[4])
	);

	reg[3:0] dct_result_counter;
	wire[15:0] dct_result;
	reg[3:0] dct_result_array[15:0];
	dct_result_regs dct_regs(
		.dct_result(dct_result), .clock(clock), .read_index(dct_result_counter), 
		.mem_write_enable(mwe), .mem_addr(mem_addr), .mem_write_data(memDataIn)
	);
	
	always @(posedge clock) begin
		dct_result_array[dct_result_counter] <= dct_result[14:11];
		dct_result_counter <= dct_result_counter + 1;
	end

	assign sevenseg_override = SW[2] ? {dct_result_array[15], dct_result_array[14], dct_result_array[13], dct_result_array[12], dct_result_array[11], dct_result_array[10], dct_result_array[9], dct_result_array[8]} : {dct_result_array[7], dct_result_array[6], dct_result_array[5], dct_result_array[4], dct_result_array[3], dct_result_array[2], dct_result_array[1], dct_result_array[0]};

	wire[15:0] audio_data_test;
	wire [15:0] poly_audio_value;
	wire word_clock_monitor;
	wire data_audio_out;
	wire wrise, wfall;


	i2s eyetwo(.sys_clock(clock), .reset(1'b0), .bit_clock(audio_clock),
    .audio_data(SW[1] ? poly_audio_value : audio_data_test),
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
	wire[15:0] square_val, saw_val, sin_val, tri_val;
	reg[31:0] lut_index, bent_inc_rate;
	reg[28:0] inc_rate, inc_rate_delta;
	initial begin
		lut_index <= 32'b0;
		inc_rate <= 0;
	end

	square_lut square_lutty(.value(square_val), .index(lut_index[31:16]));
	saw_lut saw_lutty(.value(saw_val), .index(lut_index[31:16]));
	sin_lut sin_lutty(.value(sin_val), .index(lut_index[31:16]));
	tri_lut tri_lutty(.value(tri_val), .index(lut_index[31:16]));
	
	wire double_word_clock;

	wire[15:0] inc_display;
	wire[7:0] pitch_display;
	wire[31:0] amplitude_display;
	polyphonizer soundinator(
		.clock(clock), .double_word_clock(double_word_clock), .midi_busy(midi_busy_reading), 
		.midi_result(midi_result), .audio_value(poly_audio_value), .SW(SW), .inc_display(inc_display), .pitch_display(pitch_display),
		.running_dword(JB[4]), .running_midi(JB[5]), .amplitude_display(amplitude_display), .reset(reset)
	);

	// assign sevenseg_override = SW[13] ? amplitude_display : {midi_note, pitch_display, inc_display};

	sys_counter_wide #(7) dble_word_clock(~audio_clock, 1'b0, double_word_clock); //weird but its on the not, i know right
	always @(negedge double_word_clock) begin
		if(reset) begin
			lut_index <= 32'b0;
		end else begin
			lut_index <= lut_index + bent_inc_rate;
		end
	end

	reg[20:0] freq_div;
	reg[7:0] cur_midi_note;

	always @(posedge clock) begin
		if(reset) begin
			inc_rate <= 0;
			bent_inc_rate <= 0;
		end else if(midi_status == 4'h9) begin // \note on
			freq_div <= FREQs[midi_note - 8'd21];
			inc_rate_delta <= inc_rates[midi_note - 8'd20] - inc_rates[midi_note - 8'd21];
			cur_midi_note <= midi_note;
			inc_rate = inc_rates[midi_note - 8'h15];
			bent_inc_rate = inc_rate;
			// wave_hi <= (midi_velocity[6:0] << 8);
			// wave_lo <= 16'hffff - (midi_velocity[6:0] << 8);
		end else if (midi_status == 4'h8) begin // \note off
			if(midi_note == cur_midi_note) begin
				freq_div <= 0;
				inc_rate <= 0;
				bent_inc_rate <= 0;
			end
		end else if (midi_status == 4'he)begin
			if(midi_velocity >= 8'h40) begin
				bent_inc_rate <= inc_rate + (((midi_velocity - 8'h40) * inc_rate_delta) >> 4);
			end else begin
				bent_inc_rate <= inc_rate - (((8'h40 - midi_velocity) * inc_rate_delta) >> 4);
			end
		end
	end

	sys_counter_freq #(50000000) freq_counter(CLK100MHZ, 1'b0, freq_div, square_wave);

	wire [15:0] big_pwm_out = SW[1] ? poly_audio_value : audio_data_test;
	wire [11:0] pwm_val_out = {~big_pwm_out[15], big_pwm_out[14:4]}; 
	sys_counter_pwm #(4096) bodge_pwm(clock, 1'b0, pwm_val_out, bodge_pwm_out);
	assign AUD_PWM = bodge_pwm_out;

	mux4 #(16) waveform_mux(
		.out(audio_data_test), .sel(SW[15:14]), 
		.in0(square_val), .in1(saw_val), .in2(sin_val), .in3(tri_val));

	assign audio_buffer_write_val = poly_audio_value;
	reg prev_word_clock, word_clock_edge;
	always @(posedge clock) begin
		prev_word_clock <= word_clock_monitor;
		word_clock_edge <= prev_word_clock ^ word_clock_monitor;
	end
	assign write_audio_buffer = word_clock_edge; // fuck I could've used a sys_counter here

	assign JB[0] = midi_busy_reading;
	assign JB[1] = midi_in_port;
	assign JB[2] = bodge_pwm_out;
	assign JB[3] = double_word_clock;

	assign midi_in_port = JC[0];
	assign JC[2] = write_audio_buffer;

	assign JD[5] = word_clock_monitor;
	assign JD[2] = audio_clock;
	assign JD[1] = data_audio_out;

endmodule
