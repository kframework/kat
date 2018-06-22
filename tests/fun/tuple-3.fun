// testing two tuple arguments to a function

datatype ('a,'b) pair = Pair('a,'b)

let f Pair(a,b) Pair(x,y) = a Pair(x,y) + b Pair(x,y)
in f Pair(fun Pair(x,y) -> x * y - 3 + x + y, fun Pair(x,y) -> x + y * 7 - 2 - 4 + x) Pair(10,20)
