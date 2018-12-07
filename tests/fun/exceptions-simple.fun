// 6

let x = 3
 in try (
      x + throw(2)
    ) catch(y) (
      y + 4
    )
