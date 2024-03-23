module bypass_controller(
    FDrs, FDrt, FDrd,
    DXrs, DXrt, DXrd, 
    XMrd, MWrd, 
    bypassA, bypassB, 
    XM_reg_WE, MW_reg_WE,
    DX_rtin, DX_sw, DX_setx, DX_lw,
    FD_rtin, FD_sw, FD_setx,
    XM_lw, XM_sw,
    XAsel, XBsel, MWDsel, memstall
);
// register numbers
input[4:0] FDrs, FDrt, FDrd, DXrs, DXrt, DXrd, XMrd, MWrd;
// control signals
input bypassA, bypassB, XM_reg_WE, MW_reg_WE, DX_rtin, DX_sw, DX_setx, DX_lw, FD_rtin, FD_sw, FD_setx, XM_lw, XM_sw;

output[1:0] XAsel, XBsel;
output MWDsel, memstall;

/**
 * NOTE: we should never bypass if we'd be bypassing into r0.
 * XA bypassing: (we assume rs has already been assigned 30 in the case of a setx)
 * if bypassA && (XA == XMrd), XAsel = 1 (executeout)
 * else if XA == MWrd, XAsel = 2 (data_writereg)
 */
wire XAsel1, XAsel2;
wire[4:0] XA = DX_setx ? 5'd30 : DXrs;
assign XAsel1 = bypassA && (XA == XMrd) && XA && XM_reg_WE;
assign XAsel2 = bypassA && (XA == MWrd) && !XAsel1 && XA && MW_reg_WE;
assign XAsel = {XAsel2, XAsel1}; // XAsel1 and 2 should never turn on at the same time, so we can do this???

/*
 * XB bypassing: XB = rtin ? DXrd : DXrt
 * if bypassB && (XB == XMrd), XBsel = 1
 * else if XB == MWrd, XBsel = 2
 */
wire[4:0] XB = DX_rtin ? DXrd : DXrt;
wire XBsel1 = bypassB && (XB == XMrd) && XB && XM_reg_WE;
wire XBsel2 = bypassB && (XB == MWrd) && !XBsel1 && XB && MW_reg_WE;
assign XBsel = {XBsel2, XBsel1};

/* 
 * MWD (memory write data) bypassing: 
 * if XM_sw && (XMrd == MWrd),
 * MWDsel = 1
 */
assign MWDsel = XM_sw && (XMrd == MWrd) && XMrd && MW_reg_WE;

/* 
 * stall: stall in X stage?
 * memstall = XM_lw && ((XA == XMrd) || (XB == XMrd) && !DX_sw)
 * bypass MWrd value into MWD if we have sw there.
 */
wire[4:0] DA = FD_setx ? 5'd30 : FDrs;
wire[4:0] DB = FD_rtin ? FDrd : FDrt;
assign memstall = DX_lw && ((DA == DXrd) || (DB == DXrd) && !FD_sw);
endmodule