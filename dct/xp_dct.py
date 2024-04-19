import numpy as np
import dct_lut

# reimplement the Discrete Cosine Transform (DCT) with fixed-point arithmetic
def xp_dct(vector):
    # just assume we're passed in a vector with a power of 2 length max of 512.

    n = len(vector)
    if n == 1:
        return vector.copy()
    
    half = n // 2
    assert half <= dct_lut.MAX_N
    gamma = vector[ : half]
    delta = vector[n - 1 : half - 1 : -1]
    alpha = xp_dct(gamma + delta)
    if n == 512:
        print("alpha", alpha)
    # create the DCT lookup table
    dct_lookup_table = dct_lut.dct_lut(half)
    beta = (((gamma - delta) * dct_lookup_table)//2**16)
    beta[:half-1] += beta[1:]

    ret = np.zeros_like(vector)
    ret[ : : 2] = alpha
    ret[1 : : 2] = beta
    return ret

np.set_printoptions(suppress=True, precision=6)
length = 512
test_vec = np.round(np.cos(np.pi* np.linspace(0.0, 1.0, length, endpoint=False)) * (2**15 - 1)).astype(int)
print(test_vec)
print(xp_dct(test_vec))