#include <stdint.h>
#include <stdlib.h>

typedef union {
    uint32_t u;
    float f;
} float_bits_t;

typedef union {
    uint64_t u;
    double d;
} double_bits_t;

void c_print_freq(uint64_t bits) {
    double_bits_t y;
    y.u = bits;
    double mag = (y.d < 1e3) ? 1 :
        (y.d < 1e6)  ? 1e3 :
        (y.d < 1e9)  ? 1e6 :
        (y.d < 1e12) ? 1e9 : 1;
    const char* u = (y.d < 1e3) ? "" : 
        (y.d < 1e6)     ? "K": 
        (y.d < 1e9)     ? "M": 
        (y.d < 1e12)    ? "G" : "";
    printf("%.2f %sHz", y.d / mag, u);
}

void c_print_double(uint64_t bits, int digits) {
    double_bits_t y;
    y.u = bits;
    printf("%.*f", digits, y.d);
}

uint32_t c_double_literal(const char* d) {
    double_bits_t y;
    y.d = strtof(d, NULL);
    return y.u;
}

uint64_t c_freq_from_ht_lt(uint64_t f_fast, uint32_t ht, uint32_t lt) {
    double_bits_t freq_fast, freq_slow;
    freq_fast.u = f_fast;
    freq_slow.d = freq_fast.d / (double) (ht + lt);
    return freq_slow.u;
}

uint64_t c_int_to_double(uint32_t i) {
    double_bits_t res;
    res.d = (double) i;
    printf("Got: %d ~> %f\n", i, res.d);
    return res.u;
}

void test(uint64_t d) {
    double_bits_t v;
    v.u = d;
    printf("[BDPI Real] %f\n", v.d);
}