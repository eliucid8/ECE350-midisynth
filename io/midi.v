module midi_monitor(input midi_data, input clock, output reg busy_reading, output [23:0] midi_bytes, output[31:0] midi_raw);
    localparam BIT_NUM_MAX = 30;

    wire midi_clock, clr;
    reg [BIT_NUM_MAX:0] midi_message;
    reg [23:0] midi_bytes_reg;
    reg [4:0] bit_num;


    sys_counter #(1600) midi_down(clock, clr, midi_clock);

    initial begin
        busy_reading <= 0;
        midi_message <= 0;
        bit_num <= BIT_NUM_MAX;
        midi_bytes_reg <= 0;
    end

    // reg to detect falling edge of midi data
    reg prev_midi_data;

    always @(posedge midi_clock) begin
        if(busy_reading) begin
            midi_message[bit_num] = midi_data;
            busy_reading = !(bit_num == BIT_NUM_MAX);
            bit_num = bit_num+1;
        end else if(!midi_data) begin
            bit_num <= 5'b0; 
            busy_reading <= 1'b1; 
            // prev_midi_data <= midi_data;
        end
    end

    always @(negedge busy_reading)begin
        midi_bytes_reg <= {midi_message[7:0],midi_message[18:11],midi_message[29:22]};
    end

    assign midi_bytes = midi_bytes_reg;

    assign midi_raw = {1'b0, midi_message};
endmodule