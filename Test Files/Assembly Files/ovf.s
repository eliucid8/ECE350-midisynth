nop # sanity check for ovf
nop # 0100 | 0111 -> 4 + 7 = -5, which counts as ovf... rstatus written?
addi    $r1, $r1, 1
addi    $r3, $r3, 1
nop
sll     $r1, $r1, 30
sll     $r3, $r3, 31
addi    $r2, $r2, -1
nop
nop
sub     $r2, $r2, $r3
nop
nop
or      $r4, $r1, $r2
add     $r5, $r1, $r2

