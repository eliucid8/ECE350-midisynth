module dffe_ref (q, d, clk, en, clr);

    //Inputs
    input d, clk, en, clr;

    //Internal wire
    wire clr;

    //Output
    output q;
    
    //Register
    reg q;

    //Intialize q to 0
    initial
    begin
        q = 1'b0;
    end

    //Set value of q on positive edge of the clock or clear
    always @(posedge clk or posedge clr) begin
        //If clear is high, set q to 0
        if (clr) begin
            q <= 1'b0;
        //If enable is high, set q to the value of d
        end else if (en) begin
            q <= d;
        end
    end
endmodule

module dffe_init(q, d, clk, en, clr, init);
    //Inputs
    input d, clk, en, clr, init;

    //Internal wire
    wire clr;

    //Output
    output q;
    
    //Register
    reg q;

    //Intialize q to 0
    initial
    begin
        q = 1'b0;
    end

    //Set value of q on positive edge of the clock or clear
    always @(posedge clk or posedge clr) begin
        //If clear is high, set q to 0
        if (clr) begin
            q <= init;
        //If enable is high, set q to the value of d
        end else if (en) begin
            q <= d;
        end
    end
endmodule

module tffe(q, t, clk, en, clr);
    input t, clk, en, clr;
    output q;

    // t acts like another enable signal
    wire en2, d;
    and(en2, t, en);
    not(d, q);
    dffe_ref dff(.q(q), .d(d), .clk(clk), .en(en2), .clr(clr));
endmodule