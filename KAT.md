Introduction
============

The K Analysis Toolset (KAT) is a library of tools written in K itself for analyzing programming languages and programs.
KAT uses the K strategy language to control execution of the programming languages, making it extensible in K itself.

One design goal behind this effort is that the execution state of the program should be disturbed as little as possible.
Thus, the strategy language is used as an all-powerful of monitor that executes next to the program.
Computation that the strategy needs to accomplish should be done in the `strategy` cell, not on the `k` cell.

Compile this markdown document to the relevant K files using `./tangle`.
Compile the file `imp-kat.k` with the command `kompile --main-module IMP-KAT --syntax-module IMP-KAT imp-kat.k`.

Strategy Language
=================

A simple imperative strategy language is supplied here.
It has sequencing, choice, and looping (in addition to primitives related to controlling the execution state).

```{.k .kat}
requires "imp.k"

module KAT
  imports IMP
  imports KCELLS

  configuration <kat>
                  initSCell(Init)
                  initImpCell(Init)
                  <analysis> .Analysis </analysis>
                  <states> .States </states>
                </kat>

  syntax State    ::= "#current"
  syntax States   ::= ".States"
                    | State ":" States
  syntax Analysis ::= ".Analysis"
```

Strategy Predicates
-------------------

The strategy language has its own sort `Pred` for predicates, separate from the `Bool` usually used by programming languages.
Lazy semantics ("short-circuit") are given via controlled heating and cooling.

```{.k .kat}
  syntax Pred ::= "#true" | "#false" | "#pred" | "(" Pred ")" [bracket]
                | "not" Pred | Pred "or" Pred | Pred "and" Pred
//-------------------------------------------------------------
  rule <s> not P               => P ; not #pred ... </s> [structural]
  rule <s> #false ~> not #pred => #true         ... </s> [structural]
  rule <s> #true  ~> not #pred => #false        ... </s> [structural]

  rule <s> P or Q               => P ; #pred or Q ... </s> [structural]
  rule <s> #true  ~> #pred or _ => #true          ... </s> [structural]
  rule <s> #false ~> #pred or Q => Q              ... </s> [structural]

  rule <s> P and Q               => P ; #pred and Q ... </s> [structural]
  rule <s> #true  ~> #pred and Q => Q               ... </s> [structural]
  rule <s> #false ~> #pred and _ => #false          ... </s> [structural]
```

State predicates are evaluated over the current execution state.
If you declare something a `StatePred`, this code will automatically load the current state for you (making the definition of them easier).

```{.k .kat}
  syntax StatePred
  syntax Pred ::= StatePred | StatePred "[" State "]"
//---------------------------------------------------
  rule <s> SP:StatePred              => push ; SP [ #current ] ; pred-pop ... </s>                                   [structural]
  rule <s> SP:StatePred [ #current ] => SP [ STATE ]                      ... </s> <states> STATE : STATES </states> [structural]
```

Often you'll want a way to translate from the sort `Bool` in the programming language to the sort `Pred` in the strategy language.

-   `bool?` checks if the `k` cell has just the constant `true`/`false` in it and must be defined for each programming language.

```{.k .kat}
  syntax StatePred ::= "bool?"
//----------------------------
```

The current K backend will place the token `#STUCK` at the front of the `s` cell when execution cannot continue.
Here, a wrapper around this functionality is provided which will try to execute the given strategy and will roll back the state on failure.

-   `try?_` executes a given strategy, placing `#true` on strategy cell if it succeeds and `#false` otherwise.

```{.k .kat}
  syntax Pred      ::= "try?" Strategy
  syntax Exception ::= "#try"
//---------------------------
  rule <s> try? S => push ; S ~> #try     ... </s> [structural]
  rule <s> #try   => drop ; #true         ... </s> [structural]
  rule <s> #STUCK ~> (S:Strategy => .)    ... </s> [structural]
  rule <s> #STUCK ~> #try => pop ; #false ... </s> [structural]
  rule <s> SA:StrategyApplied => .        ... </s> [structural]
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

```{.k .kat}
  syntax Strategy ::= Pred
                    > "skip"
                    | "(" Strategy ")"          [bracket]
                    | "?" Strategy ":" Strategy
                    > Strategy "*"
                    > Strategy ";" Strategy     [right]
                    > Strategy "|" Strategy     [right]
//-----------------------------------------------------
  rule <s> skip    => .        ... </s> [structural]
  rule <s> S1 ; S2 => S1 ~> S2 ... </s> [structural]

  rule <s> #true  ~> ? S : _ => S ... </s> [structural]
  rule <s> #false ~> ? _ : S => S ... </s> [structural]

  rule <s> S*     => (try? S) ; ? S* : skip ... </s> [structural]
  rule <s> S | S' => (try? S) ; ? skip : S' ... </s> [structural]
```

Strategy Primitives
-------------------

Strategies can manipulate the `state` cell (where program execution happens) and the `analysis` cell (a memory/storage for the strategy language).

-   `push_` copies the current execution state onto the stack of states and must be provided by the programming language.
-   `pop_` places the given state in the execution harness and must be provided by the programming language.
-   `drop` removes the top element of the state stack (without placing it in the execution harness).
-   `swap` swaps the top two elements of the state stack.

```{.k .kat}
  syntax Strategy ::= "push" | "push" State
//-----------------------------------------
  rule <s> push STATE => . ... </s> <states> STATES => STATE : STATES </states> [structural]

  syntax Strategy ::= "pop" | "pop" State
//---------------------------------------
  rule <s> pop #current => skip      ... </s>                                             [structural]
  rule <s> pop          => pop STATE ... </s> <states> STATE : STATES => STATES </states> [structural]

  syntax Strategy ::= "drop" | "swap"
//-----------------------------------
  rule <s> swap => . ... </s> <states> S1 : S2 : STATES => S2 : S1 : STATES </states> [structural]
  rule <s> drop => . ... </s> <states> STATE : STATES   => STATES           </states> [structural]
```

-   `analysis_` sets the `analysis` cell to the given argument.

```{.k .kat}
  syntax Strategy ::= "analysis" Analysis
//---------------------------------------
  rule <s> analysis A => skip ... </s> <analysis> _ => A </analysis> [structural]
```

-   `step-with_` is used to specify that a given strategy should be executed admist heating and cooling.
-   `#step` defines what is a proper transition and must be provided by the programming language.
-   `step` is `step-with_` instantiated to `#step`.

```{.k .kat}
  syntax priority step-with_ > _*
  syntax Strategy ::= "step-with" Strategy | "#step" | "step"
//-----------------------------------------------------------
  rule <s> step-with S => (^ regular | ^ heat)* ; S ; (^ regular| ^ cool)* ... </s> [structural]
  rule <s> step        => step-with #step                                  ... </s> [structural]
```

Things added to the sort `StateOp` will automatically load the current state for you, making it easier to define operations over the current state.

```{.k .kat}
  syntax StateOp
  syntax Strategy ::= StateOp | StateOp "[" State "]"
//---------------------------------------------------
  rule <s> SO:StateOp              => push ; SO [ #current ] ; drop ... </s>                                   [structural]
  rule <s> SO:StateOp [ #current ] => SO [ STATE ]                  ... </s> <states> STATE : STATES </states> [structural]
```

Strategy Macros
---------------

-   `can?_` tries to execute the given strategy, but restores the state afterwards.
-   `stuck?` checks if the current state can take a step.

```{.k .kat}
  syntax Pred ::= "can?" Strategy
//-------------------------------
  rule <s> can? S => push ; (try? S) ; pred-pop ... </s> <imp> STATE </imp> [structural]

  syntax Pred ::= "stuck?"
//------------------------
  rule <s> stuck? => not can? step ... </s> [structural]
```

-   `if_then_else_` provides a familiar wrapper around the more primitive `?_:_` functionality.
-   `pred-pop` is useful for always popping a state but propagating the result of a predicate through.

```{.k .kat}
  syntax priority if_then_else_ > _*
  syntax Strategy ::= "if" Pred "then" Strategy "else" Strategy | "pred-pop"
//--------------------------------------------------------------------------
  rule <s> if P then S1 else S2 => P ; ? S1 : S2    ... </s> [structural]
  rule <s> #true  ~> pred-pop => pop ; #true  ... </s> [structural]
  rule <s> #false ~> pred-pop => pop ; #false ... </s> [structural]
```

-   `while__` allows looping behavior (controlled by sort `Pred`), and `while___` implements a bounded version.
-   `_until_` will execute the given strategy until a predicate holds, and `_until__` implements a bounded version.

```{.k .kat}
  syntax priority while__ while___ > _*
  syntax Strategy ::= "while" Pred Strategy | "while" Int Pred Strategy
//---------------------------------------------------------------------
  rule <s> while   P S => if P then S ; while            P S else skip ... </s>                   [structural]
  rule <s> while 0 P S => skip                                         ... </s>                   [structural]
  rule <s> while N P S => if P then S ; while (N -Int 1) P S else skip ... </s> requires N >Int 0 [structural]

  syntax priority _until_ _until__ > _*
  syntax Strategy ::= Strategy "until" Pred | Strategy "until" Int Pred
//---------------------------------------------------------------------
  rule <s> S until   P => while   (not P) S ... </s> [structural]
  rule <s> S until N P => while N (not P) S ... </s> [structural]
```

-   `exec` executes the given state to completion, and `exec_` implements a bounded version.
    Note that `krun === exec`.
-   `eval` executes a given state to completion and checks `bool?`, and `eval_` implements a bounded version.

```{.k .kat}
  syntax priority exec_ > _*
  syntax Strategy ::= "exec" | "exec" Int
//---------------------------------------
  rule <s> exec         => step until   stuck? ... </s> [structural]
  rule <s> exec (N:Int) => step until N stuck? ... </s> [structural]

  syntax priority eval_ > _*
  syntax StatePred ::= "eval" | "eval" Int
//----------------------------------------
  rule <s> eval   [ STATE ] => exec   ; bool? ... </s> [structural]
  rule <s> eval N [ STATE ] => exec N ; bool? ... </s> [structural]
endmodule
```

K Analysis Toolset (KAT)
========================

KAT is a set of formal analysis tools which can be instantiated (as needed) to your programming language.
Each tool has a well defined interface in terms of the predicates and operations you must provide over your languages state.

Bounded Invariant Model Checking
--------------------------------

In bounded invariant model checking, the analysis being performed is a trace of the execution states that we have seen.

```{.k .kat}
module KAT-BIMC
  imports KAT

  syntax Trace ::= ".Trace"
                 | Trace ";" State

  syntax Analysis ::= Trace
```

-   `record` copies the current execution state to the end of the trace.

```{.k .kat}
  syntax StateOp ::= "record"
//---------------------------
  rule <s> record [ STATE ] => . ... </s> <analysis> T => T ; STATE </analysis> [structural]
```

Performing bounded invariant model checking is a simple predicate in our strategy language.

-   `bimc` checks that the predicate holds for each step up to a search-depth bound.

```{.k .kat}
  syntax Pred ::= "bimc" Int Pred
//-------------------------------
  rule <s> ( bimc N P
          => analysis .Trace
           ; record
           ; (step ; record) until N (not P)
           ; P
           )
           ...
       </s>
endmodule
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
module KAT-SBC
  imports KAT

  syntax Rule ::= "<" State ">"
                | "<" State "-->" State ">"

  syntax Rules ::= ".Rules"
                 | Rules "," Rule

  syntax Analysis ::= Rules
```

The interface of this analysis requires you define when to abstract and how to abstract.

-   `cut-point?` is a predicate that should hold when abstraction should occur.
-   `_subsumes?` is a predicate on two states that should be provided by the language definition (indicating whether the first state is more general than the second).
-   `abstract` is an operator than should abstract away enough details of the state to guarantee termination.
     Note that `abstract` needs to also take care not to destroy all information collected about the state in this execution.

```{.k .kat}
  syntax StatePred ::= "cut-point?" | State "subsumes?"
//-----------------------------------------------------

  syntax StateOp ::= "abstract"
//-----------------------------
```

-   `subsumed?` is a predicate that checks if any of the left-hand sides of the rules `_subsumes_` the current state.

```{.k .kat}
  syntax Pred ::= "subsumed?" | "#subsumed?" Rules
//------------------------------------------------
  rule <s> subsumed? => #subsumed? RS ... </s> <analysis> RS </analysis> [structural]

  rule <s> #subsumed? .Rules               => #false                             ... </s> [structural]
  rule <s> #subsumed? (RS , < STATE >)     => #subsumed? RS                      ... </s> [structural]
  rule <s> #subsumed? (RS , < LHS --> _ >) => (LHS subsumes?) or (#subsumed? RS) ... </s> [structural]
```

At cut-points, we'll finish the rule we've been building, abstract the state, start a building a new rule from that state.

-   `begin-rule` will use the current state as the left-hand-side of a new rule in the record of rules.
-   `end-rule` uses the current state as the right-hand-side of a new rule in the record of rules.

```{.k .kat}
  syntax StateOp ::= "begin-rule" | "end-rule"
//--------------------------------------------
  rule <s> begin-rule [ STATE ] => . ... </s> <analysis> RS => RS , < STATE >                </analysis> [structural]
  rule <s> end-rule   [ STATE ] => . ... </s> <analysis> RS , (< LHS > => < LHS --> STATE >) </analysis> [structural]
```

Finally, semantics based compilation is provided as a macro.

-   `compile` will execute a program using the given `cut-point?` and `abstract` operators until it has collected a complete set of rules.

```{.k .kat}
  syntax Strategy ::= "compile"
//-----------------------------
  rule <s> ( compile
          => analysis .Rules
           ; abstract
           ; begin-rule
           ; while (not (subsumed? or stuck?))
               ( step until (cut-point? or stuck?)
               ; end-rule
               ; abstract
               ; begin-rule
               )
           ; end-rule
           )
           ...
       </s>
endmodule
```
### Future Work

-   Post-process the results of the compilation with another abstraction pass which just hashes the contents of the `k` cell for each rule.
    This will reduce the amount of extra matching that happens in executing the compiled definition.
-   Use matching-logic implication to implement `_subsumes?` in a language-indepedent way.

Corrective Model Checking
-------------------------

Corrective model-checking extends semantics based compilation by restricting the generated transition systems to only traces which satisfy the given property.
The strategy will only allow execution to continue if the property specified is satisfied.

Not implemented yet.
