let id    = fun x         -> x
and fst   = fun l r       -> l
and snd   = fun l r       -> r
and cons  = fun h t       -> [ h : t ]
and head  = fun [ h : t ] -> h
and tail  = fun [ h : t ] -> [ t ]
and apply = fun f d       -> f d
// in id 3
 in apply id (head (tail [ 3 : 5 : 7 : 9 : .Exps ]))

// Replace the `in` clause with your program.
