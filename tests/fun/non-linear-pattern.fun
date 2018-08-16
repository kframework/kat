// 6

let f = fun x x -> x - 1
          | x y -> y
 in (f 3 3) + (f 2 4)
