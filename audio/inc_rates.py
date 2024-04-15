# print out LUT increment rates for different note frequencies
lut_length = 2**16
sample_rate = 48_000
base_freq = 27.5 # starts at a0
for j in range(8):
    for i in range(12):
        freq = base_freq * 2**(i/12)
        inc_rate = freq * (lut_length / (sample_rate * 2))
        # print(f"freq: {freq:.2f} Hz, divider: {divider}")
        # print(f"freq: {freq:.2f} Hz, divider: {divider:#0{8}x}")
        print(f"{int(inc_rate):#0{6}x}")
    base_freq *= 2