Introduction
============

Here I define a strategy language for controlling symbolic execution, and show some simple analysis we can define from within K itself.
The language IMP is used as a running example, and the theory transformations over IMP's semantics are performed by hand.

Some time is spent building a robust strategy language.
This time would otherwise be spent extending a K backend, which would not be portable.

One design goal behind this effort is that the execution state of the program should be disturbed as little as possible.
Thus, the strategy language is used as an all-powerful of monitor that executes next to the program.
Computation that the strategy needs to accomplish should be done in the `strategy` cell, not on the `k` cell.

Compile the file `imp-kat.k` with the command `kompile --main-module IMP-KAT --syntax-module IMP-KAT imp-kat.k`.

IMP Language
============

The IMP language is largely defined as in the [K tutorial](www.kframework.org/index.php/K_Tutorial).
Refer there for a more detailed explanation of the language.

### Configuration

The IMP language has a `k` cell for execution and a `mem` cell for storage.
In IMP, base values are of sorts `Int` and `Bool`.

```{.k .imp-lang}
module IMP
  imports MAP

  configuration <imp>
                  <k> $PGM:Stmt </k>
                  <mem> .Map </mem>
                </imp>

  syntax KResult ::= Int | Bool
```

### Expressions

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

### Statements

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

### Semantics

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

Strategy Language
=================

A simple imperative strategy language is supplied here.
It has sequencing, choice, and looping (in addition to primitives related to controlling the execution state).

```{.k .strategy-lang}
requires "imp.k"

module STRATEGY-IMP
  imports IMP
  imports STRATEGY
  imports KCELLS

  configuration <strategy>
                  initSCell(Init)
                  <state> initImpCell(Init) </state>
                  <analysis> .Analysis </analysis>
                </strategy>

//  syntax Strategy ::= "strategy" ":" Strategy "=====" Stmt
  syntax State    ::= "#current" | Cell
  syntax Analysis ::= ".Analysis"

//  rule <s> strategy : S ===== PGM => S </s> <state> _ => <imp> <k> PGM </k> <mem> .Map </mem> </imp> </state>
endmodule
```

Strategy Predicates
-------------------

The strategy language has its own sort `Pred` for predicates, separate from the `Bool` usually used by programming languages.
Lazy semantics ("short-circuit") are given via controlled heating and cooling.

```{.k .strategy-lang}
module STRATEGY-HARNESS
  imports STRATEGY-IMP

  syntax Pred ::= "#true" | "#false" | "#pred" | "(" Pred ")" [bracket]
                | "not" Pred | Pred "or" Pred | Pred "and" Pred
//-------------------------------------------------------------
  rule <s> (not P => P ; not #pred) ; _ </s>
  rule <s> (#false ; not #pred => #true)  ; _ </s>
  rule <s> (#true  ; not #pred => #false) ; _ </s>

  rule <s> (P or Q => P ; #pred or Q) ; _ </s>
  rule <s> (#true  ; #pred or _ => #true) ; _ </s>
  rule <s> (#false ; #pred or Q => Q)     ; _ </s>

  rule <s> (P and Q ; S => P ; #pred and Q) ; _ </s>
  rule <s> (#true  ; #pred and Q ; S => Q)      ; _ </s>
  rule <s> (#false ; #pred and _ ; S => #false) ; _ </s>
```

```{.k .strategy-lang}
  syntax Pred ::= "bool?"
```


Strategy Statements
-------------------

The strategy language is a simple imperative language with sequencing and choice.

-   `skip` acts as a no-op strategy.
-   `{_}` and `(_)` are syntactically used to make blocks in the strategy language.
-   `_;_` is used to sequentially compose strategies.
-   `?_:_` (choice) uses the `Pred` value at the top of the strategy cell to determine what to execute next.
-   `_*` executes the given strategy until it cannot be executed anymore ("greedy Kleene star").
-   `_|_` tries executing the first strategy, and on failure executes the second.

```{.k .strategy-lang}
  syntax Strategy ::= Pred
                    | "skip"
                    | "{" Strategy "}"          [bracket]
                    | "(" Strategy ")"          [bracket]
                    | "?" Strategy ":" Strategy
                    > Strategy "*"
                    > Strategy ";" Strategy     [right]
                    > Strategy "|" Strategy     [right]
//-----------------------------------------------------
  rule skip ; S => S [structural]

  rule <s> (#true  ; ? S : _ => S) ; _ </s>
  rule <s> (#false ; ? _ : S => S) ; _ </s>

  rule <s> (S*     => try S ; ? S* : skip) ; _ </s>
  rule <s> (S | S' => try S ; ? skip : S') ; _ </s>
```

Strategy Primitives
-------------------

The current K backend will place the token `#STUCK` at the front of the `s` cell when execution cannot continue.
Here, a wrapper around this functionality is provided which will try to execute the given strategy and will roll back the state on failure.

-   `try_` executes a given strategy, placing `#true` on strategy cell if it succeeds and `#false` otherwise.

```{.k .strategy-lang}
  syntax priority try_ > _*
  syntax Strategy ::= "try" Strategy | "#try" State
//-------------------------------------------------
//  rule <s> (try S => S ; #try (state STATE)) ; _ </s> <state> STATE </state>
  rule <s> (#try STATE => #true)             ; _ </s>

  rule <s> #STUCK ~> SA:StrategyApply ; #try STATE ; S => load STATE ; #false ; S </s>
  rule <s> SA:StrategyApplied ~> S => S </s>
```

Strategies can manipulate the `state` cell (where program execution happens) and the `analysis` cell (a memory/storage for the strategy language).

-   `load_` places the given state into the execution harness.
-   `analysis_` sets the `analysis` cell to the given argument.

```{.k .strategy-lang}
  syntax Strategy ::= "load" State
//--------------------------------
  rule <s> (load #current      => skip) ; _ </s>
//  rule <s> (load (state STATE) => skip) ; _ </s> <state> _ => STATE </state>

  syntax Strategy ::= "analysis" Analysis
//---------------------------------------
  rule <s> (analysis A => skip) ; _ </s> <analysis> _ => A </analysis>
```

-   `step-with_` is used to specify that a given strategy should be executed admist heating and cooling.
-   `#step` should be defined for each programming language, specifying which transitions are proper steps.
-   `step` is `step-with_` instantiated to `#step`.

```{.k .strategy-lang}
  syntax Strategy ::= "step-with" Strategy
//----------------------------------------
  rule <s> (step-with S => (^ heat | ^ regular)* ; S ; (^ cool)*) ; _ </s>

  syntax Strategy ::= "step" | "#step"
//------------------------------------
  rule <s> (step => step-with #step) ; _ </s>
```

Strategy Macros
---------------

-   `can?_` tries to execute the given strategy, but restores the state afterwards.
-   `stuck?` checks if the current state can take a step.

```{.k .strategy-lang}
  syntax Pred ::= "can?" Strategy
//-------------------------------
//  rule <s> (can? S => try S ; ? load (state STATE) ; #true : #false) ; _ </s> <state> STATE </state>

  syntax Pred ::= "stuck?"
//------------------------
  rule <s> (stuck? => not can? step) ; _ </s>
```

-   `while__` allows looping behavior (controlled by sort `Pred`), and `while___` implements a bounded version.
-   `step-until_` will execute until a predicate holds, and `step-until__` implements a bounded version.

```{.k .strategy-lang}
  syntax priority while__ while___ > _*
  syntax Strategy ::= "while" Pred Strategy | "while" Int Pred Strategy
//---------------------------------------------------------------------
  rule <s> (while P S => P ; (? S ; while P S : skip)) ; _ </s>

  rule <s> (while 0 P S => skip) ; _ </s>
  rule <s> (while N P S => P ; (? S ; while (N -Int 1) P S : skip)) ; _ </s> requires N >Int 0

  syntax priority step-until_ step-until__ > _*
  syntax Strategy ::= "step-until" Pred | "step-until" Int Pred
//-------------------------------------------------------------
  rule <s> (step-until   P => while   (not P) step) ; _ </s>
  rule <s> (step-until N P => while N (not P) step) ; _ </s> requires N >Int 0
```

-   `exec_` executes the given state to completion, and `exec__` implements a bounded version.
    Note that `krun == exec #current`.
-   `eval_` executes a given state to completion and checks `bool?`, and `eval__` implements a bounded version.

```{.k .strategy-lang}
  syntax priority exec_ exec__ > _*
  syntax Strategy ::= "exec" State | "exec" Int State
//---------------------------------------------------
  rule <s> (exec         STATE => load STATE ; step-until   stuck?) ; _ </s>
  rule <s> (exec (N:Int) STATE => load STATE ; step-until N stuck?) ; _ </s>

  syntax priority eval_ eval__ > _*
  syntax Strategy ::= "eval" State | "eval" Int State
//---------------------------------------------------
//  rule <s> (eval         STATE => exec   STATE ; bool? ; load (state STATE')) ; _ </s> <state> STATE' </state>
//  rule <s> (eval (N:Int) STATE => exec N STATE ; bool? ; load (state STATE')) ; _ </s> <state> STATE' </state>
endmodule
```

K Analysis Tools (KAT)
======================

These modules define the "interfaces" to various analysis, and provide the implementation of those interfaces for IMP.
The syntax `strategy :_=====_` allows specifying a strategy and a program.
The strategy is loaded into the `strategy` cell, and the program is loaded into the `k` cell in the `imp` execution harness.

```{.k .imp-kat}
requires "imp.k"
requires "strategy.k"
requires "kat.k"

module IMP-KAT
  imports IMP-BIMC
  imports IMP-SBC
```

Often you'll want a way to translate from the sort `Bool` in the programming language to the sort `Pred` in the strategy language.

-   `bool?` checks if the `k` cell has just the constant `true`/`false` in it.

```{.k .imp-kat}
//  rule <s> (bool? => #true)  ; _ </s> <state> <k> true  </k> ... </state>
//  rule <s> (bool? => #false) ; _ </s> <state> <k> false </k> ... </state>
endmodule
```

Bounded Invariant Model Checking
--------------------------------

In bounded invariant model checking, the analysis being performed is a trace of the execution states that we have seen.

```{.k .kat}
module STRATEGY-BIMC
  imports STRATEGY-HARNESS

  syntax State
  syntax Pred

  syntax Trace ::= ".Trace"
                 | Trace ";" State

  syntax Analysis ::= Trace
```

-   `analysis-trace` sets the current analysis to a `Trace`.
-   `record` copies the current execution state to the end of the trace.

```{.k .kat}
  syntax Strategy ::= "record"
//----------------------------
//  rule <s> (record => skip) ; _ </s> <analysis> T => T ; S </analysis>
//                                     <state> S </state>
```

-   `assertion-failure` indicates that the given predicate failed within the execution bound
-   `assertion-success` inidicates that either the depth bound has been reached, or execution has terminated

```{.k .kat}
  syntax Strategy ::= "assertion-failure" Pred | "assertion-success"
```

Performing bounded invariant model checking is a simple macro in our strategy language.

-   `bimc` checks that the predicate holds for each step up to a search-depth bound.

```{.k .kat}
  syntax Strategy ::= "bimc" Int Pred
//-----------------------------------
  rule <s> ( bimc N P
           => { analysis .Trace
              ; record
              ; while N P
                  { step
                  ; record
                  }
              ; P ; ? assertion-success : assertion-failure P
              }
           )
           ; _
       </s>
endmodule
```

### Instantiating to IMP

Here we provide a way to make queries about the current IMP memory using IMP's `BExp` sort directly.

-   `bexp?` is a predicate that allows us to make queries about the current execution memory.

```{.k .imp-kat}
module IMP-BIMC
  imports IMP
  imports STRATEGY-BIMC

  syntax Pred ::= "bexp?" BExp
//----------------------------
//  rule <s> (bexp? B => eval (state <imp> <k> B </k> <mem> MEM </mem> </imp>)) ; _ </s> <state> <mem> MEM </mem> ... </state>
endmodule
```

### BIMC Examples

Here we check the property `x <= 7` for 5 steps of execution after the code has initialized (the `step` in front of the command).
Run this with `krun --search bimc.imp`.
Every solution should be checked for `assertion-failure_` or `assertion-success`.

```{.imp .bimc .k}
int x ;
x = 0 ;
x = x + 15 ;
```

### Future Work

-   This should extended to model checking more than invariants by defining the appropriate derivatives of your favorite temporal logic's formula.
-   We should be able to use arbitrary matching-logic patterns as sort `Pred`.

Semantics Based Compilation
---------------------------

Semantics based compilation uses symbolic execution to reduce the size of transition system defined by programming language semantics.
As the program is executed symbolically, the execution state is periodically "abstracted" with a language-specific abstraction operator.
The abstraction operator must be powerful enough to guarantee termination of every program in the language.
However, if the abstraction is too strong, the transition system will not be reduced in size very much, yielding worse compilation results.

As we execute, we'll collect new the states we've seen so far as a new `Rule` of the smaller transition system.
Anytime we reach a state which is subsumed by the left-hand-side of one of our generated rules, we'll stop exploring that path.

I've subsorted `Rules` into `Analysis`, and defined `Rules` as a cons-list of `Rule`.

```{.k .kat}
module STRATEGY-SBC
  imports STRATEGY-HARNESS

  syntax State
  syntax Pred

  syntax Rule ::= "<" State ">"
                | "<" State "-->" State ">"

  syntax Rules ::= ".Rules"
                 | Rules "," Rule

  syntax Analysis ::= Rules
```

The interface of this analysis requires you define when to abstract and how to abstract.
The instantiation to IMP is provided.

-   `cut-point?` is a predicate that should hold when abstraction should occur.
-   `abstract` is an operator than should abstract away enough details of the state to guarantee termination.
     Note that `abstract` needs to also take care not to destroy all information collected about the state in this execution.

```{.k .kat}
  syntax Pred ::= "cut-point?" | "abstract"
```

-   `subsumed?` is a predicate that checks if any of the left-hand sides of the rules `_subsumes_` the current state.
    Note that below we provide the instantiation of `_subsumes_` to IMP manually, but in principle this should inferred.

```{.k .kat}
  syntax Pred ::= "subsumed?" | State "subsumes" State
//----------------------------------------------------
  rule <s> (subsumed? => #subsumed? RS) ; _ </s> <analysis> RS </analysis>

  syntax Pred ::= "#subsumed?" Rules
//----------------------------------
  rule <s> (#subsumed? .Rules => #false)                                                      ; _ </s>
//  rule <s> (#subsumed? (RS , < LHS --> _ >) => (LHS subsumes (state STATE)) or #subsumed? RS) ; _ </s> <state> STATE </state>
```

At cut-points, we'll finish the rule we've been building, abstract the state, start a building a new rule from that state.

-   `begin-rule` will use the current state as the left-hand-side of a new rule in the record of rules.
-   `end-rule` uses the current state as the right-hand-side of a new rule in the record of rules.

```{.k .kat}
  syntax Strategy ::= "begin-rule"
//--------------------------------
//  rule <s> (begin-rule => skip) ; _ </s> <analysis> RS => RS , < state STATE > </analysis>
//                                         <state> STATE </state>

  syntax Strategy ::= "end-rule"
//------------------------------
//  rule <s> (end-rule => skip)   ; _ </s> <analysis> RS , (< LHS > => < LHS --> state STATE >) </analysis>
//                                         <state> STATE </state>
```

Finally, semantics based compilation is provided as a macro.

-   `compile` will execute a program using the given `cut-point?` and `abstract` operators until it has collected a complete set of rules.

```{.k .kat}
  syntax Strategy ::= "compile"
//-----------------------------
  rule <s> ( compile
          => { analysis .Rules
             ; abstract
             ; begin-rule
             ; while (not (stuck? or subsumed?))
                 { step-until (stuck? or cut-point?)
                 ; end-rule
                 ; abstract
                 ; begin-rule
                 }
             ; end-rule
             }
           )
           ; _
       </s>
       <analysis> _ => .Rules </analysis>
endmodule
```

### Instantiating to IMP

```{.k .imp-kat}
module IMP-SBC
  imports IMP
  imports STRATEGY-SBC

// Define `cut-point?`
//--------------------
  rule <s> (cut-point? => #true)  ; _ </s> <k> while _ _ ... </k>
  rule <s> (cut-point? => #false) ; _ </s> [owise]

// Define `abstract`
//------------------
  rule <s> (abstract => #abstract keys(MEM)) ; _ </s> <mem> MEM </mem>

  syntax Strategy ::= "#abstract" Set | "#abstractKey" Id
//-------------------------------------------------------
  rule <s> (#abstract .Set            => skip)                                          ; _ </s>
  rule <s> (#abstract (SetItem(X) XS) => { #abstractKey X ; #abstract XS }) ; _ </s>
  rule <s> (#abstractKey X => skip) ; _ </s> <mem> ... X |-> (_ => ?V:Int) ... </mem>

// Define `_subsumes_`
//--------------------
  rule <s> (state (<imp> <k> KCELL </k> _ </imp>) subsumes state (<imp> <k> KCELL  </k> _ </imp>) => #true)  ; _ </s>
  rule <s> (state (<imp> <k> KCELL </k> _ </imp>) subsumes state (<imp> <k> KCELL' </k> _ </imp>) => #false) ; _ </s> requires KCELL =/=K KCELL'
endmodule
```

### SBC Examples

Execute this test file with `krun --search sbc.imp`.
Every solution will have it's own trace of generated rules.

```{.imp .sbc .k}
int n , s ;

while (0 <= n) {
  n = n + - 1 ;
  s = s + n ;
}
```

### Future Work

-   Post-process the results of the compilation with another abstraction pass which just hashes the contents of the `k` cell for each rule.
    This will reduce the amount of extra matching that happens in executing the compiled definition.
-   Use matching-logic implication to implement `_subsumes_` in a language-indepedent way.

Corrective Model Checking
-------------------------

Corrective model-checking extends semantics based compilation by restricting the generated transition systems to only traces which satisfy the given property.
The strategy will only allow execution to continue if the property specified is satisfied.

Not implemented yet.
