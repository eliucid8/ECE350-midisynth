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

module sys_counter_wide #(parameter COUNT = 69)(input clock, input clr, output down_clock);
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
        if(clr) begin up_clock <= 0; down_reg <= 1'b0; end
    end
endmodule

module sys_counter_pwm #(
    parameter COUNT = 69
) (
    input clock,
    input clr,
    input[$clog2(COUNT):0] var,
    output down_clock
);
    reg [$clog2(COUNT):0] up_clock;
    reg down_reg;
    assign down_clock = up_clock < var;
    initial begin up_clock <= 0; end
    always @(posedge clock) begin
        if(clr) begin 
            up_clock <= 0; 
        end else begin
            if (up_clock == COUNT - 1) begin
                up_clock <= 0;
            end else begin
                up_clock <= up_clock + 1;
            end
        end
    end
endmodule

module sys_counter_freq # (
    parameter SYS_CLOCK_FREQ = 50000000
) (
    input clock,
    input clr,
    input [31:0] div,
    output reg down_clock
);
    reg[31:0] up_clock;
    initial begin
        up_clock <= 0;
        down_clock <= 0;
    end
    wire[31:0] counter_limit = div;

    always @(posedge clock) begin
        if(clr) begin
            up_clock <= 0;
            down_clock <= 0;
        end else begin
            if(up_clock < counter_limit - 1) begin
                up_clock <= up_clock + 1;
            end else begin
                up_clock <= 0;
                down_clock <= ~down_clock;
            end
        end
    end

endmodule