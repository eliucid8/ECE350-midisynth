module polyphonizer(
    input clock,
    input double_word_clock,
    input midi_busy,
    input[23:0] midi_result,
    output [15:0] audio_value,
    input [15:0] SW,
    output [15:0] inc_display,
    output [7:0] pitch_display,
    output reg running_midi,
    output reg running_dword,
    output[31:0] amplitude_display,
    output midi_negedge,
    input reset
);
    localparam NUM_VOICES = 16;

    wire[3:0] midi_status, midi_channel;
	wire[7:0] midi_note, midi_velocity;
	assign midi_status = midi_result[23:20];
    assign midi_channel = midi_result[19:16];
	assign midi_note = midi_result[15:8];
	assign midi_velocity = midi_result[7:0];

    reg[3:0] channels[NUM_VOICES - 1:0];
    reg[7:0] pitches[NUM_VOICES - 1:0];
    reg[1:0] wave_selects[NUM_VOICES - 1:0];
    reg[31:0] inc_rates[NUM_VOICES - 1:0];
    reg[31:0] lut_indices[NUM_VOICES - 1:0];

    wire double_word_negedge;
    wire midi_negedge;

    negedgedetector midi_busy_negedge(.out(midi_negedge), .clock(clock), .sig(midi_busy));
    negedgedetector dword_negedge(.out(double_word_negedge), .clock(clock), .sig(double_word_clock));
    reg[3:0] midi_idx, dword_idx;
    // reg running_midi, running_dword;

    reg[31:0] overall_lut_index;
    // genvar j;
    // generate
    //     for(j = 0; j < NUM_VOICES; j = j + 1) begin
    //         assign overall_lut_index = (midi_idx == j[3:0]) ? lut_indices[j] : 32'bz;
    //     end
    // endgenerate


    reg[1:0] overall_wave_sel;
    wire[15:0] square_val, saw_val, sin_val, tri_val, selected_val;
    square_lut square_lutty(.value(square_val), .index(overall_lut_index[31:16]));
	saw_lut saw_lutty(.value(saw_val), .index(overall_lut_index[31:16]));
	sin_lut sin_lutty(.value(sin_val), .index(overall_lut_index[31:16]));
	tri_lut tri_lutty(.value(tri_val), .index(overall_lut_index[31:16]));
    reg[31:0] overall_amplitude, latched_amplitude;
    assign audio_value = latched_amplitude[19:4]; // overall amplitude >>> 4, i.e. 
    assign amplitude_display = latched_amplitude;

    reg[28:0] lut_inc_rates[95:0];
	initial begin
		$readmemh("inc_rates.mem", lut_inc_rates);
	end

    // DEBUG:
    assign inc_display = inc_rates[SW[7:4]];
    assign pitch_display = pitches[SW[7:4]];

    mux4 #(16) waveform_mux(
		.out(selected_val), .sel(overall_wave_sel), 
		.in0(square_val), .in1(saw_val), .in2(sin_val), .in3(tri_val)
    );

    integer i;
    initial begin
        for(i = 0; i < NUM_VOICES; i = i + 1) begin
            channels[i] <= 0;
            pitches[i] <= 0;
            wave_selects[i] <= i[3:2];
            inc_rates[i] <= 0;
            lut_indices[i] <= 0;
        end
        midi_idx <= 0;
        dword_idx <= 0;
        running_midi <= 0;
        running_dword <= 0;
        overall_amplitude <= 0;
    end

    always @(posedge clock) begin
        if(reset) begin
            for(i = 0; i < NUM_VOICES; i = i + 1) begin
                channels[i] <= 0;
                pitches[i] <= 0;
                wave_selects[i] <= i[3:2];
                inc_rates[i] <= 0;
                lut_indices[i] <= 0;
            end
            midi_idx <= 0;
            dword_idx <= 0;
            running_midi <= 0;
            running_dword <= 0;
            overall_amplitude <= 0;
        end
        if(midi_negedge == 1'b1) begin
            running_midi <= 1;
        end
        if(running_midi) begin
            if(midi_status == 4'h9) begin
                if(inc_rates[midi_idx] == 0) begin
                    channels[midi_idx] <= midi_channel;
                    pitches[midi_idx] <= midi_note;
                    inc_rates[midi_idx] <= lut_inc_rates[midi_note - 8'd21];
                    wave_selects[midi_idx] <= midi_channel[3:2];
                    running_midi <= 0;
                    midi_idx <= 4'b0;
                end else if(midi_idx != 4'hf) begin
                    midi_idx <= midi_idx + 1;
                end else begin
                    midi_idx <= 0;
                    running_midi <= 0;
                end
            end
            if(midi_status == 4'h8) begin
                if(channels[midi_idx] == midi_channel && pitches[midi_idx] == midi_note) begin
                    inc_rates[midi_idx] <= 0;
                end
                if(midi_idx == 4'hf) begin
                    running_midi <= 0;

                end
                midi_idx <= midi_idx + 1;
            end
        end

        if(double_word_negedge == 1'b1) begin
            running_dword <= 1;
            overall_amplitude <= 0;
        end
        if(running_dword) begin
            if(inc_rates[dword_idx] != 0) begin
                overall_lut_index = lut_indices[dword_idx];
                overall_wave_sel = wave_selects[dword_idx];
                lut_indices[dword_idx] = lut_indices[dword_idx] + inc_rates[dword_idx];
                overall_amplitude = overall_amplitude + selected_val;
            end 
            if(dword_idx == 4'hf) begin
                running_dword = 0;
                latched_amplitude = overall_amplitude;
            end
            dword_idx = dword_idx + 1;
        end
    end

endmodule