use Math::BigInt lib => 'GMP,Pari';
use List::Util qw{reduce};

$result = reduce { $a->bmul($b) } Math::BigInt->new(1), (2..500000);

print $result;
