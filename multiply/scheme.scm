(define fact 
  (lambda (n) (if (< n 2) n (* n (fact (- n 1))))))

(display (fact 500000))
