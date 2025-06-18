#include <stdint.h>

typedef union {
    uint32_t u;
    float f;
} float_bits_t;

typedef union {
    uint64_t u;
    double d;
} double_bits_t;

uint64_t c_freq_from_ht_lt(uint64_t f_fast, uint32_t ht, uint32_t lt) {
    double_bits_t freq_fast, freq_slow;
    freq_fast.u = f_fast;
    freq_slow.d = freq_fast.d / (double) (ht + lt);
    return freq_slow.u;
}

uint64_t c_int_to_double(uint32_t i) {
    double_bits_t res;
    res.d = (double) i;
    return res.u;
}

void test(uint64_t d) {
    double_bits_t v;
    v.u = d;
    printf("[BDPI Real] %f\n", v.d);
}