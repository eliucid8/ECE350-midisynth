# print out clock divider rates for different note frequencies
sys_clock = 50_000_000
base_freq = 27.5 # starts at a0
for j in range(8):
    for i in range(12):
        freq = base_freq * 2**(i/12)
        divider = int(sys_clock / (freq))
        # print(f"freq: {freq:.2f} Hz, divider: {divider}")
        print(f"freq: {freq:.2f} Hz, divider: {divider:#0{8}x}")
        # print(f"{divider:#0{8}x}")
    base_freq *= 2