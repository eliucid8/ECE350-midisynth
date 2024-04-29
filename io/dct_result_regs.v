module dct_result_regs(
    output[15:0] dct_result,
    output out_signal,
    input clock,
    input[3:0] read_index,
    input mem_write_enable,
    input[31:0] mem_addr, 
    input[31:0] mem_write_data,
    input CLK100MHZ
);

    localparam 
        MMIO_DCT_RESULT_REGION = 32'h3000, // 12288
        MMIO_DCT_RESULT_COUNT = 32'd16;

    reg[15:0] dct_results [15:0];
    integer i;
    initial begin
        for(i = 0; i < MMIO_DCT_RESULT_COUNT; i = i + 1) begin
            dct_results[i] = 16'b0;
        end
    end


    wire[671:0] buff0, buff1, buff2, buff3;
    reg[3:0] col;
    reg[2:0] place;

    always @(posedge clock) begin
        if(mem_write_enable && (mem_addr >= MMIO_DCT_RESULT_REGION && mem_addr < MMIO_DCT_RESULT_REGION + MMIO_DCT_RESULT_COUNT)) begin
            dct_results[mem_addr - MMIO_DCT_RESULT_COUNT] <= mem_write_data[15:0];
        end
    end

    assign dct_result = dct_results[read_index];

    // always @(posedge clock) begin
    //     place <= place + 1;
    //     if(place == 3'b111) begin
    //         col <= col + 1;
    //     end
    // end

    // wire color_sel = dct_results[{2'b10, col[1:0]}] > {place, 12'b0};

    // led_index ledarray(
    //     .rgb_color(color_sel ? 24'hffffff : 24'h0), 
    //     .col(col), .place(place), .clk100(clock), 
    //     .buff0(buff0), .buff1(buff0), .buff2(buff0), .buff3(buff0) 
    // );
    wire pixclk;
    reg [4:0] pxcounter;
    reg push;
    always @(posedge pixclk) begin
        if(pxcounter > 15) begin
            pxcounter <= 0;
            push <= 1'b1;
        end
        push <= 1'b0;
        pxcounter <= pxcounter + 1;
    end

    wire [15:0] dct_res = dct_results[pxcounter];
    wire rgb_input = {dct_res[15:8], dct_res[15:8], dct_res[15:8]};

    ws2b real_leds(.CLK100MHZ(CLK100MHZ), .push(push), .rgb_input(rgb_input), .out_signal(out_signal), .pixclk(pixclk));

endmodule