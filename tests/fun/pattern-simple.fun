datatype ('a,'b)    pair   = Pair   'a 'b
datatype ('a,'b,'c) triple = Triple 'a 'b 'c

let mylist1 = Triple [ Pair 8 7 : .Exps ] [] [ Pair 9 2 : Pair 3 3 : Pair 2 2       : .Exps ]
and mylist2 = Triple [                  ] [] [ Pair 7 2 : Pair 0 1 : Pair (-1) (-1) : .Exps ]
in letrec length = fun [       ] -> 0
                   |   [ h : t ] -> 1 + length [ t ]
      and complex = fun (Triple [ h : t ] l  [ Pair a 2 : x : c ]) -> Pair (1 + length [ t ]) a
                    |   (Triple [       ] [] [ Pair 7 2 : x : c ]) -> x
                    |   default                                    -> Pair 0 0
 in Pair (complex mylist1) (complex mylist2)

// Pair (Pair 1 9) (Pair 0 1)
