// [7 : 8 : 9 : .Vals ]

// testing &, *, := and lists

let f x = x := @x + 1
and x = 7
in [x : f &x; x : f &x; x : .Exps ]

// When semantics was non-deterministic (not using seqstrict), could get:
// [7 : 9 : 8 : .Exps ] or [9 : 8 : 9 : .Exps ] or [9 : 9 : 8 : .Exps ]
