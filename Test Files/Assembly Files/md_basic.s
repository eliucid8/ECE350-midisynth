nop 			# Basic mult/div Test
nop
nop
nop 			# Initialize Values
addi    $1, $0, 3	# r1 = 3
addi    $2, $0, 21	# r2 = 21
addi    $3, $0, 1	# r3 = 1
addi    $4, $0, 35	# r4 = 35
nop
nop
nop
nop
nop 
mul     $5, $1, $2  # r5 = 3 * 21 = 63
div     $6, $4, $1  # r6 = 35 / 3 = 11
nop
nop
nop
nop
nop



