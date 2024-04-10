nop                     # basic midi test

addi    $s0, $0, 0
addi    $s1, $0, 0      # prev midi message

_readloop:
    lw $s0, 8194($0)
    bne $s0, $0, _non_zero
j _readloop
_non_zero:
    bne $s0, $s1, _latch_note
j _readloop
_latch_note: # if midi_in != 0 && midi_in != last_midi_in
    add  $s1, $s0, $0
    disp $s1
j _readloop