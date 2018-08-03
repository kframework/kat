let id    x       = x
and fst   l r     = l
and snd   l r     = r
and cons  h [ t ] = [ h : t ]
and apply f d     = f d
and head [ h : t ] = h
and tail [ h : t ] = [ t ]
 in apply id (head (tail [ 3 : 5 : 7 : 9 : .Exps ]))

// 5
