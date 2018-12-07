// 18

letrec fold f b = fun [       ] -> b
                  |   [ h : t ] -> f h (fold f b [ t ])
   and f x y = x + y
    in fold f 0 [ 5 : 6 : 7 : .Exps ]
