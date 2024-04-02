module counter #(
    parameter WIDTH = 5 ) (
    output[WIDTH-1:0] count,
    input clr,
    input clk );

    wire[WIDTH-1:0] Q, D;
    assign D = ~Q;
    assign count = Q;
    wire[WIDTH-1:0] enable;
    assign enable[0] = 1'b1;

    genvar i;

    for(i = 1; i < WIDTH; i = i + 1) begin
        assign enable[i] = &Q[i-1:0];
    end

    for(i = 0; i < WIDTH; i = i + 1) begin
        dffe_ref tff(.q(Q[i]), .d(D[i]), .clk(clk), .en(enable[i]), .clr(clr));
    end
endmodule

module rShiftReg #(
    parameter WIDTH = 32 ) (
    output[WIDTH-1:0] q,
    input[WIDTH-1:0] init,
    input shin, // shift in
    input clk,
    input clr,
    input en );
    
    wire[WIDTH-1:0] d;
    assign d[WIDTH-1] = shin;
    assign d[WIDTH-2:0] = q[WIDTH-1:1];

    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin
            dffe_init dff(
                .q(q[i]), .d(d[i]), 
                .clk(clk), .en(en), 
                .clr(clr), .init(init[i])
            );
        end    
    endgenerate
endmodule

module lShiftReg #(
    parameter WIDTH = 32) (
    output[WIDTH-1:0] q,
    input[WIDTH-1:0] init,
    input shin, // shift in
    input clk,
    input clr,
    input en );
    
    wire[WIDTH-1:0] d;
    assign d[0] = shin;
    assign d[WIDTH-1:1] = q[WIDTH-2:0];

    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin
            dffe_init dff(
                .q(q[i]), .d(d[i]), 
                .clk(clk), .en(en), 
                .clr(clr), .init(init[i])
            );
        end    
    endgenerate
endmodule

module edgedetector(output out, input clock, input sig);
    wire prev_sig;
    dffe_ref prev(.q(prev_sig), .d(sig), .clk(clock), .en(1'b1));
    assign out = !prev_sig && sig;
endmodule

module debouncer #(
    parameter DELAY_CYCLES = 100000 
) (
    output debounced,
    input sig,
    input clock );

    reg[$clog2(DELAY_CYCLES):0] debounce_timer;
    reg dblatch;
    wire debounce_ready;

    assign debounced = dblatch;
    assign debounce_ready = (debounce_timer == DELAY_CYCLES);

    initial begin
        dblatch = 0;
    end

    always @(posedge clock) begin
        if(debounce_timer < DELAY_CYCLES) begin
            debounce_timer <= debounce_timer + 1;
        end
        if(sig != dblatch) begin
            if(debounce_ready) begin
                dblatch <= sig;
            end
            debounce_timer <= 0;
        end
    end
    
endmodule