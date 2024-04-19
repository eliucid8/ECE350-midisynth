nop                 # discrete cosine transform algorithm
addi    $s0,    $s0,    -65536  # 17 bit minimum?
disp    $s0
addi    $s2,    $s2,    62  #loop bounds     
lutloop:
blt     $s2,    $s1,    halt
lw      $s4,    0($s0)
disp    $s4
addi    $s0,    $s0,    128
addi    $s1,    $s1,    1
j       lutloop
halt: j halt