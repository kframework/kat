// 7

datatype ('a, 'b) pair = Pair 'a 'b

let f = fun (Pair x y) 0 -> y * x
        |   (Pair x y) p -> y + x
 in f (Pair 3 4) 1
