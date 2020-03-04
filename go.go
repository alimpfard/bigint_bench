package main

import (
	"fmt"
	"math/big"
)

func main() {
	i := big.NewInt(1);
	one := big.NewInt(1);
	huge := 500000;
	_i := 2
	for z := big.NewInt(2); _i < huge; _i+=1{
		i.Mul(i,z);
		z.Add(z,one);
	}
	fmt.Println( i );
}
