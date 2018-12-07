// 381

// testing two tuple arguments to a function

datatype ('a,'b) pair = Pair 'a 'b

let f (Pair a b) (Pair x y) = (a (Pair x y)) + (b (Pair x y))
in f (Pair (fun (Pair x y) -> x * y - 3 + x + y) (fun (Pair x y) -> x + y * 7 - 2 - 4 + x)) (Pair 10 20)

// ((fun (Pair x y) -> x * y - 3 + x + y) (Pair 10 20)) + ((fun (Pair x y) -> x + y * 7 - 2 - 4 + x) (Pair 10 20))
// (10 * 20 - 3 + 10 + 20) + (10 + 20 * 7 - 2 - 4 + 10)
// (200     - 3 + 30     ) + (10 + 140    - 6     + 10)
// (227                  ) + (154                     )
// 381
