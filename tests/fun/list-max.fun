// max of a list

letrec max = fun [h] x y -> h
             |   [h|t] x y -> let x = max t x y
                              in  if h > x then h else x
in max [1, 3, -1, 2, 5, 0, -6] true (-10)