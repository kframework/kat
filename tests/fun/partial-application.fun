// 12

let f x = fun [ h : t ] h -> x + h
          |   l         z -> x * z
and apply f = f 4
 in apply (f 3 [ 5 : 6 : .Vals ])
 //in f 3 [ 5 : 6 : .Vals ] 4

// apply (f 3 [ 5 : 6 : .Vals ])
// f 3 [ 5 : 6 : .Vals ] 4
// 12

// Note if non-linear patterns aren't taken care of with the partial application properly, you get
// 7
