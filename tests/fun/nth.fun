// [ 10 : 11 : 12 : 13 : 14 : .Vals ]

letrec
    nat n m = if n == m then [ n : .Vals ]
                        else cons n (nat (n + 1) m)
and length = fun [     ] -> 0
             |   [h : t] -> 1 + length [ t ]
and nth = fun 1 [ h : t ] -> h
          |   n [ h : t ] -> nth (n - 1) [ t ]
and cons h [ t ] = [ h : t ]
and map f = fun [       ] -> []
              | [ h : t ] -> cons (f h) (map f [ t ])
and app = fun [       ] x -> []
            | [ h : t ] x -> cons (h x) (app [ t ] x)
 in app (map nth (nat 1 5)) [ 10 : 11 : 12 : 13 : 14 : 15 : 16 : 17 : .Exps ]
