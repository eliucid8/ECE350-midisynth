nop         # basic xor test
addi        $s0,    $s0,    258
sll         $s0,    $s0,    16
addi        $s0,    $s0,    1032
addi        $s1,    $0,     -1
disp        $s0
disp        $s1
xor         $s2,    $s0,    $s1
disp        $s2
addi        $s3,    $0,     -42
disp        $s3
sra         $s4,    $s3,    31      # m = s4 = s3 >> 31
xor         $s5,    $s4,    $s3     # s5 = (s4 ^ s3)
sub         $s3,    $s5,    $s4     # ret = s5 - s4
disp        $s3