module mmio (
    output[31:0] mmio_result,
    output[31:0] midi_result,
    output midi_busy_reading,
    input clock,
    input [31:0] mem_addr,
    input mem_read_enable,
    input midi_data,
	input[15:0] audio_buffer_write_val,
	input write_audio_buffer,
	output audio_buff_ready
);
	localparam 
		MMIO_XORSHIFT = 			32'h2001, // 8193
		MMIO_MIDIIN = 				32'h2002, // 8194
		MMIO_AUDIO_BUFFER_READY = 	32'h2003, // 8195
		MMIO_DCTLUTS = 				32'h4000, // 16384
		MMIO_AUDIO_BUFFER_REGION = 	32'h10000; // -65536 IDEA: eventually, use this region as the audio buffer?

	// xorshift
	wire[31:0] rng_result;
	wire next_rng = mem_read_enable && mem_addr == MMIO_XORSHIFT; // hex address 1388
	xorshift #(.SEED(32'hdeadbeef)) xorshift_rng(.rand(rng_result), .next(next_rng), .clock(clock));
    assign mmio_result = (mem_addr == MMIO_XORSHIFT) ? rng_result : 32'bz;

	wire midi_busy_reading;
	wire[23:0] midi_bytes;
	reg[31:0] midi_result;
	wire[31:0] midi_raw;
	midi_monitor midi_bitty(.midi_data(midi_data), .clock(clock), .busy_reading(midi_busy_reading), .midi_bytes(midi_bytes));
	always @(negedge midi_busy_reading) begin
		midi_result <= {8'b0, midi_bytes};
	end
    assign mmio_result = (mem_addr == MMIO_MIDIIN) ? midi_result : 32'bz;

	localparam AUDIO_BUFFER_SIZE = 512;
	reg[15:0] audio_buffer[AUDIO_BUFFER_SIZE - 1:0];
	reg[$clog2(AUDIO_BUFFER_SIZE) - 1 : 0] audio_buffer_idx;
	initial begin
		audio_buffer_idx <= AUDIO_BUFFER_SIZE - 1;
	end

	always @(posedge write_audio_buffer) begin
		audio_buffer[audio_buffer_idx] <= audio_buffer_write_val;
		if(audio_buffer_idx != 0) begin
			audio_buffer_idx <= audio_buffer_idx - 1;
		end else begin
			audio_buffer_idx <= AUDIO_BUFFER_SIZE - 1;
		end
	end
	wire audio_buffer_ready = (audio_buffer_idx == 0);
	assign audio_buff_ready = audio_buffer_ready;
	assign mmio_result = (mem_addr == MMIO_AUDIO_BUFFER_READY) ? {30'b0, audio_buffer_ready} : 32'bz;


	wire[31:0] dct_lut_val;
	reg [23:0] sin_lut_vals [511:0];
	initial begin
        // FIX: remove the directories when you go to flash this to hardware
        $readmemh("dct_lut.mem", sin_lut_vals, 0, 511);
    end
	assign dct_lut_val = {8'b0, sin_lut_vals[mem_addr[8:0]]};
	assign mmio_result = (mem_addr >= MMIO_DCTLUTS && mem_addr < MMIO_DCTLUTS + 512) ? dct_lut_val : 32'bz;

	// wire[15:0] sin_val;
	// tri_lut tri_lutty(.value(sin_val), .index(mem_addr[15:0]));
	assign mmio_result = (mem_addr >= MMIO_AUDIO_BUFFER_REGION) ? {16'b0, audio_buffer[mem_addr[8:0]]} : 32'bz;

    // mux4 #(32) iomux(
	// 	.out(mmio_result), .sel(mem_addr[1:0]), 
	// 	.in0(32'hfbadc0de), .in1(rng_result), .in2(midi_result), .in3(32'hdeadbeef));
endmodule