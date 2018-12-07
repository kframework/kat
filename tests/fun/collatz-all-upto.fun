// 216

// Compute collatz up to symbolic bound

letrec
    allCollatz = fun 0 -> 0
                 |   n -> (collatz n) + allCollatz (n - 1)
and collatz = fun 1 -> 1
              |   n -> if n % 2 == 0 then
                         1 + collatz (n / 2)
                       else
                         1 + collatz (3 * n + 1)
in allCollatz 20
