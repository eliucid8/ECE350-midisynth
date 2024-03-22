nop 				# Advanced Control Test with Bypassing
nop 				# Values initialized using addi (positive only)
nop 				# Registers 10,11 track correct and 20,21 track incorrect
nop 				# Values in the first two tests be updated if the number of lines is modified
nop 				# Author: Nathaniel Brooke
nop
nop
nop 				    # Test Bypassing into JR
addi $r31, $r0, 12		# r31 = 12
nop				        # Avoid RAW hazard for jr
addi $r31, $r0, 16		# r31 = 16 (with RAW hazard)
jr $r31     			# PC = r31 = 16
addi $r20, $r20, 1		# r20 += 1 (Incorrect)
addi $r20, $r20, 1		# r20 += 1 (Incorrect)
addi $r20, $r20, 1		# r20 += 1 (Incorrect)
addi $r20, $r20, 1		# r20 += 1 (Incorrect)
addi $r10, $r10, 1		# r10 += 1 (Correct)
add $r11, $r10, $r11		# Accumulate r10 score
add $r21, $r20, $r21		# Accumulate r20 score
and $r10, $r0, $r10		# r10 should be 1
and $r20, $r0, $r20		# r20 should be 0
nop
nop 				# Test JAL into JR
addi $r31, $r0, 32		# r31 = 32
nop				# Avoid RAW hazard for jr
jal j1				# jal to jr (with RAW hazard)
nop				# Spacer
nop				# Spacer
j end1				# Jump to test cleanup
nop				# Spacer
nop				# Spacer
j1: jr $r31 			# jr immediately after jal
addi $r20, $r20, 1		# r20 += 1 (Incorrect)
addi $r20, $r20, 1		# r20 += 1 (Incorrect)
end1: nop			# Landing pad for jump
add $r11, $r10, $r11		# Accumulate r10 score
add $r21, $r20, $r21		# Accumulate r20 score
and $r10, $r0, $r10		# r10 should be 0
and $r20, $r0, $r20		# r20 should be 0
nop
nop 				# Test Bypassing into Branch (with loops)
addi $r1, $r0, 5		# r1 = 5
b1: addi $r2, $r2, 1		# r2 += 1
blt $r2, $r1, b1		# if r2 < r1 take branch (5 times)
b2: addi $r1, $r1, 1		# r1 += 1
addi $r3, $r3, 2		# r3 += 2
blt $r3, $r1, b2		# if r3 < r1 take branch (4 times)
add $r10, $r2, $r3		# r10 = r2 + r3
add $r11, $r10, $r11		# Accumulate r10 score
add $r21, $r20, $r21		# Accumulate r20 score
and $r10, $r0, $r10		# r10 should be 15
and $r20, $r0, $r20		# r20 should be 0
nop
nop 				# Test bypassing into bex
setx 0				# r30 = 0
nop				# Avoid RAW hazard from first setx
setx 10				# r30 = 10 (with RAW hazard)
bex e1				# r30 != 0 --> taken
addi $r20, $r20, 1		# r20 += 1 (Incorrect)
addi $r20, $r20, 1		# r20 += 1 (Incorrect)
addi $r20, $r20, 1		# r20 += 1 (Incorrect)
addi $r20, $r20, 1		# r20 += 1 (Incorrect)
addi $r20, $r20, 1		# r20 += 1 (Incorrect)
e1: addi $r10, $r10, 1		# r10 += 1 (Correct)
add $r11, $r10, $r11		# Accumulate r10 score
add $r21, $r20, $r21		# Accumulate r20 score
and $r10, $r0, $r10		# r10 should be 1
and $r20, $r0, $r20		# r20 should be 0
nop
nop 				# Test Branch/Jump Race Condition
addi $r4, $r0, 1		# r4 = 1
nop				# Avoid RAW hazard
bne $r4, $r0, rgood		# Branch racing (should branch)
j rbad				# Jump racing (should not jump)
nop				# Spacer
nop				# Spacer
nop				# Spacer
nop				# Spacer
rbad: nop			# Landing pad for jump
addi $r20, $r20, 1		# r20 += 1 (Incorrect)
addi $r20, $r20, 1		# r20 += 1 (Incorrect)
j end2				# Jump to test cleanup
nop				# Spacer
rgood: nop			# Landing pad for branch
addi $r10, $r10, 1		# r10 += 1 (Correct)
addi $r10, $r10, 1		# r10 += 1 (Correct)
end2: nop			# Landing pad for jump
nop				# Avoid RAW hazard
add $r11, $r10, $r11		# Accumulate r10 score
add $r21, $r20, $r21		# Accumulate r20 score
and $r10, $r0, $r10		# r10 should be 2
and $r20, $r0, $r20		# r20 should be 0
nop
nop 				# Final Check (All Correct)
and $r0, $r11, $r11		# r11 should be 19
and $r0, $r21, $r21		# r21 should be 0