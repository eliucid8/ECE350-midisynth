import numpy as np

MAX_N = 512

def dct_lut(n):
    # n = n // 2
    ret_string = ""
    lut_vals = 1/(np.cos(np.arange(0.5, n + 0.5) * (np.pi / n / 2)) * 2.0)
    rounded_lut_vals = np.round(lut_vals * 2**16).astype(int)
    # lut_lengths = {}
    # ret = np.zeros(n, dtype=np.int32)
    for i in range(n):
        cur = rounded_lut_vals[i]
        hex_string = f"{cur:06x}"
        ret_string += f"{hex_string}\n"
    # lut_lengths[len(binary_string)] = lut_lengths.get(len(binary_string), 0) + 1
    # num_bits = np.round(np.log2(lut_vals * 2**16)) + 1
    # precision_loss = 16 - num_bits
    # exponent_loss = precision_loss
    # if n == 256:
    #     exponent_loss[n//2 - 1] += 1 # 1 bit less for the last element because it has the same huffman string length as the 
    # pre_round_factor = 2**(16 + precision_loss +exponent_loss)
    # rounded_cosvector = np.round(lut_vals * pre_round_factor) / pre_round_factor
    # ret = np.round(rounded_cosvector * (2**16-1)).astype(int)
    # print(lut_vals)
    # print(ret / (2**16-1))
    # return ret

    # print(lut_lengths)
    return ret_string

with open("Test Files/Memory Files/dct_lut.mem", "w") as f:
    f.write(1*"000000\n")
    i = 1
    while i <= 256:
        f.write(dct_lut(i))
        i *= 2