// 55

letrec
    sumrec = fun 0 m -> m
               | n m -> sumrec (n - 1) (m + n)
and sum n = sumrec n 0
 in sum 10
