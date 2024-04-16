// The output is in 2's complement. ig I could use signed but idk how that works...

module square_lut(
    output[15:0] value, 
    input [15:0] index);
    
    assign value = index[15] ? 16'h8001 : 16'h7fff;

endmodule

module saw_lut(
    output[15:0] value, 
    input [15:0] index);
    
    // 2's complement to the rescue again! Just making sure that the value is never 16 bit signed min. 
    assign value = (index == 16'h8000) ? 16'h0 : index;

endmodule

module sin_lut(
    output signed [15:0] value, 
    input [15:0] index);

    reg signed [15:0] sin_lut_vals [128:0];
    initial begin
        $readmemh("sin_lut.mem", sin_lut_vals);
    end

    // flip the order of indexing if in 2nd or 4th quadrant of range
    wire [6:0] flipped_index = index[14] ? 8'h80 - index[13:7] : index[13:7];
    wire signed [15:0] unflipped_vals = sin_lut_vals[flipped_index];
    assign value = index[15] ? -unflipped_vals : unflipped_vals;

endmodule

module tri_lut(
    output signed [15:0] value, 
    input [15:0] index);

    wire [15:0] flipped_index = index[14] ? {15'h4000 - {1'b0, index[13:0]}, 1'b0} : {1'b0, index[13:0], 1'b0};
    assign value = index[15] ? -flipped_index : flipped_index;

endmodule