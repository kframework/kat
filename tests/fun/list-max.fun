// max of a list

letrec max = fun [ h : .Exps ] -> h
             |   [ h : t     ] -> let x = max [ t ]
                                   in if h > x then h else x
in max [ 1 : 3 : -1 : 2 : 5 : 0 : -6 : .Exps ]

// 5
