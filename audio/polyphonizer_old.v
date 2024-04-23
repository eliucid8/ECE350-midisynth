module polyphonizer_old(
    input clock,
    input double_word_clock,
    input midi_busy,
    input[23:0] midi_result,
    output reg [15:0] audio_value
);
    localparam 
        NUM_VOICES = 8;

    reg[3:0] channels[NUM_VOICES - 1:0];
    reg[7:0] pitches[NUM_VOICES - 1:0];
    reg[1:0] wave_selects[NUM_VOICES - 1:0];
    reg[31:0] inc_rates[NUM_VOICES - 1:0];
    reg[31:0] lut_indices[NUM_VOICES - 1:0];
    reg[$clog2(NUM_VOICES) - 1 :0] num_on, cur_channel;

    reg[31:0] overall_lut_index;
    reg[1:0] overall_wave_sel;

    integer i;
    initial begin
        for(i = 0; i < NUM_VOICES; i = i + 1) begin
            channels[i] <= 0;
            pitches[i] <= 0;
            wave_selects[i] <= i[3:2];
            inc_rates[i] <= 0;
            lut_indices[i] <= 0;
        end
        num_on <= 0;
        cur_channel <= 0;
        overall_lut_index <= 0;
        overall_wave_sel <= 0;
    end

    reg[28:0] inc_rate_lut[95:0];
	initial begin
		$readmemh("inc_rates.mem", inc_rates);
	end

    wire[3:0] midi_status, midi_channel;
	wire[7:0] midi_note, midi_velocity;
	assign midi_status = midi_result[23:20];
    assign midi_channel = midi_result[19:16];
	assign midi_note = midi_result[15:8];
	assign midi_velocity = midi_result[7:0];

    wire midi_negedge, double_word_negedge;
    negedgedetector midi_busy_negedge(.out(midi_negedge), .clock(clock), .sig(midi_busy));
    negedgedetector dword_negedge(.out(double_word_negedge), .clock(clock), .sig(double_word_clock));

    reg removing, remove_found, queue_gen, note_genning;
    reg[$clog2(NUM_VOICES) - 1:0] channel_to_be_removed;
    reg signed[31:0] pre_output_sum;

    wire signed [15:0] square_val, saw_val, sin_val, tri_val, selected_val;
    
    square_lut square_lutty(.value(square_val), .index(overall_lut_index[31:16]));
	saw_lut saw_lutty(.value(saw_val), .index(overall_lut_index[31:16]));
	sin_lut sin_lutty(.value(sin_val), .index(overall_lut_index[31:16]));
	tri_lut tri_lutty(.value(tri_val), .index(overall_lut_index[31:16]));
    assign selected_val = overall_wave_sel[1] ? (overall_wave_sel[0] ? tri_val : sin_val) : (overall_wave_sel[0] ? saw_val : square_val);
    reg signed [31:0] averaged;

    always @(posedge clock) begin
        if(midi_negedge) begin
            if(midi_status == 4'h9) begin
                channels[num_on] <= midi_channel;
                pitches[num_on] <= midi_note;
                if(midi_note < 4) begin
                    wave_selects[num_on] <=  midi_note[1:0];
                end
                inc_rates[num_on] <= inc_rate_lut[midi_note - 8'd21];
                lut_indices[num_on] <= 0;
                num_on <= num_on + 1;
            end else if(midi_status == 4'h8) begin
                removing <= 1'b1;
            end
        end

        // if(removing && !remove_found && !note_genning) begin  // haven't found channel to remove yet.
        //     if((midi_channel == channels[cur_channel]) && (midi_note == pitches[cur_channel])) begin
        //         remove_found <= 1'b1;
        //         channel_to_be_removed <= cur_channel;
        //     end
        //     cur_channel <= cur_channel + 1;
        // end else if(remove_found && !note_genning) begin
        //     if(cur_channel == channel_to_be_removed) begin
        //         removing <= 0;
        //         remove_found <= 0;
        //         cur_channel <= 0;
        //         num_on <= num_on -1;
        //     end
        //     if(cur_channel > channel_to_be_removed) begin
        //         // shift everything down
        //         channels[cur_channel - 1] <= channels[cur_channel];
        //         pitches[cur_channel - 1] <= pitches[cur_channel];
        //         wave_selects[cur_channel - 1] <= wave_selects[cur_channel];
        //         inc_rates[cur_channel - 1] <= inc_rates[cur_channel];
        //         lut_indices[cur_channel - 1] <= lut_indices[cur_channel];
        //     end
        //     cur_channel <= cur_channel + 1;
        // end

        if(double_word_negedge) begin
            queue_gen <= 1;
        end
        if(queue_gen && !removing) begin
            note_genning <= 1;
            cur_channel <= 0;
            queue_gen <= 0;
        end
        if(note_genning) begin
            lut_indices[cur_channel] = lut_indices[cur_channel] + inc_rates[cur_channel];
            overall_lut_index = lut_indices[cur_channel];
            overall_wave_sel = wave_selects[cur_channel];
            pre_output_sum = pre_output_sum + selected_val;
            cur_channel = cur_channel + 1;
        end
        if(cur_channel == 0) begin
            averaged = (pre_output_sum >>> 4);
            audio_value = averaged[15:0];
            note_genning = 0;
            pre_output_sum = 0;
        end
    end

endmodule