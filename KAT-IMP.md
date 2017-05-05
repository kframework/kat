IMP Language
============

The IMP language is largely defined as in the [K tutorial](www.kframework.org/index.php/K_Tutorial).
Refer there for a more detailed explanation of the language.

Configuration
-------------

The IMP language has a `k` cell for execution and a `mem` cell for storage.
In IMP, base values are of sorts `Int` and `Bool`.

```{.k .imp-lang}
module IMP
  imports MAP
  imports STRATEGY


   configuration <imp>
                   <k> $PGM:Stmt </k>
                   <mem> .Map </mem>
                 </imp>

  syntax Analysis ::= ".Analysis"
  syntax KResult  ::= Int | Bool
```

Expressions
-----------

IMP has `AExp` for arithmetic expressions (over integers).

```{.k .imp-lang}
  syntax AExp  ::= Int | Id
                 | AExp "/" AExp [left, strict]
                 > AExp "+" AExp [left, strict]
                 | "(" AExp ")"  [bracket]
//----------------------------------------
  rule I1 / I2 => I1 /Int I2  requires I2 =/=Int 0
  rule I1 + I2 => I1 +Int I2
```

IMP has `BExp` for boolean expressions.

```{.k .imp-lang}
  syntax BExp  ::= Bool
                 | AExp "<=" AExp [seqstrict, latex({#1}\leq{#2})]
                 | "!" BExp       [strict]
                 > BExp "&&" BExp [left, strict(1)]
                 | "(" BExp ")"   [bracket]
//-----------------------------------------
  rule I1 <= I2   => I1 <=Int I2
  rule ! T        => notBool T
  rule true  && B => B
  rule false && _ => false
```

Statements
----------

IMP has `{_}` for creating blocks, `if_then_else_` for choice, `_:=_` for assignment, and `while(_)_` for looping.

```{.k .imp-lang}
  syntax Block ::= "{" "}"
                 | "{" Stmt "}"

  syntax Ids ::= List{Id,","}

  syntax Stmt  ::= Block
                 | "int" Ids ";"
                 | Id "=" AExp ";"                      [strict(2)]
                 | "if" "(" BExp ")" Block "else" Block [strict(1)]
                 | "while" "(" BExp ")" Block
                 > Stmt Stmt                            [left]
//------------------------------------------------------------
  rule {}              => .        [structural]
  rule {S}             => S        [structural]

  rule int .Ids ;      => .        [structural]
  rule S1:Stmt S2:Stmt => S1 ~> S2 [structural]

  rule <k> int (X,Xs => Xs) ; ... </k> <mem> Rho:Map (.Map => X |-> ?V:Int) </mem>
    requires notBool (X in keys(Rho))
```

Semantics
---------

All the rules above are "regular" rules, not to be considered transition steps by analysis tools.
The rules below are named (with the attribute `tag`) so that strategy-based analysis tools can treat them specially.

```{.k .imp-lang}
  rule <k> X:Id        => I ... </k> <mem> ... X |-> I        ... </mem> [tag(lookup)]
  rule <k> X = I:Int ; => . ... </k> <mem> ... X |-> (_ => I) ... </mem> [tag(assignment)]

  rule if (true)  B:Block else _ => B:Block [tag(if), transition]
  rule if (false) _ else B:Block => B:Block [tag(if), transition]

  rule while (B) STMT => if (B) {STMT while (B) STMT} else {} [tag(while)]
endmodule
```

Instantiation of KAT
====================

The KAT requires some programming-language specific information to work.
Instantiation of the progamming language to KAT should happen with the language semantics on an as-needed basis.

The module `IMP-KAT` includes all the supported analysis for the IMP language.

```{.k .imp-kat}
requires "imp.k"
requires "kat.k"

module IMP-KAT
  imports IMP-BIMC
  imports IMP-SBC
endmodule
```

BIMC
----

Here we provide a way to make queries about the current IMP memory using IMP's `BExp` sort directly.

-   `bexp?` is a predicate that allows us to make queries about the current execution memory.

```{.k .imp-kat}
module IMP-BIMC
  imports IMP
  imports KAT-BIMC

  syntax Pred ::= "bexp?" BExp
//----------------------------
  rule <s> bexp? B => eval (<k> B </k> <mem> MEM </mem>) ... </s> <mem> MEM </mem>
endmodule
```

### Example (Invariant Failure)

Here we check the property `x <= 7` for 5 steps of execution after the code has initialized (the `step` in front of the command).
Run this with `krun --search bimc.imp`.
Every solution should be checked for `assertion-failure_` or `assertion-success`.

```{.imp .bimc .k}
int x ;
x = 0 ;
x = x + 15 ;
```

### Example (Bound Reached)

### Example (Execution Terminates)

SBC
---

```{.k .imp-kat}
module IMP-SBC
  imports IMP
  imports KAT-SBC

// Define `cut-point?`
//--------------------
  rule <s> cut-point? => #true  ... </s> <k> while _ _ ... </k>
  rule <s> cut-point? => #false ... </s> [owise]

// Define `abstract`
//------------------
  rule <s> abstract => #abstract keys(MEM) ... </s> <mem> MEM </mem>

  syntax Strategy ::= "#abstract" Set | "#abstractKey" Id
//-------------------------------------------------------
  rule <s> #abstract .Set            => skip                          ... </s>
  rule <s> #abstract (SetItem(X) XS) => #abstractKey X ; #abstract XS ... </s>
  rule <s> #abstractKey X => skip ... </s> <mem> ... X |-> (_ => ?V:Int) ... </mem>

// Define `_subsumes_`
//--------------------
  rule <s> (<k> KCELL </k> <mem> _ </mem>) subsumes (<k> KCELL  </k> <mem> _ </mem>) => #true  ... </s>
  rule <s> (<k> KCELL </k> <mem> _ </mem>) subsumes (<k> KCELL' </k> <mem> _ </mem>) => #false ... </s> requires KCELL =/=K KCELL'
endmodule
```

### Example (Single Loop)

Execute this test file with `krun --search sbc.imp`.
Every solution will have it's own trace of generated rules.

```{.imp .sbc .k}
int n , s ;

while (0 <= n) {
  n = n + - 1 ;
  s = s + n ;
}
```

### Exmaple (Collatz)

### Example (Memory Walk)
