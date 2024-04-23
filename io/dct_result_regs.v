module dct_result_regs(
    output[15:0] dct_result,
    input clock,
    input[3:0] read_index,
    input mem_write_enable,
    input[31:0] mem_addr, mem_write_data
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

    always @(posedge clock) begin
        if(mem_write_enable && (mem_addr >= MMIO_DCT_RESULT_REGION && mem_addr < MMIO_DCT_RESULT_REGION + MMIO_DCT_RESULT_COUNT)) begin
            dct_results[mem_addr - MMIO_DCT_RESULT_COUNT] <= mem_write_data[15:0];
        end
    end

    assign dct_result = dct_results[read_index];

endmodule