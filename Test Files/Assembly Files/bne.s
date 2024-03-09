nop 	                # Simple bne test case no bypassing
nop                     # Author Unknown, Modified by Will Denton
nop     
nop
nop
nop
addi    $r1, $r0, 4     # $r1 = 4
addi    $r2, $r0, 5     # $r2 = 5
nop
nop
sub     $r3, $r0, $r1   # $r3 = -4
sub     $r4, $r0, $r2   # $r4 = -5
nop
nop
nop 	
bne 	$r1, $r2, b1	# $r1 != $r2 --> taken
nop			            # flushed instruction
nop			            # flushed instruction
addi 	$r20, $r20, 1	# $r20 += 1 (Incorrect)
addi 	$r21, $r21, 1	# $r21 += 1 (Incorrect)
addi 	$r22, $r22 1	# $r22 += 1 (Incorrect)
b1: 
addi 	$r10, $r10, 1	# $r10 += 1 (Correct)
bne 	$r2, $r2, b2	# r2 == r2 --> not taken
nop			            # nop in case of flush
nop			            # nop in case of flush
nop			            # Spacer
addi 	$r10, $r10, 1	# r10 += 1 (Correct) 
b2: 
nop			            # Landing pad for branch
nop			            # Avoid add RAW hazard
nop