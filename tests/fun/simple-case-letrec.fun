// simple case with symbolic value

letrec f = fun 0 -> 0
           |   n -> n - 1
in f 13

// 12
