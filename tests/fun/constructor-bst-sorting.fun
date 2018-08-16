// [ 0 : 0 : 1 : 1 : 2 : 2 : 3 : 3 : 4 : 4 : 5 : 5 : .Vals ]

datatype 'a bst = Empty
                | Leaf 'a
                | Node ('a bst) 'a ('a bst)

letrec cons h [ t ] = [ h : t ]
   and bst_sort l = flatten (mk_bst l)
   and flatten = fun Empty        -> [] 
                 |   (Leaf n)     -> cons n []
                 |   (Node l n r) -> append (flatten l) (cons n (flatten r))
   and append = fun [       ] r -> r
                |   [ h : t ] r -> cons h (append [ t ] r)
   and mk_bst = fun [       ] -> Empty
                |   [ h : t ] -> insert (mk_bst [ t ]) h
   and insert = fun Empty        n -> Leaf n
                |   (Leaf m)     n -> insert (Node Empty m Empty) n
                |   (Node l m r) n -> if n < m
                                       then Node (insert l n) m r
                                       else Node l m (insert r n)
   and downto = fun 0 -> cons 0 []
                |   n -> cons n (downto (n - 1))
   and upto = fun 0 -> cons 0 []
               |  n -> append (upto (n - 1)) (cons n [])
   and merge = fun [         ] [         ] -> []
                 | [ h1 : t1 ] [ h2 : t2 ] -> cons h1 (cons h2 (merge [ t1 ] [ t2 ]))
   and shuffle n = merge (downto n) (upto n)
 in bst_sort (shuffle 5)
