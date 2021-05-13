<?php
    echo array_reduce(range(2, 500000), 'gmp_mul', gmp_strval("1", 10));
?>
