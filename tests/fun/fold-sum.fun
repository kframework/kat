// 55

letrec cons h [ t ] = [ h : t ]
   and fold f b = fun [       ] -> b
                  |   [ h : t ] -> f h (fold f b [ t ])
   and f x y = x + y
   and nat n m = if n == m then [ n : .Vals ] else cons n (nat (n + 1) m)
    in fold f 0 (nat 0 10)
