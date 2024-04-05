# ISA Reference
A reference for aspiring Liupercomputer programmers!

### Instructions
| Insn | Opcode | Type | Operation |
|------|--------|------|-----------|
|`add $rd, $rs, $rt`|00000 (00000)|R|$rd = $rs + $rt|
|`sub $rd, $rs, $rt`|00000 (00001)|R|$rd = $rs - $rt|
|`and $rd, $rs, $rt`|00000 (00010)|R|$rd = $rs & $rt|
|`or $rd, $rs, $rt`|00000 (00011)|R|$rd = $rs \| $rt|
|`sll $rd, $rs, shamt`|00000 (00100)|R|$rd = $rs << shamt|
|`sra $rd, $rs, shamt`|00000 (00101)|R|$rd = $rs >>> shamt|
|`mul $rd, $rs, $rt`|00000 (00110)|R|$rd = $rs * $rt|
|`div $rd, $rs, $rt`|00000 (00111)|R|$rd = $rs / $rt|
|`addi $rd, $rs, N`|00101|I|$rd = $rs + N|
|`sw \$rd, N(\$rs)`|00111|I|MEM[$rs + N] = $rd|
|`lw \$rd, N(\$rs)`|01000|I|\$rd = MEM[\$rs + N]|
|`j T`|00001|JI|PC = T|
|`bne $rd, $rs, N`|00010|I|if($rd != $rs), PC = PC + 1 + N|
|`jal T`|00011|JI|$r31 = PC + 1, PC = T|
|`jr $rd`|00100|JII|PC = $rd|
|`blt $rd, $rs, N`|00110|I|if($rd < $rs), PC = PC + 1 + N|
|`bex T`|10110|JI|if($rstatus != 0), PC = T|
|`setx T`|10101|JI|$rstatus = T|
|**CUSTOM INSNS**||||
|`disp $rd`|11000|JII|push $rd to 7 seg disp\*|

### Instruction Structure
| Insn Type | | | | | | | |
|-----------|-|-|-|-|-|-|-|
| R type: | opcode [31:27] | rd [26:22] | rs [21:17] | rt [16:12] | shamt [11:7] | aluop [6:2] | zero [1:0] |
| I type: | opcode [31:27] | rd [26:22] | rs [21:17] | immed [16:0] | | | |
| JI type: | opcode [31:27] | target [26:0] |
| JII type: | opcode [31:27] | rd [26:22] | zeroes [21:0] |

### (MIPS) Register Conventions 
|Name|Reg #|Convention|
|----|-----|----------|
|$zero, $0|0|**Constant** 0|
|$at|1|Use for pseudoinstructions|
|$v0-$v1|2-3|**Results**|
|$a0-$a3|4-7|**Arguments**|
|$t0-$t7|8-15|(Callee-Saved) temps|
|$s0-$s7|16-23|**Caller-Saved**|
|$t8-$t9|24-25|(Callee-Saved) temps|
|$k0-$k1|26-27|reserved for OS (Use for I/O?)|
|$gp|28|global pointer|
|$sp|29|**Stack Pointer**|
|$fp, $rstatus|30|**Status Register** (also frame pointer)|
|$ra|31|**Return Address**|



## I/O:
The simplest form of I/O is to the 7-segment display, which can be done using the `disp` instruction.
We also implement memory-mapped I/O: since the RAM block has only a 12-bit address space, loads/stores to any address above that will be intercepted and executed as I/O operations instead.

|Device|Address|Behavior|
|------|-------|--------|
|Pseudorandom Number Generator|`9000 (0x2328)`|**Load:** Loads a pseudorandom 32-bit value into the specified register (0 is not possible)|

## Clarifications
#### disp:
If `$rd` != 0, writes the data in that register to the buffer that the 7-segment display reads from.
If `$rd` == 0, writes the current instruction to the 7-segment display buffer.
#### overflow:
If an arithmetic instruction overflows or there is division by zero, the result isn't written to the original intended destination, but instead regsister `$r30`, also known as `$rstatus`. The written value corresponds to the operation that was originally meant to happen:
|Insn|Opcode|`rstatus` Value|
|-|-|-|
|add|00000 (00000)|1|
|addi|00101|2|
|sub|00000 (00001)|3|
|mul|00000 (00110)|4|
|div|00000 (00111)|5|
