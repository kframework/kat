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
    rule #branch => ^ iftrue | ^ iffalse
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
    syntax Strategy ::= "#abstract" Map State
 // -----------------------------------------
    rule <s> abstract [ <FUN> <k> KCELL </k> <env> ENV </env> <store> STORE </store> </FUN> ] => #abstract STORE <FUN> <k> KCELL </k> <env> ENV </env> <store> STORE </store> </FUN> ... </s>
    rule <s> #abstract .Map STATE                                                             => pop STATE                                                                           ... </s>

    rule <s> #abstract ((X |-> I:Int           => .Map) XS) <FUN> <store> STORE => STORE[X <- ?V:Int] </store> ... </FUN> ... </s>
    rule <s> #abstract ((X |-> closure(_, _)   => .Map) XS) _                                                             ... </s>
    rule <s> #abstract ((X |-> muclosure(_, _) => .Map) XS) _                                                             ... </s>
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
