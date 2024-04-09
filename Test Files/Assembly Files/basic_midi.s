nop                     # basic midi test

addi    $s0, $0, 0
_readloop:
    lw $s0, 8194($0)
    disp $s0
    bne $s0, $0, _doneread
j _readloop

_doneread:
    disp $s0
halt: j halt