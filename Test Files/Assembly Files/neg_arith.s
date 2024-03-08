nop             # Basic Arithmetic Test with no Hazards
nop             # Values initialized using addi (positive only) and sub
nop             # Author: Oliver Rodas
nop
nop
nop             # Initialize Values
addi $3, $0, 1    # r3 = 1
addi $4, $0, 35    # r4 = 35
addi $1, $0, 3    # r1 = 3
addi $2, $0, 21    # r2 = 21
sub $3, $0, $3    # r3 = -1
sub $4, $0, $4    # r4 = -35
nop 
nop             # Negative Value Tests
addi $11, $2, -89    # r11 = r2 - 89 = -68
add $12, $4, $2    # r12 = r4 + r2 = -14
sub $13, $4, $2    # r13 = r4 - r2 = -56
sll $14, $3, 16    # r14 = r3 << 16 = -65536
sra $15, $4, 16    # r15 = r4 >> 16 = -1