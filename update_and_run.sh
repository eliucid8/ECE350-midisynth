filename=$1
circ_pattern='INSTR_FILE = ".+?";'
replace_circ="INSTR_FILE = \"$filename\";"
sed -i -r "s/$circ_pattern/$replace_circ/g" Wrapper.v

tb_pattern='parameter FILE = ".+?"'
replace_tb="parameter FILE = \"$filename\";"
sed -i -r "s/$tb_pattern/$replace_tb/g" Wrapper_tb.v

'./Test Files/asm.exe' "./Test Files/Assembly Files/$filename.s"
mv -f "./Test Files/Assembly Files/$filename.mem" './Test Files/Memory Files/'
iverilog -c filelist.txt -o proc.vvp -Wimplicit -s Wrapper_tb
vvp proc.vvp