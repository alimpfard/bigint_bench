
extern crate ramp;
use ramp::Int;

fn factorial(n: usize) -> Int {
   let mut a = Int::from(1);
   for i in 2..n {
       a *= i;
   }
   return a * n;
}

fn main() {
    println!("{}", factorial(500000));
}
