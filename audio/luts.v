// The output is in 2's complement. ig I could use signed but idk how that works...

module squarelut(
    output[15:0] value, 
    input [15:0] index);
    
    assign value = index[15] ? 16'h8001 : 16'h7fff;
endmodule

module sawlut(
    output[15:0] value, 
    input [15:0] index);
    
    // 2's complement to the rescue again! Just making sure that the value is never 16 bit signed min. 
    assign value = (index == 16'h8000) ? 16'h0 : index;
endmodule