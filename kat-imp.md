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
 // ----------------------------------
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
 // ---------------------------------
    rule <s> bexp? B [ { KCELL | MEM } ] => push { KCELL | MEM } ; pop { B | MEM } ; eval ; #pred pop ... </s>

    syntax StatePred ::= "div-zero-error?"
 // --------------------------------------
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
 // -----------------------------------------------------------------------
    rule <s> abstract [ { KCELL | MEM } ] => #abstract keys(MEM) { KCELL | MEM } ... </s>
    rule <s> #abstract .Set STATE         => pop STATE                           ... </s>

    rule <s> #abstract (SetItem(X) XS) STATE   => #abstractKey X XS STATE                   ... </s>
    rule <s> #abstractKey X XS { KCELL | MEM } => #abstract XS { KCELL | MEM[X <- ?V:Int] } ... </s>
```

### Define `_subsumes?_`

Because the memory is fully abstract every time subsumption is checked, it's enough to check that the `k` cell is identical for subsumption.

```{.k .imp-kat}
    rule <s> { (B:Bool => .) ~> KCELL | _ } subsumes? [ { KCELL' | _ } ] ... </s>

    rule <s> { KCELL | _ } subsumes? [ { KCELL  | _ } ] => #true  ... </s>
    rule <s> { KCELL | _ } subsumes? [ { KCELL' | _ } ] => #false ... </s> requires KCELL =/=K KCELL'

  //  rule <s> { while ( BEXP ) BODY ~> REST    | MEM | BOOL } subsumes? [ STATE ] => { while ( BOOL ) BODY ~> REST    | MEM } subsumes? [ STATE ] ... </s>
  //  rule <s> { if ( BEXP ) S1 else S2 ~> REST | MEM | BOOL } subsumes? [ STATE ] => { if ( BOOL ) S1 else S2 ~> REST | MEM } subsumes? [ STATE ] ... </s>
endmodule
```
