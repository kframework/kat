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
    syntax Strategy ::= "#case"        [function]
                      | "#caseSuccess" [function]
                      | "#caseFailure" [function]
                      | "#let"         [function]
 // ---------------------------------------------
    rule #normal => ^ lookup
                  | ^ applicationFocusFunction
                  | ^ applicationFocusArgument
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
    rule #case   => #caseSuccess
                  | #caseFailure
    rule #caseSuccess => ^ caseNonlinearMatchJoinSuccess
                       | ^ caseBoolSuccess
                       | ^ caseIntSuccess
                       | ^ caseStringSuccess
                       | ^ caseNameSuccess
                       | ^ caseConstructorNameSuccess
                       | ^ caseConstructorArgsSuccess
                       | ^ caseListSuccess
                       | ^ caseListEmptySuccess
                       | ^ caseListSingletonSuccess
                       | ^ caseListNonemptySuccess
    rule #caseFailure => ^ caseNonlinearMatchJoinFailure
                       | ^ caseBoolFailure
                       | ^ caseIntFailure
                       | ^ caseStringFailure
                       | ^ caseConstructorNameFailure
                       | ^ caseConstructorArgsFailure1
                       | ^ caseConstructorArgsFailure2
                       | ^ caseListEmptyFailure3
                       | ^ caseListEmptyFailure1
                       | ^ caseListEmptyFailure2
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
    rule <s> abstract => #abstractNames(keys(RHO)) ... </s>
         <FUN>
           <k> mu ( XS , E ) ... </k>
           <env> RHO </env>
           ...
         </FUN>

    syntax Strategy ::= #abstractNames ( Set  )
                      | #abstractName  ( Name )
 // -------------------------------------------
    rule <s> #abstractNames(.Set)          => .                                      ... </s>
    rule <s> #abstractNames(SetItem(X) XS) => #abstractName(X) ~> #abstractNames(XS) ... </s>

    rule <s> #abstractName(X) => . ... </s> <env> ... X |-> (V  => #abstractVal(V))   ... </env>
    rule <s> #abstractName(X) => . ... </s> <env> ... X |-> (VS => #abstractVals(VS)) ... </env>

    syntax Val  ::= #abstractVal  ( Val  ) [function]
    syntax Vals ::= #abstractVals ( Vals ) [function]
 // -------------------------------------------------
    rule #abstractVals(_:Vals) => ?VS:Vals

    rule #abstractVal(_:Int)    => ?I:Int
    rule #abstractVal(_:Bool)   => ?B:Bool
    rule #abstractVal(_:String) => ?S:String

    rule #abstractVal(_:ConstructorVal) => ?CV:ConstructorVal
    rule #abstractVal(CV:ClosureVal)    => CV:ClosureVal
    rule #abstractVal([VS])             => valList(#abstractVals(VS))
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
