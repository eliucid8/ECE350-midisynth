module xorshift #(
    parameter SEED = 32'hdeadbeef
) (
    output[31:0] rand,
    input next,
    input clock );

reg[31:0] state;
assign rand = state;
initial begin
    state = SEED;
end

wire[31:0] a, b, c;

assign a = state ^ (state << 13);
assign b = a ^ (a >> 17);
assign c = b ^ (b << 5);

always @(posedge clock) begin // clocked on posedge like dmem
    if(next) begin
        state <= c;
    end
end

endmodule