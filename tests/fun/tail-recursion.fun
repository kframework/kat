// 0

// This tail recursive program uses fixed memory, but can take a lot of
// computation/stack space if the semantics is not tail-recursive.
// Curiously, the tail recursion rule does not seem to be favoured by
// maude: (1) it is not applied, preferring to apply the normal
// environment-recovery rule; and (2) it slows down significantly
// this program (4-5 times!), because it makes maude's matcher slower.

datatype nothing = Nothing

letrec f n Nothing = if n > 0 then f (n - 1) Nothing else 0
in f 100 Nothing
