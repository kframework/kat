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

**TODO**: HACK!!!
          Rules `resetEnv` and `switchFocus` need to execute before `heatExps`, `heatCTorArgs`, and `unwrapApplication`.
          If the latter rules are allowed to execute first, K does not prune applications of them as infeasible properly.

```k
    syntax Strategy ::= "#case" [function]
                      | "#let"  [function]
 // --------------------------------------
    rule #normal => ^ lookup
                  | ^ applicationFocusFunction
                  | ^ applicationFocusArgument
                  | ^ resetEnv
                  | ^ listAssignment
                  | ^ assignment
                  | ^ allocate
                  | #let
    rule #loop   => ^ recCall
    rule #branch => #case
                  | ^ iftrue
                  | ^ iffalse
    rule #let    => ^ letBinds
                  | ^ letRecBinds
    rule #case   => ^ caseNonlinearMatchJoinSuccess
                  | ^ caseNonlinearMatchJoinFailure
                  | ^ caseBoolSuccess
                  | ^ caseBoolFailure
                  | ^ caseIntSuccess
                  | ^ caseIntFailure
                  | ^ caseStringSuccess
                  | ^ caseStringFailure
                  | ^ caseNameSuccess
                  | ^ caseConstructorNameSuccess
                  | ^ caseConstructorNameFailure
                  | ^ caseConstructorArgsSuccess
                  | ^ caseConstructorArgsFailure1
                  | ^ caseConstructorArgsFailure2
                  | ^ caseListSuccess
                  | ^ caseListEmptyFailure3
                  | ^ caseListEmptySuccess
                  | ^ caseListSingletonSuccess
                  | ^ caseListEmptyFailure1
                  | ^ caseListEmptyFailure2
                  | ^ caseListNonemptySuccess
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

**TODO**: Only abstracting the values in `RHO` will make references behave poorly.

```k
    rule <s> abstract [ <FUN> <k> muclosure ( RHO , CS ) ~> ARGS                </k> <store> STORE                              </store> REST </FUN> ]
          => pop        <FUN> <k> muclosure ( RHO , CS ) ~> #abstractArgs(ARGS) </k> <store> #abstractStore(values(RHO), STORE) </store> REST </FUN>
         ...
         </s>

    syntax K ::= #abstractArgs ( K ) [function]
 // -------------------------------------------
    rule #abstractArgs(#arg(V) ~> KS) => #arg(#abstractVal(V)) ~> #abstractArgs(KS)
    rule #abstractArgs(#arg(V))       => #arg(#abstractVal(V))
    rule #abstractArgs(KS           ) => KS [owise]

    syntax Map ::= #abstractStore ( List , Map ) [function]
 // -------------------------------------------------------
    rule #abstractStore(.List, RHO) => RHO

    rule #abstractStore(((ListItem(X) => .List) KEYS), ((X |-> (E:Exp   => E                )) XS))
    rule #abstractStore(((ListItem(X) => .List) KEYS), ((X |-> (V:Val   => #abstractVal (V ))) XS))
    rule #abstractStore(((ListItem(X) => .List) KEYS), ((X |-> (VS:Vals => #abstractVals(VS))) XS))

    syntax Val  ::= #abstractVal  ( Val  ) [function]
    syntax Vals ::= #abstractVals ( Vals ) [function]
 // -------------------------------------------------
    rule #abstractVals(_:Vals) => ?VS:Vals

    rule #abstractVal(_:Int)    => ?I:Int
    rule #abstractVal(_:Bool)   => ?B:Bool
    rule #abstractVal(_:String) => ?S:String

    rule #abstractVal(_:ConstructorVal) => ?CV:ConstructorVal
    rule #abstractVal(CV:ClosureVal)    => CV:ClosureVal
    rule #abstractVal([VS])             => [#abstractVals(VS)]
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
