// [ 6 : 7 : 8 : .Exps ]

letrec cons h [ t ] = [ h : t ]
   and map  f       = fun [       ] -> [ ]
                      |   [ h : t ] -> cons (f h) (map f [ t ])
   and f x = x + 1
    in map f [ 5 : 6 : 7 : .Exps ]
