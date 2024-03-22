nop                                     # sanity check for bypassing 
nop                                     # Author: Eric Liu
nop     # r10 contains test 1 success, r20 contains test 1 fails, etc. 
nop     # ====test 1: jal bypassing====
setx    1                               # $r30 indicates test number
jal     jtarg                           
bne     $r1     $r0,    good            # if r10 was correctly added to, branch down to good
addi    $r20,   $r0,    1               # otherwise suffer the consequences
addi    $r20,   $r0,    1
addi    $r20,   $r0,    1
j       bad                             
jtarg:                                  # while we're down here:
add     $r1,   $r31,   $r31             # add $ra to itself and add to $r10
jr      $r31                            # jr $ra
good:
addi    $r10,   $r0,    1
bad:
and     $r1,    $r0,    $r0             # zero everything out to make the exp file nice and neat.
and		$r31,   $r0,    $r0             
nop
nop
nop     # ====test 2: lw into bne bypassing====
setx    2
addi    $r1,    $r0,    39
addi    $r2,    $r0,    42
sw      $r1,    2($r0)
sw      $r2,    3($r0)                  # 0x18 (r30 changes to 2 here)
lw      $r3,    2($r0)
lw      $r4,    3($r0)
bne     $r3,    $r4,    good2
addi    $r21,   $r0,    1               # you messed up.
addi    $r21,   $r0,    1
addi    $r21,   $r0,    1
j       done2
good2:
addi    $r11,   $r0,    1
done2:
and     $r3,    $r0,    $r0
and     $r4,    $r0,    $r0
nop
nop
nop     # ====test 3: lw into blt bypassing====
setx    3
lw      $r3,    2($r0)                  # subtest 1
lw      $r4,    3($r0)
blt     $r3,    $r4,    good3
addi    $r22,   $r0,    1               # you messed up.
addi    $r22,   $r0,    1
addi    $r22,   $r0,    1
j       done3
good3:
addi    $r12,   $r0,    1
done3:
and     $r3,    $r0,    $r0
and     $r4,    $r0,    $r0

sll     $r12,   $r12,   1               # subtest 2
lw      $r3,    2($r0)
lw      $r4,    3($r0)
blt     $r4,    $r3,    bad3
j done32
bad3:
addi    $r22,   $r0,    1               # you messed up.
addi    $r22,   $r0,    1
addi    $r22,   $r0,    1
done32:
and     $r3,    $r0,    $r0             
and     $r4,    $r0,    $r0
setx    4       # ====ok its secretly test 4 now====
lw      $r4,    3($r0)                  # subtest 3
lw      $r3,    2($r0)
blt     $r3,    $r4,    good33
addi    $r22,   $r0,    1               # you messed up.
addi    $r22,   $r0,    1
addi    $r22,   $r0,    1
good33:
addi    $r12,   $r0,    1
done33:
and     $r3,    $r0,    $r0             
and     $r4,    $r0,    $r0

sll     $r12,   $r12,   1               # subtest 4
lw      $r4,    3($r0)
lw      $r3,    2($r0)
blt     $r4,    $r3,    bad34
j done34
bad34:
addi    $r22,   $r0,    1               # you messed up.
addi    $r22,   $r0,    1
addi    $r22,   $r0,    1
done34:
and     $r3,    $r0,    $r0             
and     $r4,    $r0,    $r0

and     $r1,    $r0,    $r0
and     $r2,    $r0,    $r0
and     $r3,    $r0,    $r0
and     $r4,    $r0,    $r0

