module freq_counter_tb();
    reg clock;
    integer limit, i, j;

    initial begin
        $dumpfile("freq_counter.vcd");
        $dumpvars(0, freq_counter_tb);
    end

    initial begin
        clock <= 0;
        i <= 0;
        // for(i = 100; i < 500; i = i + 1) begin
            for(j = 0; j < 1000000; j = j + 1) begin
                #1
                clock <= ~clock;
                // $display("div %d: %b", i, down_clock);
            end
        // end
    end

    wire down_clock;
    sys_counter_freq #(48000) test_freq_counter(clock, 1'b0, 480, down_clock); 

    

endmodule