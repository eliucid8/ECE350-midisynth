module multdiv(
	data_operandA, data_operandB, 
	ctrl_MULT, ctrl_DIV, 
	clock, 
	data_result, data_exception, data_resultRDY);

    input [31:0] data_operandA, data_operandB;
    input ctrl_MULT, ctrl_DIV, clock;

    output [31:0] data_result;
    output data_exception, data_resultRDY;

    // add your code here
    wire operation;
    dffe_ref opdff(
        .q(operation), .d(ctrl_MULT), .clk(clock), 
        .en(ctrl_MULT | ctrl_DIV), .clr(1'b0)
    );

    wire[31:0] mult_res;
    wire mult_ovf, mult_ready;

    mult mult(
        .multiplicand(data_operandA), .multiplier(data_operandB),
        .reset(ctrl_MULT), .clk(clock),
        .prod(mult_res), .ovf(mult_ovf), .ready(mult_ready)
    );

    wire[31:0] divider_out, div_res;
    wire div0, div_hardware_ready, div_ready;
     // divide by zero
    assign div_ready = div0 ? 1'b1 : div_hardware_ready;

    div div(
        .dividend(data_operandA), .divisor(data_operandB),
        .reset(ctrl_DIV), .clk(clock),
        .quot(divider_out), .ready(div_hardware_ready), .div0(div0)
    );
    // set result to 0 if we divide by 0.
    assign div_res = div0 ? 32'b0 : divider_out;

    assign data_resultRDY = operation ? mult_ready : div_ready;

    // assign data_result = ctrl_MULT ? mult_res : 32'bz;
    // assign data_result = ctrl_DIV ? div_res : 32'bz;
    assign data_result = operation ? mult_res : div_res;

    // assign data_exception = ctrl_MULT ? mult_ovf : 32'bz;
    // assign data_exception = ctrl_DIV ? div0 : 32'bz;
    assign data_exception = operation ? mult_ovf : div0;
endmodule