module ws2b(
    input CLK100MHZ,
    input push,
    input [23:0] rgb_input,
    // input [15:0] SW,
    output out_signal,
    // output [7:0] JA
);

wire [23:0] rgb_input;
//assign rgb_input[0] = 24'hff0000;
//assign rgb_input[1] = 24'h00ff00;
//assign rgb_input[2] = 24'h0000ff;
//assign rgb_input[3] = 24'hffff00;
//assign rgb_input[4] = 24'h00ffff;
//assign rgb_input[5] = 24'hff00ff;
//assign rgb_input[6] = 24'h000000;
//assign rgb_input[7] = 24'hffffff;

// wire push;
// assign push = SW[0];
reg [23:0] GRB;
wire clock_0, clock_1, bitclk, pixclk;

reg [5:0] bit_place;
reg reset_bit_place;

reg out_reg, out_bit, push_reg;
wire out_wire;
initial begin
    GRB = {rgb_input[15:8], rgb_input[23:16], rgb_input[7:0]};
    bit_place = 6'd23;
    //out_reg = 1;
end

arb_clock #(35,90) ws_zero_clock(CLK100MHZ, clock_0);

arb_clock #(90,35) ws_one_clock(CLK100MHZ, clock_1);

arb_clock #(120,5) ws_bit_clock(CLK100MHZ, bitclk); //falls 50ns before end of bit

arb_clock #(2980, 20) ws_pixel_clock(CLK100MHZ, pixclk); //falls 200ns before end of pixel

//always @(negedge clock_0)begin out_reg = out_bit ? 1'b1 : 1'b0; end
//always @(negedge clock_1)begin out_reg = 1'b0; end//out_bit ? clock_1 : clock_0; end
//always @(posedge bitclk) begin out_reg = 1; end

always @(negedge bitclk) begin
    if(bit_place == 0)begin
        bit_place = 6'd23;
        out_bit = GRB[bit_place];end
    else begin
        out_bit = GRB[bit_place];
        bit_place = bit_place - 1;
    end
end

always @(negedge pixclk) begin
    GRB = ~GRB;//{rgb_input[15:8], rgb_input[23:16], rgb_input[7:0]};
   // bit_place = 6'd23;
   // out_reg = 1;
    push_reg = push;
end

assign out_wire = out_bit ? clock_1 : clock_0;

assign out_signal = push_reg ? 1'b0 : out_wire;
// assign JA[2] = out_signal;
// assign JA[1] = clock_1;
// assign JA[0] = clock_0;
// assign JA[3] = pixclk;
// assign JA[4] = bitclk;
endmodule



module arb_clock #(parameter HIGH=50, LOW = 50)(input clk_100, output reg arb_clk);
reg [31:0] counter;
initial begin
counter = 32'd0;
arb_clk = 32'd0;
end
always @(posedge clk_100)
begin
    counter <= counter + 32'd1;
    if(counter >= (LOW+HIGH-1))
        counter <= 32'd0;
    arb_clk <= (counter < HIGH) ? 1'b1 : 1'b0;
end
endmodule