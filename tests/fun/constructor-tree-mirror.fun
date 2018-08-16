// (Tree (Tree (Tree (Leaf 5) (Leaf 4)) (Leaf 3)) (Tree (Leaf 2) (Leaf 1)))

datatype 'a tree = Leaf 'a
                 | Tree ('a tree) ('a tree)

letrec
   mirror = fun (Leaf n)   -> Leaf n
            |   (Tree l r) -> Tree (mirror r) (mirror l)
in mirror (Tree (Tree (Leaf 1) (Leaf 2)) (Tree (Leaf 3) (Tree (Leaf 4) (Leaf 5))))
