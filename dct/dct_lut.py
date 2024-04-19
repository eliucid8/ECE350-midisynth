import numpy as np

MAX_N = 512

def dct_lut(n):
    # n = n // 2

    lut_vals = 1/(np.cos(np.arange(0.5, n + 0.5) * (np.pi / n / 2)) * 2.0)
    lut_lengths = {}
    ret = np.zeros(n, dtype=np.int32)
    # cur = int(np.round(lut_vals[i] * 2**16))
    # binary_string = format(cur, "b")
    # print(binary_string)
    # lut_lengths[len(binary_string)] = lut_lengths.get(len(binary_string), 0) + 1
    num_bits = np.round(np.log2(lut_vals * 2**16)) + 1
    precision_loss = 16 - num_bits
    exponent_loss = precision_loss
    if n == 256:
        exponent_loss[n//2 - 1] += 1 # 1 bit less for the last element because it has the same huffman string length as the 
    pre_round_factor = 2**(16 + precision_loss +exponent_loss)
    rounded_cosvector = np.round(lut_vals * pre_round_factor) / pre_round_factor
    ret = np.round(rounded_cosvector * (2**16-1)).astype(int)
    # print(lut_vals)
    # print(ret / (2**16-1))
    return ret

    # print(lut_lengths)

dct_lut(256)