module midi_tb;
    initial begin
            $dumpfile("midi.vcd");
            $dumpvars(0, midi_tb);
        end

    reg clock;
    wire midi_data, busy_reading;
    wire[23:0] midi_bytes;

    midi_monitor midi_ditty(.midi_data(midi_data), .clock(clock), .busy_reading(busy_reading), .midi_bytes(midi_bytes));

    integer i;
    reg[31:0] state;
    wire[31:0] a, b, c;
    assign a = state ^ (state << 13);
    assign b = a ^ (a >> 17);
    assign c = b ^ (b << 5);
    assign midi_data = c[3];

    initial begin
        clock = 0;
        state = 32'hdeadbeef;
        for(i = 0; i < 1024; i = i + 1) begin
            #1
            clock <= ~clock;
            // $display("%h", c);
        end
        $finish;
    end

    always @(posedge clock) begin
                state <= c;
            end
endmodule