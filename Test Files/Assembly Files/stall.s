nop             # Values initialized using addi (positive only)
nop             # Author: Oliver Rodas
nop
nop
nop             # EDGE CASE: Stalling 1 cycle for lw to ALUop
addi $1, $0, 830        # r1 = 830
nop            # Avoid RAW hazard to test only lw/sw
nop            # Avoid RAW hazard to test only lw/sw
sw $1, 2($0)         # mem[2] = r1 = 830
lw $4, 2($0)         # r4 = mem[2] = 830
addi $5, $4, 12        # r5 = r4 + 12 = 842    (M->D) 1 cycle stall required
addi $0, $0, 42      # padding to see what happens in the pipeline
addi $0, $0, 42
addi $0, $0, 42
addi $0, $0, 42
addi $0, $0, 42