/**
 * READ THIS DESCRIPTION!
 *
 * This is your processor module that will contain the bulk of your code submission. You are to implement
 * a 5-stage pipelined processor in this module, accounting for hazards and implementing bypasses as
 * necessary.
 *
 * Ultimately, your processor will be tested by a master skeleton, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file, Wrapper.v, acts as a small wrapper around your processor for this purpose. Refer to Wrapper.v
 * for more details.
 *
 * As a result, this module will NOT contain the RegFile nor the memory modules. Study the inputs 
 * very carefully - the RegFile-related I/Os are merely signals to be sent to the RegFile instantiated
 * in your Wrapper module. This is the same for your memory elements. 
 *
 *
 */

module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for RegFile
    ctrl_writeReg,                  // O: Register to write to in RegFile
    ctrl_readRegA,                  // O: Register to read from port A of RegFile
    ctrl_readRegB,                  // O: Register to read from port B of RegFile
    data_writeReg,                  // O: Data to write to for RegFile
    data_readRegA,                  // I: Data from port A of RegFile
    data_readRegB,                  // I: Data from port B of RegFile
	);

	// Control signals
	input clock, reset;
	
	// Imem
    output [31:0] address_imem;
	input [31:0] q_imem;

	// Dmem
	output [31:0] address_dmem, data;
	output wren;
	input [31:0] q_dmem;

	// Regfile
	output ctrl_writeEnable;
	output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	output [31:0] data_writeReg;
	input [31:0] data_readRegA, data_readRegB;

	/* YOUR CODE STARTS HERE */
    // TODO: Change this when modifying Control!
    localparam NUM_CTRL = 25;
    localparam
        wb_dst =            1,
        reg_WE =            2,
        use_mem =           3,
        sw =                4,
        alu_imm =           5,
        calcALUop =         10,
        use_calc_ALUop =    11,
        rtin =              12,
        jr =                13,
        branch =            14,
        use_non_PC =        15,
        jal =               16,
        blt =               17,
        bex =               18,
        setx =              19,
        add_insn =          20,
        addi =              21,
        bypassA =           22,
        bypassB =           23,
        lw =                24;

    // ========Fetch========
    wire[31:0] pcp1, next_pc, addr_imem_out; // pc plus 1
    wire stall_fetch, stall_decode, stall_execute;

    assign address_imem = addr_imem_out;

    cla_32 pc_increment(.A(addr_imem_out), .B(32'b1), .Cin(1'b0), .Sum(pcp1));

    register #(32) pc(
        .clk(clock), .writeEnable(!stall_fetch), .reset(reset), .dataIn(next_pc), .dataOut(addr_imem_out)
    );

    wire[63:0] FDIR, FDIRin;
    wire flush_FD;
    assign FDIRin = flush_FD ? 64'b0 : {addr_imem_out, q_imem}; // We don't use pc+1 here bc idk, non blocking assignments.
    register #(64) FDIRlatch(
        .clk(!clock), .writeEnable(!stall_decode), .reset(reset), .dataIn(FDIRin), .dataOut(FDIR)
    );

    // ========Decode======== 
    wire[31:0] Dinsn =         FDIR[31:0];
    wire[4:0] Dopcode =         Dinsn[31:27];
    wire[4:0] Drd =             Dinsn[26:22];
    wire[4:0] Drs =             Dinsn[21:17];
    wire[4:0] Drt =             Dinsn[16:12];
    // wire[4:0] Dshamt =          Dinsn[11:7];
    // wire[4:0] DinsnALUop =      Dinsn[6:2];
    // wire[31:0] Dimmed =         {{15{Dinsn[16]}}, {Dinsn[16:0]}};
    // wire[26:0] Djump_target =   {5'b0, Dinsn[26:0]};

    wire[NUM_CTRL-1:0] Dctrlbus;
	insn_decode #(NUM_CTRL) insn_decoder(.opcode(Dopcode), .ctrlbus(Dctrlbus));

    // rs = 30 when bex.
    assign ctrl_readRegA = Dctrlbus[bex] ? 32'd30 : Drs;

    //rtin 
    assign ctrl_readRegB = Dctrlbus[rtin] ? Drd : Drt;

    // ====bypassing==== (couldn't figure out where to put this)
    wire[1:0] XAsel, XBsel;
    wire MWDsel, memstall;
    wire[4:0] modified_rd;

    bypass_controller bypass_ctrl(
        .FDrs(Drs), .FDrt(Drt), .FDrd(Drd),
        .DXrs(Xinsn[21:17]), .DXrt(Xinsn[16:12]), .DXrd(/* Xinsn[26:22] */ modified_rd), 
        .XMrd(Minsn[26:22]), .MWrd(Winsn[26:22]),
        .bypassA(Xctrlbus[bypassA]), .bypassB(Xctrlbus[bypassB]),
        .XM_reg_WE(Mctrlbus[reg_WE]), .MW_reg_WE(Wctrlbus[reg_WE]),
        .DX_rtin(Xctrlbus[rtin]), .DX_sw(Xctrlbus[sw]), .DX_setx(Xctrlbus[setx]), .DX_lw(Xctrlbus[lw]),
        .FD_rtin(Dctrlbus[rtin]), .FD_sw(Dctrlbus[sw]), .FD_setx(Dctrlbus[setx]),
        .XM_lw(Mctrlbus[lw]), .XM_sw(Mctrlbus[sw]),
        .XAsel(XAsel), .XBsel(XBsel), .MWDsel(MWDsel), .memstall(memstall)
    );

    wire[31:0] Mexecout, Wresult;

    wire [NUM_CTRL+127:0] DXIR, DXIRin;
    wire flush_DX;
    assign DXIRin = (flush_DX) || (stall_decode && !stall_execute) ? {NUM_CTRL+128{1'b0}} : {Dctrlbus, data_readRegA, data_readRegB, FDIR};
    register #(128 + NUM_CTRL) DXIRlatch(
        .clk(!clock), .writeEnable(!stall_execute), .reset(reset), .dataIn(DXIRin), .dataOut(DXIR)
    );

    // ========eXecute========
    wire [NUM_CTRL-1:0] Xctrlbus;
    assign Xctrlbus = DXIR[NUM_CTRL + 127:128];
    wire [31:0] Xinsn;
    assign Xinsn = DXIR[31:0];

    wire[31:0] XA, XB, Ximmed, XAby, XBby;
    assign XA = DXIR[127:96];
    assign XB = DXIR[95:64];

    mux4 #(.WIDTH(32)) abypassmux(
        .out(XAby), .sel(XAsel),
        .in0(XA), .in1(Mexecout), .in2(Wresult), .in3(32'hdeadbeef)
    );

    mux4 #(.WIDTH(32)) bbypassmux(
        .out(XBby), .sel(XBsel),
        .in0(XB), .in1(Mexecout), .in2(Wresult), .in3(32'hdeadbeef)
    );


    // mux in 0 as Ximmed for bex, so that we can compare against it.
    assign Ximmed = Xctrlbus[bex] ? 32'b0 : {{15{Xinsn[16]}}, {Xinsn[16:0]}};

    wire[31:0] alu_inB;
    assign alu_inB = Xctrlbus[alu_imm] ? Ximmed : XBby;

    wire[31:0] alu_result;
    wire ALU_ne, ALU_lt, ALU_ovf;

    // select between aluop in insn, or aluop provided by control.
    wire[4:0] ALUop, XinsnALUop;
    assign XinsnALUop = Xinsn[6:2];
    assign ALUop = Xctrlbus[11] ? Xctrlbus[10:6] : XinsnALUop;

    wire[4:0] Xshamt;
    assign Xshamt = Xinsn[11:7];
    wire alu_result_ready;

    alu alu(
        .data_operandA(XAby), .data_operandB(alu_inB), .ctrl_ALUopcode(ALUop), 
        .ctrl_shiftamt(Xshamt), .data_result(alu_result), 
        .isNotEqual(ALU_ne), .isLessThan(ALU_lt), .overflow(ALU_ovf),
        .clock(clock), .result_rdy(alu_result_ready)
    );

    // ====Stalls====
    wire div_stall;
    assign div_stall = (ALUop == 5'b00111) && !alu_result_ready;
    assign stall_fetch = div_stall   || memstall;
    assign stall_decode = div_stall  || memstall;
    assign stall_execute = div_stall;

    // ====Exceptions====
    wire [31:0] rstatus_in, alu_except_result;
    wire set_except, allow_except;
    exceptionmap exception_map(.rstatus(rstatus_in), .ALUop(ALUop), .addi(Xctrlbus[addi]), .allow_except(allow_except));
    assign set_except = (Xctrlbus[add_insn]) && allow_except && ALU_ovf;
    assign alu_except_result = set_except ? rstatus_in : alu_result; // set ALU result to exception value if set_except triggered.  

    // modify insn to write to r30 if exception.
    wire[31:0] modified_Xinsn;
    // wire[4:0] modified_rd;
    mux4 #(5) rd_modifier(
        .out(modified_rd), .sel({Xctrlbus[jal], (set_except || Xctrlbus[setx])}),
        .in0(Xinsn[26:22]), .in1(5'd30), .in2(5'd31), .in3(5'bx)
    );
    // assign modified_rd = (set_except || Xctrlbus[setx]) ? 5'd30 : Xinsn[26:22];
    assign modified_Xinsn = {Xinsn[31:27], modified_rd, Xinsn[21:0]}; 

    // TODO: merge all modifications to result into 1 mux.
    /* executeOut
     * default:     alu_result
     * add_insn:    set_except ? rstatus_in : alu_result
     * setx:        jump_addr
     * jal:         cur_pcp1
     */

    // ====Branchland====
    wire[31:0] Tsx, jump_addr, cur_pcp1, branch_target, branch_addr;
    
    wire[31:0] alu_setx_result;
    assign alu_setx_result = Xctrlbus[setx] ? jump_addr : alu_except_result;
    
    // bex jumps to an absolute addr as well. don't do the jump if bex and the sub results in 0.
    wire no_bex_jump = Xctrlbus[bex] && !ALU_ne;
    assign Tsx = no_bex_jump ? pcp1 : {5'b0, {Xinsn[26:0]}}; // muxes in normal pc if bex fails.
    
    assign jump_addr = Xctrlbus[jr] ? XBby : Tsx;
    assign cur_pcp1 = DXIR[63:32];

    // add immediate to pc+1 to see where this insn would branch to.
    cla_32 branch_cla(.A(cur_pcp1), .B(Ximmed), .Cin(1'b0), .Sum(branch_target));
    // ALU_lt tells us if rs < rd , but we want it the other way around.
    // rd < rs => !(rs < rd) && rs != rd.
    wire flipped_lt;
    assign flipped_lt = !ALU_lt && ALU_ne;

    wire do_branch = (!Xctrlbus[blt] && ALU_ne) || (Xctrlbus[blt] && flipped_lt); // hopefully this is readable?
    assign branch_addr = do_branch ? branch_target : pcp1;


    wire[31:0] cflow_addr; // control flow address
    assign cflow_addr = Xctrlbus[branch] ? branch_addr : jump_addr;

    wire[31:0] next_no_stall;
    wire cflow_flush;
    assign cflow_flush = Xctrlbus[use_non_PC] && !(Xctrlbus[branch] && !do_branch) && !(Xctrlbus[bex] && no_bex_jump); // Flush if we change control flow. don't flush if branch not taken, however.

    assign next_no_stall = Xctrlbus[use_non_PC] ? cflow_addr : pcp1; // is next_no_stall necessary???
    assign next_pc = stall_fetch ? addr_imem_out : next_no_stall; 

    assign flush_FD = cflow_flush;
    assign flush_DX = cflow_flush;

    wire[31:0] executeOut; // mux in this insn's pc+1
    assign executeOut = Xctrlbus[jal] ? cur_pcp1 : alu_setx_result;

    wire[NUM_CTRL+95:0] XMIR, XMIRin, XMIRnop;
    assign XMIRnop = {(NUM_CTRL + 96){1'b0}};

    assign XMIRin = stall_execute ? XMIRnop : {Xctrlbus, XBby, executeOut, modified_Xinsn};

    register #(NUM_CTRL + 96) XMIRlatch(
        .clk(!clock), .writeEnable(1'b1), .reset(reset), .dataIn(XMIRin), .dataOut(XMIR)
    );

    // ========Memory========

    wire[NUM_CTRL-1:0] Mctrlbus;
    assign Mctrlbus = XMIR[NUM_CTRL+95:96];

    assign Mexecout = XMIR[63:32];
    assign address_dmem = Mexecout;
    assign wren = Mctrlbus[4];
    wire[31:0] MXB = XMIR[95:64];
    wire[31:0] Mwritedata;
    assign data = Mwritedata;
    wire[31:0] Minsn = XMIR[31:0];

    wire[31:0] Mresult;
    assign Mresult = Mctrlbus[3] ? q_dmem : address_dmem; // decide between memory result and alu result

    mux2 #(.WIDTH(32)) mwdbypassmux(
        .out(Mwritedata), .sel(MWDsel),
        .in0(MXB), .in1(Wresult)
    );

    wire[NUM_CTRL + 63:0] MWIR;
    register #(NUM_CTRL + 64) MWIRlatch(
        .clk(!clock), .writeEnable(1'b1), .reset(reset), .dataIn({Mctrlbus, Mresult, Minsn}), .dataOut(MWIR)
    );

    // ========Writeback========
    wire [NUM_CTRL-1:0] Wctrlbus = MWIR[NUM_CTRL+63:64];
    wire [31:0] Winsn = MWIR[31:0];

    mux4 #(.WIDTH(5)) writeRegMux(ctrl_writeReg, Wctrlbus[1:0], Winsn[26:22], 5'bx, 5'd30, 5'd31);
    assign ctrl_writeEnable = Wctrlbus[2];
    assign Wresult = MWIR[63:32];
    assign data_writeReg = Wresult;

	/* END CODE */
endmodule
