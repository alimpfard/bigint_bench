package test.bigint;

import java.math.BigInteger;

fun main() {
    println(
        (1..500000).fold(1.toBigInteger(), {
            acc: BigInteger, i: Int -> acc * i.toBigInteger()
        })
    );
}
