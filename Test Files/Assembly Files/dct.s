nop                 # discrete cosine transform algorithm

# ====MAIN====

addi    $sp,    $0,     4096    # initialize sp to end of memory
addi    $s0,    $s0,    -65536  # 17 bit minimum?
addi    $t5,    $0,     -65536  # negative upper half
# disp    $s0
addi    $s2,    $s2,    15      # loop bounds     
addi    $t1,    $0,     32768   # sign bit mask
lutloop:
blt     $s2,    $s1,    _done_load_sin
lw      $s4,    0($s0)
and     $t3,    $s4,    $t1
sra     $t3,    $t3,    15
mul     $t4,    $t3,    $t5
add     $s4,    $s4,    $t4
disp    $s4
sw      $s4,    0($s1)
addi    $s0,    $s0,    4096
addi    $s1,    $s1,    1
j       lutloop
_done_load_sin:
addi    $s7,    $0,    -1
disp    $s7
disp    $s7
disp    $s7
disp    $s7
add     $s7,    $0,     $0

addi    $a0,    $0,     0
addi    $a1,    $0,     16
jal     dct

add     $s7,    $0,     $0

addi    $a0,    $0,     0
addi    $a1,    $0,     16
jal     print_array

halt:   j halt

# ====Inplace Discrete Cosine Transform====
# a0: memory address of array
# a1: length of array
dct:
    # disp    $a1
    nop  # FIX: bypassing error here
    addi    $t9,    $0,     3
    blt     $a1,    $t9,    _dct_base_case  # if N <= 2, go to base case. Second exit point. Ugh.

    # stack
    addi    $sp,    $sp,    -4
    sw      $s0,    0($sp)
    sw      $s1,    1($sp)
    sw      $s2,    2($sp)
    sw      $ra,    3($sp)

    add     $s0,    $a0,    0       # s0 = &vector[0]
    sra     $s1,    $a1,    1       # s1 = half = n / 2
    add     $s2,    $s1,    $s0     # s2 = &vector[len(vector)/2], i.e. start of second half
    
    jal dct_plus_minus

    # IDEA: use length of array as index of LUTs! LUT for len 4 goes from mem[4:7], lut for len 8 goes from mem[8:15], etc!

    addi    $a0,    $s2,    0     # a0 = &vector[half]
    addi    $a1,    $s1,    0       # assuming a1 still == n/2
    addi    $a2,    $s1,    16384   # dct_lut[len/2]
    jal		vector_mul

    jal     dct         # dct(vector[half:])

    addi    $a0,    $s0,    0
    addi    $a1,    $s1,    0
    jal     dct         # dct(vector[1:half])

    addi    $t0,    $s2,    1       # t0 = &vector[half + 1]
    add     $t1,    $s2,    $s1     # t1 = end of vector
    addi	$t1,    $t1,    -1      # t1 = vector[len-1]

    # disp    $s1
    # disp    $t0
    # disp    $t1

    # _dct_beta_sum_loop:
    #     blt     $t1,    $t0,    _dct_zip
    #     lw      $t2,    -1($t0)
    #     lw      $t3,    0($t0)
    #     add     $t2,    $t2,    $t3
    #     sw      $t2,    -1($t0)
    #     addi    $t0,    $t0,    1
    #     j _dct_beta_sum_loop

    _dct_zip:
    # addi    $at,    $0,    42
    # disp    $at

    addi    $a0,    $s0,    0
    sll     $a1,    $s1,    1
    jal     print_array 
    addi    $t9,    $0,    -1
    disp    $t9
    disp    $t9

    lw      $s0,    0($sp)
    lw      $s1,    1($sp)
    lw      $s2,    2($sp)
    lw      $ra,    3($sp)
    addi    $sp,    $sp,    4

jr      $ra

    _dct_base_case:     # dct(x[2]) = [x[0] + x[1], (x[0] - x[1])/sqrt(2)]
        addi    $t9,    $0,     46341       # 1/sqrt(2) * 2^16

        lw      $t0,    0($a0)
        lw      $t1,    1($a0)
        add     $t2,    $t0,    $t1
        sub     $t3,    $t0,    $t1
        mul     $t3,    $t3,    $t9
        sra     $t3,    $t3,    16
        sw      $t2,    0($a0)
        sw      $t3,    1($a0)
        addi    $a0,    $s2,    0

        # disp    $t2
        # disp    $t3
        # addi    $t9,    $0,    -1
        # disp    $t9

        jr      $ra


# ====DCT plus/minus split====
# a0: memory address of array
# a1: length of array
dct_plus_minus:
    # stack discipline baybey
    addi    $sp,    $sp,    -5
    sw      $s0,    0($sp)
    sw      $s1,    1($sp)
    sw      $s2,    2($sp)
    sw      $s3,    3($sp)
    sw      $s4,    4($sp)

    add     $s0,    $0,     $a0     # s0 = front half pointer
    add     $s1,    $s0,    $a1     # s1 = back half pointer
    addi    $s1,    $s1,    -1      # pointer points to actual array element
    sra     $s2,    $a1,    1       # s2 = half

    # plus/minus loop
    sra     $s4,    $s2,    1       # loop iteration limit
    addi    $s4,    $s4,    -1      # while i ($s3) < s4 ==> break if (s4 - 2) < i
    addi    $s3,    $0,     0       # i = 0
    # [t2    t3|t4     t5]
    _dct_pm_loop:
        blt     $s4,    $s3,    _dct_done_pm
        lw		$t2,    0($s0)		    # t2 = vector[i]
        lw		$t5,    0($s1)		    # t5 = vector[n-1 - i]
        add     $t7,    $s0,    $s2     # t7 = half + i
        sub     $t6,    $s1,    $s2     # t6 = n-1-half - i
        # [s0    t6|t7     s1]
        lw		$t3,    0($t6)		    # t3 = vector[half + i]
        lw		$t4,    0($t7)		    # t4 = vector[n-1-half - i]
        # [t2+t5  t3+t4|t2-t5  t3-t4]
        # [t0        t1|t8        t9]
        add     $t0,    $t2,    $t5
        add     $t1,    $t3,    $t4
        sub     $t8,    $t2,    $t5
        sub     $t9,    $t3,    $t4
        sw		$t0,    0($s0) 
        sw		$t1,    0($t6)
        sw		$t8,    0($t7)
        sw		$t9,    0($s1)
        # increment
        addi    $s3,    $s3,    1       # ++i
        addi    $s0,    $s0,    1       # ++front_half_pointer
        addi    $s1,    $s1,    -1      # --back_half_pointer
    j _dct_pm_loop
    
    _dct_done_pm:
    # restore stack
    lw      $s0,    0($sp)
    lw      $s1,    1($sp)
    lw      $s2,    2($sp)
    lw      $s3,    3($sp)
    lw      $s4,    4($sp)
    addi    $sp,    $sp,    5

    jr      $ra

# ====Element-wise vector multiplication====
# a0 *= a2
# a0 = start address of vector 1
# a1 = length of vector
# a2 = start address of vector 2
vector_mul:
    addi    $t0,    $a0,    0       # start index 1
    add     $t1,    $a0,    $a1     # stop index
    addi    $t1,    $t1,    -1      # iteration bounds
    addi    $t2,    $a2,    0       # start index 2

    # multiplies 2 at a time! loop unrolling technically...
    _vector_mul_loop:
        blt     $t1,    $t0,    _vector_mul_done
        lw      $t3,    0($t0)
        lw      $t4,    0($t2)
        lw      $t6,    1($t0)
        lw      $t7,    1($t2)

        mul     $t5,    $t3,    $t4
        mul     $t8,    $t6,    $t7
        sra     $t5,    $t5,    16
        sra     $t8,    $t8,    16
        sw      $t5,    0($t0)
        sw      $t8,    1($t0)

        addi    $t0,    $t0,    2
        addi    $t2,    $t2,    2
        j       _vector_mul_loop

    _vector_mul_done:
        jr      $ra

# ====print array====
# a0 = array start index
# a1 = number of entries to display
print_array:
    addi    $t0,    $a0,    0       # start index
    add     $t1,    $a0,    $a1     # stop index
    addi    $t1,    $t1,    -1

    _print_array_loop:
        blt     $t1,    $t0,    _print_array_ret
        lw      $t2,    0($t0)
        disp    $t2
        addi    $t0,    $t0,    1
        j _print_array_loop

    _print_array_ret:
        jr      $ra