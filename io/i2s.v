module i2s(
    input sys_clock, reset, bit_clock,
    input [15:0] audio_data,
    output word_clock, data_bit
    );

    reg [15:0] audio_reg_left, audio_reg_right;
    reg old_word_clock;
    reg [16:0] data_reg;
 
    always @(posedge sys_clock)begin //yes, you could technically get by with one register.
        audio_reg_left = audio_data;
        audio_reg_right = audio_data;
    end                            
    //ALSO: in this system, can't give data super super early,
    //specifically can't give R(t+1) while outputting L(t), 
    //but can give R(t) while L(t), or R(t+1) while R(t)
    //and likewise can give L(t+1) while outputting L(t).

    sys_counter_wide #(32) wordclock(~bit_clock, reset, word_clock); //weird but its on the not, i know right

    always @(posedge bit_clock) begin
        old_word_clock <= word_clock;
    end

    always @(negedge bit_clock) begin
        data_reg <= data_reg << 1;
        if(~old_word_clock & word_clock)begin //edge detection ! L to R
            data_reg <= {1'b0, audio_reg_right};
        end if(old_word_clock & ~word_clock)begin  //edge detection ! R to L
            data_reg <= {1'b0, audio_reg_left};
        end
    end

    assign data_bit = data_reg[16];
endmodule

module sys_counter_wide #(parameter COUNT = 69)(input clock, clr, output down_clock);
    reg [31:0] up_clock;
    reg down_reg;
    assign down_clock = down_reg;
    initial begin up_clock <= 0; down_reg <= 1'b0; end
    always @(posedge clock) begin
        up_clock <= up_clock + 1;
        if (up_clock == COUNT) begin
            down_reg <= ~down_reg;
            up_clock <= 0;
        end
        if(clear) begin up_clock <= 0; down_reg <= 1'b0; end
    end
endmodule