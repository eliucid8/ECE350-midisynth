module i2s(
    input sys_clock, reset, bit_clock,
    input [15:0] audio_data,
    output word_clock, data_bit,
    output wrise, wfall
    );

    reg [15:0] audio_reg_left, audio_reg_right;
    reg old_word_clock;
    reg [15:0] data_reg;
 
    always @(posedge sys_clock)begin //yes, you could technically get by with one register.
        audio_reg_left = audio_data;
        audio_reg_right = audio_data;
    end                            
    //ALSO: in this system, can't give data super super early,
    //specifically can't give R(t+1) while outputting L(t), 
    //but can give R(t) while L(t), or R(t+1) while R(t)
    //and likewise can give L(t+1) while outputting L(t).

    sys_counter_wide #(15) wordclock(~bit_clock, reset, word_clock); //weird but its on the not, i know right

    initial begin
        data_reg = 16'hc0de;
    end

    reg word_rising, word_falling;
    assign wrise = word_rising;
    assign wfall = word_falling;
    always @(posedge bit_clock) begin
         if(~old_word_clock & word_clock)begin //edge detection ! L to R
            word_rising <= 1'b1;
        end else if(old_word_clock & ~word_clock)begin  //edge detection ! R to L
            word_falling <= 1'b1;
        end else begin
            word_rising <= 1'b0;
            word_falling <= 1'b0;
        end
        old_word_clock <= word_clock;

    end

    always @(negedge bit_clock) begin
        
        if(word_rising == 1)begin //edge detection ! L to R
            data_reg <= audio_reg_right;
        end else if(word_falling == 1)begin  //edge detection ! R to L
            data_reg <= audio_reg_left;
        end else begin
            data_reg <= data_reg << 1;
        end
    end

    assign data_bit = data_reg[15];
endmodule