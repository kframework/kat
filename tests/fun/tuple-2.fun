// 18

// testing functions taking tuple arguments

datatype ('a,'b,'c) triple = Triple 'a 'b 'c

let f (Triple x y z) = x + y + z * y + z - x + z * z - y
 in f (Triple 1 2 3)

// 1 + 2 + (3 * 2) + 3 - 1 + (3 * 3) - 2
// 1 + 2 + 6       + 3 - 1 + 9       - 2
// 9               + 11              - 2
// 18
