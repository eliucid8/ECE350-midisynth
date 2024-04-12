nop
nop
addi $r1, $r1, 1
jal j1
j j3
addi $r3, $r3, 1
addi $r3, $r3, 1
j3: blt $r1, $r2, done1
addi $r3, $r3, 1
addi $r3, $r3, 1
addi $r3, $r3, 1
j1: addi $r2, $r2, 2
jr $r31
done1: nop
nop
bne $r4, $r5, dummy
jal j4
j done2
j4: addi $r4, $r4, 1
addi $r4, $r4, 1
jr $r31
done2:
nop
nop
nop
dummy: nop