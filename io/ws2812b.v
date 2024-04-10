module ws2812 #(parameter NUM = 8)(
input clock_100, clear,
input [((24*NUM)-1):0] rgb_strip,
output out, done
);
//this module allows interfacing with ws2812b leds of length NUM based on array rgb_strip.
//rgb_strip is of length num*24. rgb_strip should be 24 bit colors (8 bits each R, G, B in that order)
//with MSB first. The leds that come first in the strip should be the most significant.
//the done output goes high when all data is written, but it must be high for at least 50 us in order to
//lock the new colors in to the strip and display them. the clear input can be pulled high to load in and
//display a new array in the input. The input is saved to a reg, so after one cycle it can be changed and not
//disrupt the writing to the strip. the out output should go to a pin. 
//clock_100 should go to the 100MHZ CLOCK, NOT THE 50MHZ CPU CLOCK!

reg out_reg, done_reg;

reg [23:0] rgb;
reg [((24*NUM)-1):0] rgb_strip_reg;

integer counter;
integer bit_loc;
integer state;
integer pixel_count;

wire clock_20;
sys_counter #(5) twenty(clock_100, clear, clock_20);

initial begin
    rgb_strip_reg = rgb_strip;
    rgb = rgb_strip_reg[((24*NUM)-1):(24*(NUM-1))];
    bit_loc <= 23;
    counter <= 0; pixel_count <= 0;
    GRB = {rgb[15:8], rgb[23:16], rgb[7:0]};
    out_reg <= 1;
    done_reg <= 0;
end

always @(posedge clock_20) begin
    if(state == 0 & counter == 8) begin //switch from zero_high to zero_low
        out_reg <= 0;
    end else if(state == 1 & counter == 16) begin //switch from one_high to one_low
        out_reg <= 0;
    end
    if(counter < 25) begin
        counter <= counter + 1;
    end

    else begin //done transmitting this bit
        if(bit_loc == 0) begin state = 2; end
        else begin 
            bit_loc = bit_loc - 1;
            state = GRB[bit_loc];
            out_reg = 1;
        end
        counter <= 0;
    end

    if(state == 2) begin
        if(pixel_count == NUM-1)begin
            done_reg = 1; out_reg = 0; //done with strip
        end
        else begin
            pixel_count = pixel_count + 1;
            bit_loc <= 23;
            counter <= 0;
            rgb_strip_reg = rgb_strip_reg << 24;
            rgb = rgb_strip_reg[((24*NUM)-1):(24*(NUM-1))];
            GRB = {rgb[15:8], rgb[23:16], rgb[7:0]};
            out_reg <= 1;
        end //done with one pixel, so we move on

        if(clear) begin
            rgb_strip_reg = rgb_strip;
            rgb = rgb_strip_reg[((24*NUM)-1):(24*(NUM-1))];
            bit_loc <= 23;
            counter <= 0; pixel_count = 0;
            GRB = {rgb[15:8], rgb[23:16], rgb[7:0]};
            out_reg <= 1;
            done_reg <= 0;
        end
    end
end

assign out = out_reg;
assign done = done_reg;
endmodule