// 42

datatype 'a tree = Leaf | Tree ('a tree) 'a ('a tree)

letrec foldtree f b = fun Leaf                -> b
                      |   (Tree left n right) -> f n (foldtree f b left) (foldtree f b right)
   and f x y z = x + y + z
    in foldtree f 0 (Tree (Tree (Tree Leaf 3 Leaf) 6 (Tree Leaf 21 Leaf)) 1 (Tree Leaf 11 Leaf))

//      1
//     / \
//    6   11
//   / \
//  3  21
