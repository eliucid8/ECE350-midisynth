module regfile (
	clock,
	ctrl_writeEnable, ctrl_reset, ctrl_writeReg,
	ctrl_readRegA, ctrl_readRegB, data_writeReg,
	data_readRegA, data_readRegB
);

	input clock, ctrl_writeEnable, ctrl_reset;
	input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	input [31:0] data_writeReg;

	output [31:0] data_readRegA, data_readRegB;

	// add your code here
	wire[31:0] writeRegOneHot, readRegAOneHot, readRegBOneHot;

	decoder32 writeRegDec(writeRegOneHot, ctrl_writeReg, ctrl_writeEnable);
	decoder32 readRegADec(readRegAOneHot, ctrl_readRegA, 1'b1);
	decoder32 readRegBDec(readRegBOneHot, ctrl_readRegB, 1'b1);

	// register $0 hardwired to 0/zstate.
	assign data_readRegA = readRegAOneHot[0] ? 32'b0 : 32'bz;
	assign data_readRegB = readRegBOneHot[0] ? 32'b0 : 32'bz;

	genvar i;
	for(i = 1; i < 32; i = i + 1) begin
		wire[31:0] regout;
		register #(32) r(
			.clk(clock), 
			.writeEnable(writeRegOneHot[i]), .reset(ctrl_reset),
			.dataIn(data_writeReg), .dataOut(regout)
			);

		assign data_readRegA = readRegAOneHot[i] ? regout : 32'bz;
		assign data_readRegB = readRegBOneHot[i] ? regout : 32'bz;
	end
endmodule
