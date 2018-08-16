// non-terminating

letrec
    x = y + 1
and y = x * 2
 in x + y
