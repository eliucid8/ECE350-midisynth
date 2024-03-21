module bypass_controller(
    DXrs, DXrt, DXrd, 
    XMrd, MWrd, 
    bypassA, bypassB, 
    DX_rtin, DX_sw, DX_setx, 
    XM_lw, XM_sw,
    XAsel, XBsel, MWDsel, memstall
);
// register numbers
input[4:0] DXrs, DXrt, DXrd, XMrd, MWrd;
// control signals
input bypassA, bypassB, DX_rtin, DX_sw, DX_setx, XM_lw, XM_sw;

output[1:0] XAsel, XBsel;
output MWDsel, memstall;

/**
 * XA bypassing: (we assume rs has already been assigned 30 in the case of a setx)
 * if bypassA && (XA == XMrd), XAsel = 1 (executeout)
 * else if XA == MWrd, XAsel = 2 (data_writereg)
 */
wire XAsel1, XAsel2;
wire[4:0] XA = DX_setx ? 5'd30 : DXrs;
assign XAsel1 = bypassA && (XA == XMrd);
assign XAsel2 = bypassA && (XA == MWrd) && !XAsel1;
assign XAsel = {XAsel2, XAsel1}; // XAsel1 and 2 should never turn on at the same time, so we can do this???

/*
 * XB bypassing: XB = rtin ? DXrd : DXrt
 * if bypassB && (XB == XMrd), XBsel = 1
 * else if XB == MWrd, XBsel = 2
 */
wire[4:0] XB = DX_rtin ? DXrd : DXrt;
wire XBsel1 = bypassB && (XB == XMrd);
wire XBsel2 = bypassB && (XB == MWrd) && !XBsel1;
assign XBsel = {XBsel2, XBsel1};

/* 
 * MWD (memory write data) bypassing: 
 * if XM_sw && (XMrd == MWrd),
 * MWDsel = 1
 */
assign MWDsel = XM_sw && (XMrd == MWrd);

/* 
 * stall: stall in X stage?
 * memstall = XM_lw && ((XA == XMrd) || (XB == XMrd) && !DX_sw)
 * bypass MWrd value into MWD if we have sw there.
 */
assign memstall = XM_lw && ((XA == XMrd) || (XB == XMrd) && !DX_sw);
endmodule