#include <iostream>
#include <gmpxx.h>

int main() {
    mpz_class r;
    r = 1;
    for (mpz_class z=2; z<500000; ++z)
        r *= z;
    std::cout << r << std::endl;
}
