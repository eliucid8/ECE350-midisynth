nop 			# Basic Memory Test with no Hazards
nop
nop
nop 			# Initialize Values
addi    $3, $0, 1	# r3 = 1
addi    $4, $0, 35	# r4 = 35
addi    $1, $0, 3	# r1 = 3
addi    $2, $0, 21	# r2 = 21
sub     $3, $0, $3	# r3 = -1
sub     $4, $0, $4	# r4 = -35
nop
nop
nop
nop 
nop 			# Store Words:
sw		$1, 0($2)		# mem[21] = 3
sw		$3, 1($2)		# mem[22] = -1
nop
nop
nop
nop
nop 
lw		$5, 0($2)		# r5 = mem[21] = 3
lw      $6, 1($2)       # r6 = mem[22] = -1


