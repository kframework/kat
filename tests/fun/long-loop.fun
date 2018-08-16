// 0

// long loop

letrec longLoop = fun 0 x y z -> 0
                  |   c x y z ->
                        let y2 = y * x + (100 - z) in
                          let x2 = x + 1 in
                            let z2 = z * z * x2 in
                              let y3 = 30 + y2 in
                                let z3 = 15 * y2 in
                                  let c2 = c - 1 in
                                    longLoop c2 x2 y3 z3
in longLoop 3 0 0 0
