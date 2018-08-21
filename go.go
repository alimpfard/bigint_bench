package main

import (
	"fmt"
	"math/big"
)

func main() {
	i := big.NewInt(1);
	one := big.NewInt(1);
	for z := big.NewInt(2); z.Cmp(big.NewInt(500000)) < 0; {
		i.Mul(i,z);
		z.Add(z,one);
	}
	fmt.Println( i );
}
