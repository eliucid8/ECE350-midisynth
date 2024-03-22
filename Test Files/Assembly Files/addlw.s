nop                     # testing lw after add
nop
nop
nop
addi    $r3,    $r0,    42
sw      $r3,    12($r0)         # mem[12] = 42
addi    $r3,    $r3,    -14
bne     $r3,    $r0,    test
addi    $r7,    $r0,    95
nop
nop
test:
addi    $r1,    $r0,    7       # $r1 = 7
add     $r2,    $r1,    $r0     # $r2 = 7
lw      $r1,    5($r2)          # $r1 = mem[7 + 5] = 42
nop
nop
nop
