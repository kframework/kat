// [ 1 : 2 : 3 : 4 : 5 : .Vals ]

let
    cons h [ t ] = [ h : t ]
 in
letrec
    map f  = fun [       ] -> [ ]
             |   [ h : t ] -> cons (f h) (map f [ t ])
and nats   = fun -> cons 1 (map (fun n -> n + 1) nats)
and take n = fun [       ] -> [ ]
             |   [ h : t ] -> if n > 0 then cons h (take (n - 1) [ t ]) else [ ]
 in take 5 [ 1 : 2 : 3 : 4 : 5 : 6 : 7 : .Exps ]
