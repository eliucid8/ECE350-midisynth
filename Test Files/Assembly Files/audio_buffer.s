ab_poll_loop:
    lw      $s0,    8195($0)
    bne     $s0,    $0,     break_ab_poll_loop
    j ab_poll_loop

break_ab_poll_loop:
    lw      $s0,    -65536($0)
    nop
    nop
    disp    $s0
    j       ab_poll_loop