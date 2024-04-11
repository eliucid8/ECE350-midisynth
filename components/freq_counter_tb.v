module freq_counter_tb();
    reg clock;
    integer limit, i, j;

    initial begin
        $dumpfile("freq_counter.vcd");
        $dumpvars(0, freq_counter_tb);
    end

    initial begin
        clock <= 0;
        limit <= 0;
        i <= 0;
        for(i = 0; i < 16; i = i + 1) begin
            for(j = 0; j < 60; j = j + 1) begin
                #10
                clock <= ~clock;
                $display("div %d: %b", i, down_clock);
            end
        end
    end

    wire down_clock;
    sys_counter_freq #(60) test_freq_counter(clock, 1'b0, i[6:0], down_clock); 

    

endmodule