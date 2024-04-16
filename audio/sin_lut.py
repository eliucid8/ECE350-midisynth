import numpy as np

lut_length = 2** 7
max_val = 2**15 - 1
with open('sin_lut.mem', 'w') as f:
    for i in range (lut_length):
        val = int(max_val * (np.sin(i * np.pi/2 / lut_length)))
        hex_string = f"{val:#0{6}x}"
        f.write(hex_string[2:] + '\n')