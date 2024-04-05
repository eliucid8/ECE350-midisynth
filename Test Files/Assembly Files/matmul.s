nop                             # basic test of dct via matrix multiplication
addi    $sp, $0, 4096           # set sp to end of memory
nop
nop
addi    $s0, $0, 32767
sw      $s0, 0($0)
addi    $s0, $0, 32767
sw      $s0, 1($0)
addi    $s0, $0, 32767
sw      $s0, 2($0)
addi    $s0, $0, 32767
sw      $s0, 3($0)

addi    $s0, $0, 30273
sw      $s0, 4($0)
addi    $s0, $0, 12539
sw      $s0, 5($0)
addi    $s0, $0, -12539
sw      $s0, 6($0)
addi    $s0, $0, -30273
sw      $s0, 7($0)

addi    $s0, $0, 23170
sw      $s0, 8($0)
addi    $s0, $0, -23170
sw      $s0, 9($0)
addi    $s0, $0, -23170
sw      $s0, 10($0)
addi    $s0, $0, 23170
sw      $s0, 11($0)

addi    $s0, $0, 12539
sw      $s0, 12($0)
addi    $s0, $0, -30273
sw      $s0, 13($0)
addi    $s0, $0, 30273
sw      $s0, 14($0)
addi    $s0, $0, -12539
sw      $s0, 15($0)

addi    $s0, $0, 30273
sw      $s0, 16($0)
addi    $s0, $0, 12539
sw      $s0, 17($0)
addi    $s0, $0, -12539
sw      $s0, 18($0)
addi    $s0, $0, -30273
sw      $s0, 19($0)


addi    $s6, $0, 0                  # loop iterator
addi    $s7, $0, 4                  # loop limit
addi    $s2, $0, 20                 # output vec addr
_matmul_loop:
    mul     $a0, $s6, $s7           # vec1 = i * n
    addi    $a1, $0, 16            # vec2 = i + 16
    addi    $a2, $s7, 0             # len = n
    
    # disp    $a0
    # disp    $a1

    addi    $sp, $sp, -4
    sw      $s6, 0($sp)
    sw      $s7, 1($sp)
    sw      $s2, 2($sp)
    jal     dotmul                  # dotmul()
    lw      $s6, 0($sp)
    lw      $s7, 1($sp)
    lw      $s2, 2($sp)
    addi    $sp, $sp, 4
    
    sw      $v0, 0($s2)             # *output_vec = dotmul()

    addi    $s6, $s6, 1             # i++
    addi    $s2, $s2, 1             # output_vec++

    bne     $s6, $s7, _matmul_loop

addi    $t1, $0, 0                 
addi    $t2, $0, 4                 
_ploop:                             # print vector results
lw      $t0, 20($t1)
disp    $t0
addi    $t1, $t1, 1
bne     $t1, $t2, _ploop          # confirm that lws worked

halt: j halt
# Dot product on two vectors--scales result down by 2^15 (ideally 2^15 - 1)
# $a0: start of vec a, $a1: start of vec b, $a2: length of vectors
dotmul:
addi    $s0, $0, 0                  # s0 is accumulator register
addi    $t8, $0, 0                  # t8 is loop iterator
add     $t9, $0, $a2
_dotmul_loop:
    lw      $s1, 0($a0)
    lw      $s2, 0($a1)
    # disp    $s1
    # disp    $s2
    # disp    $0
    mul     $s3, $s1, $s2
    add		$s0, $s0, $s3
    addi    $t8, $t8, 1
    addi    $a0, $a0, 1
    addi    $a1, $a1, 1
    bne     $t8, $t9, _dotmul_loop

sra     $s0, $s0, 16  # 14 + length of vector
add     $v0, $0, $s0
# disp    $v0
jr		$ra					

