module midi_monitor(input midi_data, input clock, output reg busy_reading, output [23:0] midi_bytes);
    wire midi_clock, clr;
    reg [29:0] midi_message;
    reg [23:0] midi_bytes_reg;
    reg [4:0] bit_num;

    sys_counter #(1600) midi_down(clock, clr, midi_clock);

    initial begin
        busy_reading <= 0;
        midi_message <= 0;
        bit_num <= 29;
        midi_bytes_reg <= 0;
    end

    always @(negedge midi_data) begin
        if(!busy_reading) begin bit_num <= 29; busy_reading <= ~busy_reading; end
    end

    always @(posedge midi_clock)begin
        if(busy_reading)begin
        midi_message[bit_num] <= midi_data;
        busy_reading = (bit_num == 0);
        bit_num <= bit_num-1;
        end
    end

    always @(negedge busy_reading)begin
        midi_bytes_reg <= {midi_message[28:21],midi_message[18:11],midi_message[8:1]};
    end

    assign midi_bytes = midi_bytes_reg;
endmodule

module sys_counter #(parameter COUNT = 69)(input clock, input clr, output down_clock);
    reg [$clog2(COUNT):0] up_clock;
    reg down_reg;
    assign down_clock = down_reg;
    initial begin up_clock = 0; down_reg = 0; end
    always @(posedge clock or posedge clr) begin
        if(up_clock < COUNT)begin
            up_clock <= up_clock + 1;
            down_reg <= 1'b0;
        end else begin
            down_reg <= 1'b1;
            up_clock <= 0;
        end
        if(clr) begin
            up_clock <= 0; 
            down_reg <= 0;
        end
    end
endmodule