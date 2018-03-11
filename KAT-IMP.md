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
  imports STRATEGY
  imports DOMAINS

  configuration <imp>
                  <k> $PGM:Stmt </k>
                  <mem> .Map </mem>
                </imp>

  syntax KResult  ::= Int | Bool
```

Expressions
-----------

IMP has `AExp` for arithmetic expressions (over integers).

```{.k .imp-lang}
  syntax KItem ::= "div-zero-error"

  syntax AExp  ::= Int | Id
                 | AExp "/" AExp [left, strict]
                 | AExp "*" AExp [left, strict]
                 > AExp "-" AExp [left, strict]
                 | AExp "+" AExp [left, strict]
                 | "(" AExp ")"  [bracket]
//----------------------------------------
  rule I1 + I2 => I1 +Int I2
  rule I1 - I2 => I1 -Int I2
  rule I1 * I2 => I1 *Int I2
  rule <k>  I / 0 ~> _ => div-zero-error </k>                      [tag(divzero)]
  rule <k> I1 / I2     => I1 /Int I2 ... </k> requires I2 =/=Int 0 [tag(div)]
```

IMP has `BExp` for boolean expressions.

```{.k .imp-lang}
  syntax BExp  ::= Bool
                 | AExp "<=" AExp [seqstrict]
                 | AExp "<" AExp  [seqstrict]
                 | AExp "==" AExp [seqstrict]
                 | "!" BExp       [strict]
                 > BExp "&&" BExp [left, strict(1)]
                 | "(" BExp ")"   [bracket]
//-----------------------------------------
  rule I1 <= I2   => I1 <=Int I2
  rule I1 <  I2   => I1 <Int  I2
  rule I1 == I2   => I1 ==Int I2
  rule ! T        => notBool T
  rule true  && B => B
  rule false && _ => false
```

IMP has `{_}` for creating blocks of statements.

```{.k .imp-lang}
  syntax Block ::= "{" "}" | "{" Stmt "}"
//---------------------------------------
  rule {}  => .
  rule {S} => S
```

IMP has `int_;` for declaring variables and `_=_;` for assignment.

```{.k .imp-lang}
  syntax Ids ::= List{Id,","}
  syntax Stmt ::= Block | "int" Ids ";"
//-------------------------------------
  rule int .Ids ; => .
  rule <k> int (X,Xs => Xs) ; ... </k> <mem> Rho:Map (.Map => X |-> ?V:Int) </mem> requires notBool (X in keys(Rho))

  syntax Stmt ::= Id "=" AExp ";" [strict(2)]
//-------------------------------------------
  rule <k> X:Id        => I ... </k> <mem> ... X |-> I        ... </mem> [tag(lookup)]
  rule <k> X = I:Int ; => . ... </k> <mem> ... X |-> (_ => I) ... </mem> [tag(assignment)]
```

IMP has `if(_)_else_` for choice, `while(_)_` for looping, and `__` for sequencing.

```{.k .imp-lang}
  syntax Stmt ::= "if" "(" BExp ")" Block "else" Block
//----------------------------------------------------
  rule <k> true  ~> if (BE) B else _ => B ... </k> [tag(ifeval)]
  rule <k> false ~> if (BE) _ else B => B ... </k> [tag(ifeval)]
  rule <k> if (BE) B else B' => BE ~> if (BE) B else B' ... </k> [tag(ifIMP)]

  syntax Stmt ::= "while" "(" BExp ")" Block
//------------------------------------------
  rule <k> while (B) STMT => if (B) {STMT while (B) STMT} else {} ... </k> [tag(whileIMP)]

  syntax Stmt ::= Stmt Stmt [left]
//--------------------------------
  rule S1:Stmt S2:Stmt => S1 ~> S2

  syntax priority int_;_IMP _=_;_IMP if(_)_else__IMP while(_)__IMP > ___IMP
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

module IMP-ANALYSIS
  imports STRATEGY
  imports IMP-BIMC
  imports IMP-SBC
endmodule

module IMP-KAT
  imports IMP
  imports KAT

  configuration <kat-imp> initSCell(Init) initKatCell initImpCell(Init) </kat-imp>
```

### Define `push` and `pop`

Here the definition of a `State` for IMP is given, as well as the definitions of how to `push` and `pop` states.

```{.k .imp-kat}
  syntax State ::= "{" K "|" Map "}"
//----------------------------------
  rule <s> push                => push { KCELL | MEM } ... </s> <imp> <k> KCELL      </k> <mem> MEM      </mem> </imp>
  rule <s> pop { KCELL | MEM } => .                    ... </s> <imp> <k> _ => KCELL </k> <mem> _ => MEM </mem> </imp>
```

### Define `#transition` and `#normal`

```{.k .imp-kat}
  rule <s> #transition => ^ ifIMP | ^ divzero                                     ... </s>
  rule <s> #normal     => ^ whileIMP | ^ ifeval | ^ lookup | ^ assignment | ^ div ... </s>
```

### Define `bool?`

```{.k .imp-kat}
  rule <s> bool? [ { true  | _ } ] => #true  ... </s>
  rule <s> bool? [ { false | _ } ] => #false ... </s>
endmodule
```

BIMC
----

Here we provide a way to make queries about the current IMP memory using IMP's `BExp` sort directly.

-   `bexp?` is a predicate that allows us to make queries about the current execution memory.

```{.k .imp-kat}
module IMP-BIMC
  imports IMP-KAT
  imports KAT-BIMC

  syntax StatePred ::= "bexp?" BExp
//---------------------------------
  rule <s> bexp? B [ { KCELL | MEM } ] => push { KCELL | MEM } ; pop { B | MEM } ; eval ; #pred pop ... </s>

  syntax StatePred ::= "div-zero-error?"
//--------------------------------------
  rule <s> div-zero-error? [ { div-zero-error | _ } ] => #true  ... </s>
  rule <s> div-zero-error? [ { KCELL          | _ } ] => #false ... </s> requires KCELL =/=K div-zero-error
endmodule
```

SBC
---

```{.k .imp-kat}
module IMP-SBC
  imports IMP-KAT
  imports KAT-SBC

  syntax State ::= "{" K "|" Map "|" Bool "}"

  rule <s> next-states [ { . | _ } ] => skip ... </s> [strucural]
//  rule <s> next-states [ { while ( BEXP:BExp ) BODY ~> REST | MEM } ]
//        => push { while ( BEXP ) BODY ~> REST | MEM | true  }
//         ; push { while ( BEXP ) BODY ~> REST | MEM | false }
//         ...
//       </s>
  rule <s> next-states [ { if ( BEXP:BExp ) S1 else S2 ~> REST | MEM } ]
        => push { true  ~> if ( BEXP ) S1 else S2 ~> REST | MEM }
         ; push { false ~> if ( BEXP ) S1 else S2 ~> REST | MEM }
         ...
       </s>

//  rule <s> pop { while ( BEXP ) BODY ~> REST     | MEM | BOOL } => pop { while ( BOOL ) BODY ~> REST    | MEM } ... </s>
  rule <s> pop { if ( BEXP ) S1 else S2  ~> REST | MEM | BOOL } => pop { BOOL ~> if ( BEXP ) S1 else S2 ~> REST | MEM } ... </s>
```

### Define `cut-point?`

IMP will have a cut-point at the beginning of every `while` loop, allowing every execution of IMP to terminate.

```{.k .imp-kat}
  rule <s> cut-point? [ STATE ] => pop STATE ; can? (^ whileIMP) ... </s> requires STATE =/=K #current
```

### Define `abstract`

IMP will abstract by turning all the values in memory into fresh symbolic values.

```{.k .imp-kat}
  syntax Strategy ::= "#abstract" Set State | "#abstractKey" Id Set State
//-----------------------------------------------------------------------
  rule <s> abstract [ { KCELL | MEM } ] => #abstract keys(MEM) { KCELL | MEM } ... </s>
  rule <s> #abstract .Set STATE         => pop STATE                           ... </s>

  rule <s> #abstract (SetItem(X) XS) STATE   => #abstractKey X XS STATE                   ... </s>
  rule <s> #abstractKey X XS { KCELL | MEM } => #abstract XS { KCELL | MEM[X <- ?V:Int] } ... </s>
```

### Define `_subsumes?_`

Because the memory is fully abstract every time subsumption is checked, it's enough to check that the `k` cell is identical for subsumption.

```{.k .imp-kat}
  rule <s> { B:Bool ~> KCELL | _ } subsumes? [ { KCELL  | _ } ] => #true  ... </s>
  rule <s> { B:Bool ~> KCELL | _ } subsumes? [ { KCELL' | _ } ] => #false ... </s> requires KCELL =/=K KCELL'

//  rule <s> { while ( BEXP ) BODY ~> REST    | MEM | BOOL } subsumes? [ STATE ] => { while ( BOOL ) BODY ~> REST    | MEM } subsumes? [ STATE ] ... </s>
//  rule <s> { if ( BEXP ) S1 else S2 ~> REST | MEM | BOOL } subsumes? [ STATE ] => { if ( BOOL ) S1 else S2 ~> REST | MEM } subsumes? [ STATE ] ... </s>
endmodule
```
