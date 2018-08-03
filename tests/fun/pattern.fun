datatype ('a,'b)    pair   = Pair   'a 'b
datatype ('a,'b,'c) triple = Triple 'a 'b 'c

letrec length = fun [       ] -> 0
                |   [ h : t ] -> 1 + length [ t ]
and   complex = fun (Triple [ Pair h1 h2 : t ] l  [ Pair a 2 : Pair 3 b : c ]) -> Pair (h2 + length [ t ] + b) a
                |   (Triple [                ] [] [ Pair 7 2 : x : c        ]) -> x
                |   default                                                    -> Pair 0 0
and  cons h [ t ] = [ h : t ]
and     map f = fun [       ] -> []
                |   [ h : t ] -> cons (f h) (map f [ t ])
in map complex [ Triple [ Pair 8 7 : .Exps ] [] [ Pair 9 2 : Pair 3 3 : Pair 2 2       : .Exps ]
               : Triple [                  ] [] [ Pair 7 2 : Pair 0 1 : Pair (-1) (-1) : .Exps ]
               : Triple [                  ] [] [                                              ]
               : .Exps
               ]

// [ Pair 10 9 : Pair 0 1 : Pair 0 0 : .Vals ]
