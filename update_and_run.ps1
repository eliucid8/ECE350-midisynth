& '.\Test Files\asm.exe' '.\Test Files\Assembly Files\sort.s'
mv -Force '.\Test Files\Assembly Files\sort.mem' '.\Test Files\Memory Files\'
iverilog -c filelist.txt -o proc.vvp -Wimplicit -s Wrapper_tb
vvp proc.vvp