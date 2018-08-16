// 3

// testing letrec and multiple arguments with currying

letrec head [ h : t ] = h
   and tail [ h : t ] = [ t ]
   and second l x     = head (tail l)
in second [ 1 : 3 : 5 : 2 : 4 : 0 : -1 : -5 : .Exps ] true
