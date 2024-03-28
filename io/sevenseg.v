module sevenseg_logic(num, segments);
    input[3:0] num;
    output[7:0] segments;
    
    wire[15:0] digit;
    assign digit = 4'b1 << num;
    
    assign segments[0] = |{digit[1], digit[4], digit[11], digit[13]};

    assign segments[1] = |{digit[5], digit[6], digit[11], digit[12], digit[14], digit[15]};

    assign segments[2] = |{digit[2], digit[12], digit[14], digit[15]};

    assign segments[3] = |{digit[1], digit[4], digit[7], digit[15]};

    assign segments[4] = |{digit[1], digit[3], digit[4], digit[7], digit[9]};

    assign segments[5] = |{digit[1], digit[2], digit[3], digit[7], digit[10], digit[12]};

    assign segments[6] = |{digit[0], digit[1], digit[7], digit[12]};

    assign segments[7] = 1'b1;
endmodule

module sevenseg_controller(downclock, word, segments, enables);
    input downclock;
    input[31:0] word;
    output[7:0] segments, enables;

    // she count on my johnson till I stepper motor 
    // it's not an actual johnson counter
    reg[7:0] counter;
    assign enables = {~counter};
    initial begin
        counter = 8'b1;
    end
    
    always @(posedge downclock) begin
        counter <= counter << 1;
        counter[0] <= counter[7];
    end

    wire[2:0] sel;
    assign sel[2] = |{counter[4], counter[5], counter[6], counter[7]};
    assign sel[1] = |{counter[2], counter[3], counter[6], counter[7]};
    assign sel[0] = |{counter[1], counter[3], counter[5], counter[7]};
    
    wire[3:0] num;
    mux8 #(4) sslogic_mux(num, sel, word[3:0], word[7:4], word[11:8], word[15:12], word[19:16], word[23:20], word[27:24], word[31:28]);

    sevenseg_logic sslogic(.num(num), .segments(segments));

endmodule