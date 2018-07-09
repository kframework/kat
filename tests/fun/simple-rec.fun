// simple recursion

letrec simple = fun 0 -> 0
                |   n -> simple(n - 1)
in simple(symbolicInt)