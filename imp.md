IMP Language
============

The IMP language is largely defined as in the [K tutorial](www.kframework.org/index.php/K_Tutorial).
Refer there for a more detailed explanation of the language.

Configuration
-------------

The IMP language has a `k` cell for execution and a `mem` cell for storage.
In IMP, base values are of sorts `Int` and `Bool`.

```k
module IMP
    imports DOMAINS
```

```kcompile
    imports STRATEGY
```

```k
    configuration <imp>
                    <k> $PGM:Stmt </k>
                    <mem> .Map </mem>
                  </imp>

    syntax KResult ::= Int | Bool
```

### Symbolic Integers

```kcompile
    syntax Int ::= "symbolicInt" [function]
 // ---------------------------------------
    rule symbolicInt => ?V:Int
```

Expressions
-----------

IMP has `AExp` for arithmetic expressions (over integers).

```k
    syntax KItem ::= "div-zero-error"

    syntax AExp  ::= Int | Id
                   | AExp "/" AExp [left, seqstrict]
                   | AExp "*" AExp [left, seqstrict]
                   > AExp "-" AExp [left, seqstrict]
                   | AExp "+" AExp [left, seqstrict]
                   | "(" AExp ")"  [bracket]
 // ----------------------------------------
    rule I1 + I2 => I1 +Int I2
    rule I1 - I2 => I1 -Int I2
    rule I1 * I2 => I1 *Int I2
```

```kcompile
    rule  I / 0  => div-zero-error                      [tag(divzero)]
    rule I1 / I2 => I1 /Int I2     requires I2 =/=Int 0 [tag(divnonzero)]
```

```krun
    rule  I / 0  => div-zero-error
    rule I1 / I2 => I1 /Int I2     requires I2 =/=Int 0
```

IMP has `BExp` for boolean expressions.

```k
    syntax BExp  ::= Bool
                   | AExp "<=" AExp [seqstrict]
                   | AExp "<" AExp  [seqstrict]
                   | AExp "==" AExp [seqstrict]
                   | "!" BExp       [strict]
                   > BExp "&&" BExp [left, strict(1)]
                   | "(" BExp ")"   [bracket]
 // -----------------------------------------
    rule I1 <= I2   => I1 <=Int I2
    rule I1 <  I2   => I1 <Int  I2
    rule I1 == I2   => I1 ==Int I2
    rule ! T        => notBool T
    rule true  && B => B
    rule false && _ => false
```

IMP has `{_}` for creating blocks of statements.

```k
    syntax Block ::= "{" "}" | "{" Stmt "}"
 // ---------------------------------------
    rule {   } => .
    rule { S } => S
```

IMP has `int_;` for declaring variables and `_=_;` for assignment.

```k
    syntax Ids ::= List{Id,","}
    syntax Stmt ::= Block | "int" Ids ";"
 // -------------------------------------
    rule int .Ids ; => .
    rule <k> int (X, XS => XS) ; ... </k>
         <mem> MEM => MEM [ X <- 0 ] </mem>

    syntax Stmt ::= Id "=" AExp ";" [strict(2)]
 // -------------------------------------------
```

```kcompile
    rule <k> X:Id        => I ... </k> <mem> ... X |-> I        ... </mem> [tag(lookup)]
    rule <k> X = I:Int ; => . ... </k> <mem> ... X |-> (_ => I) ... </mem> [tag(assignment)]
```

```krun
    rule <k> X:Id        => I ... </k> <mem> ... X |-> I        ... </mem>
    rule <k> X = I:Int ; => . ... </k> <mem> ... X |-> (_ => I) ... </mem>
```

IMP has `if(_)_else_` for choice, `while(_)_` for looping, and `__` for sequencing.

```k
    syntax Stmt ::= "if" "(" BExp ")" Block "else" Block [strict(1)]
 // ----------------------------------------------------------------
```

```kcompile
    rule <k> if (true)  B1 else _  => B1 ... </k> [tag(iftrue)]
    rule <k> if (false) _  else B2 => B2 ... </k> [tag(iffalse)]
```

```krun
    rule <k> if (true)  B1 else _  => B1 ... </k>
    rule <k> if (false) _  else B2 => B2 ... </k>
```

```k
    syntax Stmt ::= "while" "(" BExp ")" Block
 // ------------------------------------------
```

```kcompile
    rule <k> while (B) STMT => if (B) {STMT while (B) STMT} else {} ... </k> [tag(whileIMP)]
```

```krun
    rule <k> while (B) STMT => if (B) {STMT while (B) STMT} else {} ... </k>
```

```k
    syntax Stmt ::= Stmt Stmt [left]
 // --------------------------------
    rule S1:Stmt S2:Stmt => S1 ~> S2

    syntax priority int_;_IMP _=_;_IMP if(_)_else__IMP while(_)__IMP > ___IMP
endmodule
```
