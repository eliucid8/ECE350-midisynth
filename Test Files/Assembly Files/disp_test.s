nop
addi $r10, $r0, 17
addi $r11, $r0, 0
_numtest:
disp $r11
addi $r11, $r11, 1
blt $r11, $r10, _numtest

_fibtest:
addi $r1, $r0, 1
addi $r4, $r0, 47  // end loop
addi $r4, $r4, -2
_fibloop:
blt $r4, $r3, _halt
disp $r3
disp $r2
add $r2, $r2, $r1
addi $r3, $r3, 1

blt $r4, $r3, _halt
disp $r3
disp $r1
add $r1, $r1, $r2
addi $r3, $r3, 1
j _fibloop
nop
_halt: j _halt