// 12

// simple case in a "fake" letrec

letrec f = fun 0 -> 0
           |   n -> n - 1
in f 13
