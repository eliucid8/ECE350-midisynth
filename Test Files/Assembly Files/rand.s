nop
addi    $s0, $zero, 5000 // mmio addr of random device
addi    $t8, $zero, 100 // limit on randloop
addi    $t8, $t8, -2
and     $t9, $t0, $t0
_randloop:
    # blt     $t8, $t9, _halt
    lw      $s1, 0($s0)
    disp    $s1
    addi $t9, $t9, 1
    j _randloop

_halt: j _halt