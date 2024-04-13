module mmio (
    output[31:0] mmio_result,
    output[31:0] midi_result,
    output midi_busy_reading,
    input clock,
    input [31:0] memAddr,
    input mem_read_enable,
    input midi_data
);
	localparam 
		MMIO_XORSHIFT = 	32'h2001, // 8193
		MMIO_MIDIIN = 		32'h2002; // 8194

	// xorshift
	wire[31:0] rng_result;
	wire next_rng = mem_read_enable && memAddr == MMIO_XORSHIFT; // hex address 1388
	xorshift #(.SEED(32'hdeadbeef)) xorshift_rng(.rand(rng_result), .next(next_rng), .clock(clock));
    assign mmio_result = (memAddr == MMIO_XORSHIFT) ? rng_result : 32'bz;

	wire midi_busy_reading;
	wire[23:0] midi_bytes;
	reg[31:0] midi_result;
	wire[31:0] midi_raw;
	midi_monitor midi_bitty(.midi_data(midi_data), .clock(clock), .busy_reading(midi_busy_reading), .midi_bytes(midi_bytes));
	always @(negedge midi_busy_reading) begin
		midi_result <= {8'b0, midi_bytes};
	end
    assign mmio_result = (memAddr == MMIO_MIDIIN) ? midi_result : 32'bz;

    // mux4 #(32) iomux(
	// 	.out(mmio_result), .sel(memAddr[1:0]), 
	// 	.in0(32'hfbadc0de), .in1(rng_result), .in2(midi_result), .in3(32'hdeadbeef));
endmodule