Instantiation of KAT
====================

The KAT requires some programming-language specific information to work.
Instantiation of the progamming language to KAT should happen with the language semantics on an as-needed basis.

The module `IMP-KAT` includes all the supported analysis for the IMP language.

```k
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

    configuration <kat-imp> initSCell(Init) initKatCell <harness> initImpCell(Init) </harness> </kat-imp>
```

### Define `push` and `pop`

Here the definition of a `State` for IMP is given, as well as the definitions of how to `push` and `pop` states.

```k
    syntax State ::= ImpCell
 // ------------------------
    rule <s> push         => push IMPCELL ... </s> <harness> IMPCELL </harness>
    rule <s> pop  IMPCELL => .            ... </s> <harness> _ => IMPCELL </harness>
```

### Define `#transition` and `#normal`

```k
    rule #transition => ^ iftrue | ^ iffalse | ^ divzero | ^ divnonzero
    rule #normal     => ^ whileIMP | ^ lookup | ^ assignment
```

### Define `bool?`

```k
    rule <s> bool? [ <imp> <k> true  ... </k> ... </imp> ] => #true  ... </s>
    rule <s> bool? [ <imp> <k> false ... </k> ... </imp> ] => #false ... </s>
endmodule
```

BIMC
----

Here we provide a way to make queries about the current IMP memory using IMP's `BExp` sort directly.

-   `bexp?` is a predicate that allows us to make queries about the current execution memory.

```k
module IMP-BIMC
    imports IMP-KAT
    imports KAT-BIMC

    syntax StatePred ::= "bexp?" BExp
 // ---------------------------------
    rule <s> bexp? B [ <imp> <k> KCELL </k> <mem> MEM </mem> </imp> ]
          => push <imp> <k> KCELL </k> <mem> MEM </mem> </imp>
          ~> pop  <imp> <k> B     </k> <mem> MEM </mem> </imp>
          ~> eval
          ~> #pred pop
         ...
         </s>
endmodule
```

SBC
---

```k
module IMP-SBC
    imports IMP-KAT
    imports KAT-SBC
```

### Define `abstract`

IMP will abstract by turning all the values in memory into fresh symbolic values.

```k
    syntax Strategy ::= "#abstract" Set State
 // -----------------------------------------
    rule <s> abstract [ <imp> <k> KCELL </k> <mem> MEM </mem> </imp> ] => #abstract keys(MEM) <imp> <k> KCELL </k> <mem> MEM </mem> </imp> ... </s>
    rule <s> #abstract .Set STATE                                      => pop STATE                                                        ... </s>

    rule <s> #abstract ((SetItem(X) => .Set) XS) <imp> <mem> MEM => MEM[X <- ?V:Int] </mem> ... </imp> ... </s>
```

### Define `_subsumes?_`

Because the memory is fully abstract every time subsumption is checked, it's enough to check that the `k` cell is identical for subsumption.

```k
    rule <s> <imp> <k> KCELL </k> ... </imp> subsumes? <imp> <k> KCELL' </k> ... </imp>
          => #if KCELL ==K KCELL' #then #true #else #false #fi
         ...
         </s>
endmodule
```
