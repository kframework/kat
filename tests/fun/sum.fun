// sum program

letrec sum = fun 0 -> 0
             |   n -> n + sum (n - 1)
in sum 100

// 5050
