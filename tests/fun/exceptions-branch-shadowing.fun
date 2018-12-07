// 21

let x = 3
 in try (
      try (
        3 + throw(10) * 2
      ) catch(x) (
        if x == 10 then throw(2*x) else 7 + x
      )
    ) catch(x) (
      x + 1
    )
