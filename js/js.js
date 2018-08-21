let r = BigInt(1);

for(let a=2n; a<500000n; a++)
    r *= a;

console.log(r);
