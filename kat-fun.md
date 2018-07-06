Instantiation of KAT
====================

The KAT requires some programming-language specific information to work.
Instantiation of the progamming language to KAT should happen with the language semantics on an as-needed basis.

The module `FUN-KAT` includes all the supported analysis for the FUN language.

```k
requires "fun.k"
requires "kat.k"

module FUN-ANALYSIS
    imports STRATEGY
    imports FUN-SBC
endmodule

module FUN-KAT
    imports FUN-UNTYPED
    imports KAT

    configuration <kat-FUN> initSCell(Init) initKatCell <harness> initFUNCell(Init) </harness> </kat-FUN>
```

### Define `push` and `pop`

Here the definition of a `State` for FUN is given, as well as the definitions of how to `push` and `pop` states.

```k
    syntax PreState ::= FUNCell
 // ---------------------------
    rule <s> push         => push FUNCELL ... </s> <harness> FUNCELL </harness>
    rule <s> pop  FUNCELL => .            ... </s> <harness> _ => FUNCELL </harness>
```

### Define `#branch` and `#normal`

```k
    rule #normal => ^ lookup | ^ assignment
    rule #branch => ^ iftrue | ^ iffalse | ^ caseSuccess | ^ caseFailure
    rule #loop   => ^ recCall
```

### Define `bool?`

```k
    rule <s> bool? [ <FUN> <k> true  ... </k> ... </FUN> ] => #true  ... </s>
    rule <s> bool? [ <FUN> <k> false ... </k> ... </FUN> ] => #false ... </s>
endmodule
```

SBC
---

```k
module FUN-SBC
    imports FUN-KAT
    imports KAT-SBC
    imports MATCHING
```

### Define `abstract`

```k
    rule <s> abstract [ <FUN> <k> KCELL                </k> <store> STORE                 </store> REST </FUN> ]
          => pop      ( <FUN> <k> #abstractArgs(KCELL) </k> <store> #abstractStore(STORE) </store> REST </FUN> )
         ...
         </s>

    syntax Map ::= #abstractStore ( Map ) [function]
 // ------------------------------------------------
    rule #abstractStore(.Map) => .Map

    rule #abstractStore (X |-> _:Int             XS) => X |-> ?V:Int            #abstractStore(XS)
    rule #abstractStore (X |-> _:Bool            XS) => X |-> ?V:Bool           #abstractStore(XS)
    rule #abstractStore (X |->   closure(RHO, E) XS) => X |->   closure(RHO, E) #abstractStore(XS)
    rule #abstractStore (X |-> muclosure(RHO, E) XS) => X |-> muclosure(RHO, E) #abstractStore(XS)

    syntax K ::= #abstractArgs ( K ) [function]
 // -------------------------------------------
    rule #abstractArgs(.K) => .K

    rule #abstractArgs(K                     ~> KS) => K               ~> #abstractArgs(KS) requires notBool isArg(K)
    rule #abstractArgs(#arg(_:Int)           ~> KS) => ?V:Int          ~> #abstractArgs(KS)
    rule #abstractArgs(#arg(_:Bool)          ~> KS) => ?V:Bool         ~> #abstractArgs(KS)
    rule #abstractArgs(#arg(closure(RHO, E)) ~> KS) => closure(RHO, E) ~> #abstractArgs(KS)
```

### Define `_subsumes?_`

Subsumption will be based on matching one `<k>` cell with the other.
This is correct because the memory is fully abstracted at the beginning of each rule.

**TODO**: We should be able to match on the entire configuration, not just the `<k>` cell.

```k
    rule <s> <FUN> <k> KCELL </k> ... </FUN> subsumes? <FUN> <k> KCELL' </k> ... </FUN>
          => #if #matches(KCELL', KCELL) #then #true #else #false #fi
         ...
         </s>
```

```k
endmodule
```
