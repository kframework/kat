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

```k
requires "unification.k"

module KAT
    imports STRATEGY
    imports DOMAINS
    imports UNIFICATION

    configuration <kat>
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

```k
    syntax PredAtom ::= "#true" | "#false"
    syntax Pred     ::= PredAtom | "#pred" | "(" Pred ")" [bracket]
                      | "not" Pred | Pred "or" Pred | Pred "and" Pred
 // -----------------------------------------------------------------
    rule <s> not P               => P ~> not #pred ... </s>
    rule <s> #false ~> not #pred => #true          ... </s>
    rule <s> #true  ~> not #pred => #false         ... </s>

    rule <s> P or Q               => P ~> #pred or Q ... </s>
    rule <s> #true  ~> #pred or _ => #true           ... </s>
    rule <s> #false ~> #pred or Q => Q               ... </s>

    rule <s> P and Q               => P ~> #pred and Q ... </s>
    rule <s> #true  ~> #pred and Q => Q                ... </s>
    rule <s> #false ~> #pred and _ => #false           ... </s>
```

State predicates are evaluated over the current execution state.
If you declare something a `StatePred`, this code will automatically load the current state for you (making the definition of them easier).

```k
    syntax StatePred
    syntax Pred ::= StatePred | StatePred "[" State "]"
 // ---------------------------------------------------
    rule <s> SP:StatePred              => push ~> SP [ #current ] ... </s>
    rule <s> SP:StatePred [ #current ] => SP [ STATE ]            ... </s> <states> STATE : STATES => STATES </states>
```

-   `#pred_` is useful for propagating the result of a predicate through another strategy.

```k
    syntax Strategy ::= "#pred" Strategy
 // ------------------------------------
    rule <s> PA:PredAtom ~> #pred S => S ~> PA ... </s>
```

Often you'll want a way to translate from the sort `Bool` in the programming language to the sort `Pred` in the strategy language.

-   `bool?` checks if the `k` cell has just the constant `true`/`false` in it and must be defined for each programming language.

```k
    syntax StatePred ::= "bool?"
 // ----------------------------
```

The current K backend will place the token `#STUCK` at the front of the `s` cell when execution cannot continue.
Here, a wrapper around this functionality is provided which will try to execute the given strategy and will roll back the state on failure.

-   `try?_` executes a given strategy, placing `#true` on strategy cell if it succeeds and `#false` otherwise.

```k
    syntax Pred      ::= "try?" Strategy
    syntax Exception ::= "#try"
 // ---------------------------
    rule <s> try? S => push ~> S ~> #try ... </s>
    rule <s> #try   => drop ~> #true     ... </s>

    rule <s> #STUCK() ~> (S:Strategy => .)     ... </s>
    rule <s> #STUCK() ~> #try => pop ~> #false ... </s>

    rule <s> SA:StrategyApplied => . ... </s>
```

-   `stack-empty?` is a predicate that checks whether the stack of states is empty or not.

```k
    syntax Pred ::= "stack-empty?"
 // ------------------------------
    rule <s> stack-empty? => #true  ... </s> <states> .States        </states>
    rule <s> stack-empty? => #false ... </s> <states> STATE : STATES </states>
```

-   `can?_` tries to execute the given strategy, but restores the state afterwards.
-   `stuck?` checks if the current state can take a step.

```k
    syntax Pred ::= "can?" Strategy
 // -------------------------------
    rule <s> can? S => push ~> (try? S) ~> #pred pop ... </s>

    syntax Pred ::= "stuck?"
 // ------------------------
    rule <s> stuck? => not can? step ... </s>
```

Strategy Statements
-------------------

The strategy language is a simple imperative language with sequencing and choice.

-   `skip` acts as a no-op strategy.
-   `{_}` and `(_)` are syntactically used to make blocks in the strategy language.
-   `_;_` is used to sequentially compose strategies.
-   `?_:_` (choice) uses the `Pred` value at the top of the strategy cell to determine what to execute next.
-   `__` and `_{_,_}` allow specifying repetition patterns over strategies.
-   `_|_` tries executing the first strategy, and on failure executes the second.

```k
    syntax Strategy ::= "#eval" Pred
                      > "skip"
                      | "(" Strategy ")"          [bracket]
                      | "?" Strategy ":" Strategy
                      > Strategy StrategyRep
                      | Strategy "{" Int "," StrategyRep "}"
                      > Strategy ";" Strategy     [right]
                      > Strategy "|" Strategy     [right]
 // -----------------------------------------------------
    rule <s> #eval P => P ... </s>

    rule <s> skip    => .        ... </s>
    rule <s> S1 ; S2 => S1 ~> S2 ... </s>

    rule <s> #true  ~> ? S : _ => S ... </s>
    rule <s> #false ~> ? _ : S => S ... </s>

    rule <s> S | S' => (try? S) ~> ? skip : S' ... </s>
```

-   `StrategyRep` allows repeating a given strategy between a given number of times.
    This repetition is greedy, if only one bound is supplied it's an upper bound and the lower bound is zero.
    If both bounds are supplied the strategy fails if the lower bound is not met.
-   The repetition `*` is the "greedy Kleene star" which will attempt a strategy as many times as possible.
-   The repetition `?` will try a strategy at most once.

```k
    syntax StrategyRep ::= Int | "*" | "?"
                         | #decrement ( StrategyRep ) [function]
 // ------------------------------------------------------------
    rule #decrement(0) => 0
    rule #decrement(?) => 0
    rule #decrement(N) => N -Int 1 requires N =/=Int 0
    rule #decrement(*) => *

    rule <s> S SR:StrategyRep => S { 0 , SR } ... </s>

    rule <s> S { 0 , N }
          => #if N =/=K 0 #then try? S ~> ? S { 0 , #decrement(N) } : skip
                          #else .
             #fi
         ...
         </s>

    rule <s> S { N , M } => S ~> S { N -Int 1 , #decrement(M) } ... </s> requires N =/=Int 0
```

-   `if_then_else_` provides a familiar wrapper around the more primitive `?_:_` functionality.

```k
    syntax Strategy ::= "if" Pred "then" Strategy "else" Strategy
 // -------------------------------------------------------------
    rule <s> if P then S1 else S2 => P ~> ? S1 : S2 ... </s>
```

-   `exec` executes the given state to completion.
    Note that `krun === exec`.
-   `eval` executes a given state to completion and checks `bool?`.

```k
    syntax Strategy ::= "exec"
 // --------------------------
    rule <s> exec => step * ... </s>

    syntax StatePred ::= "eval"
 // ---------------------------
    rule <s> eval [ STATE ] => pop STATE ~> exec ~> bool? ... </s> requires STATE =/=K #current
```

Strategy Primitives
-------------------

Strategies can manipulate the `state` cell (where program execution happens) and the `analysis` cell (a memory/storage for the strategy language).

-   `push_` copies the current execution state onto the stack of states and must be provided by the programming language.
-   `pop_` places the given state in the execution harness and must be provided by the programming language.
-   `stack_` sets the `states` cell to the given state stack.
-   `swap` swaps the top two elements of the state stack.
-   `dup` duplicates the top element of the state stack.
-   `drop` removes the top element of the state stack (without placing it in the execution harness).

```k
    syntax Strategy ::= "push" | "push" State
 // -----------------------------------------
    rule <s> push STATE => . ... </s> <states> STATES => STATE : STATES </states>

    syntax Strategy ::= "pop" | "pop" State
 // ---------------------------------------
    rule <s> pop #current => .         ... </s>
    rule <s> pop          => pop STATE ... </s> <states> STATE : STATES => STATES </states>

    syntax Strategy ::= "stack" States
 // ----------------------------------
    rule <s> stack STATES => . ... </s> <states> _ => STATES </states>

    syntax Strategy ::= "swap" | "dup" | "drop"
 // -------------------------------------------
    rule <s> swap => . ... </s> <states> S1 : S2 : STATES => S2 : S1 : STATES </states>
    rule <s> dup  => . ... </s> <states> S1      : STATES => S1 : S1 : STATES </states>
    rule <s> drop => . ... </s> <states> S1      : STATES =>           STATES </states>
```

-   `setAnalysis_` sets the `analysis` cell to the given argument.

```k
    syntax Strategy ::= "setAnalysis" Analysis
 // ---------------------------------------
    rule <s> setAnalysis A => . ... </s> <analysis> _ => A </analysis>
```

-   `step-with_` is used to specify that a given strategy should be executed admist heating and cooling.
-   `#transition` defines what is a proper transition and must be provided by the programming language.
-   `#normal` defines a normal transition in the programming language (not a step for analysis).
-   `step` is `step-with_` instantiated to `#normal | #transition`.

```k
    syntax Strategy ::= "step-with" Strategy | "#transition" | "#normal" | "step"
 // -----------------------------------------------------------------------------
    rule <s> step-with S => (^ regular | ^ heat)* ~> S ~> (^ regular | ^ cool)* ... </s>
    rule <s> step        => step-with (#normal | #transition)                   ... </s>
```

Things added to the sort `StateOp` will automatically load the current state for you, making it easier to define operations over the current state.

```k
    syntax StateOp
    syntax Strategy ::= StateOp | StateOp "[" State "]"
 // ---------------------------------------------------
    rule <s> SO:StateOp              => push ~> SO [ #current ] ... </s>
    rule <s> SO:StateOp [ #current ] => SO [ STATE ]            ... </s> <states> STATE : STATES => STATES </states>
```

-   `rename-vars` will replace the contents of the execution harness with a state with completely renamed variables.

```k
    syntax Strategy ::= "rename-vars" | "#rename-vars" | "#renamed-vars" K
 // ----------------------------------------------------------------------
    rule <s> rename-vars           => push ~> #rename-vars              ... </s>
    rule <s> #renamed-vars S:State => pop S                             ... </s>
    rule <s> #rename-vars          => #renamed-vars #renameVariables(S) ... </s>
         <states> S : STATES => STATES </states>
endmodule
```

K Analysis Toolset (KAT)
========================

KAT is a set of formal analysis tools which can be instantiated (as needed) to your programming language.
Each tool has a well defined interface in terms of the predicates and operations you must provide over your languages state.

Bounded Invariant Model Checking
--------------------------------

In bounded invariant model checking, the analysis being performed is a trace of the execution states that we have seen.

```k
module KAT-BIMC
    imports KAT

    syntax Trace    ::= ".Trace"
                      | Trace ";" State

    syntax Analysis ::= Trace
```

-   `#length` calculates the length of a trace.

```k
    syntax Int ::= #length ( Trace ) [function]
 // -------------------------------------------
    rule #length(.Trace) => 0
    rule #length(T ; _)  => 1 +Int #length(T)
```

-   `record` copies the current execution state to the end of the trace.

```k
    syntax StateOp ::= "record"
 // ---------------------------
    rule <s> record [ STATE ] => . ... </s> <analysis> T => T ; STATE </analysis> requires STATE =/=K #current
```

After performing BIMC, we'll need a container for the results of the analysis.

-   `#bimc-result_in_steps` holds the result of a bimc analysis.
    The final state reached in the analysis cell will be in the execution harness.
-   `bimc__` runs bounded invariant model checking of the given predicate up to the given depth.

```k
    syntax Exception ::= "#bimc-result" PredAtom "in" Int "steps"
 // -------------------------------------------------------------

    syntax Strategy ::= "#bimc-result" PredAtom
 // -------------------------------------------
    rule <s> #bimc-result PA => #bimc-result PA in #length(TRACE) steps ... </s>
         <analysis> TRACE </analysis>

    syntax Strategy ::=  "bimc" Int Pred
                      | "#bimc" Int Pred
 // ------------------------------------
    rule <s> bimc N P => setAnalysis .Trace ~> P ~> ? #bimc N P : #bimc-result #false ... </s>

    rule <s> #bimc 0 P => #bimc-result #true ... </s>
         <analysis> TRACE </analysis>

    rule <s> #bimc N P
          => record
          ~> try? step
          ~> ? #eval P ; ? #bimc (N -Int 1) P : #bimc-result #false
             : #bimc-result #true
         ...
         </s>
      requires N =/=Int 0
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

```k
module KAT-SBC
    imports KAT

    syntax Rule ::= "<" State ">"
                  | "<" State "-->" State ">"

    syntax Rules ::= ".Rules"
                   | Rules "," Rule

    syntax Analysis ::= Rules
```

The interface of this analysis requires you define when to abstract and how to abstract.

-   `_subsumes?` is a predicate on two states that should be provided by the language definition (indicating whether the first state is more general than the second).
-   `abstract` is an operator than should abstract away enough details of the state to guarantee termination of the execution of compilation.
     Note that `abstract` needs to also take care not to destroy all information collected about the state in this execution.

```k
    syntax StatePred ::= State "subsumes?"
 // --------------------------------------

    syntax StateOp ::= "abstract"
 // -----------------------------
```

-   `subsumed?` is a predicate that checks if any of the left-hand sides of the rules `_subsumes_` the current state.

```k
    syntax Pred ::= "subsumed?" | "#subsumed?" Rules
 // ------------------------------------------------
    rule <s> subsumed? => #subsumed? RS ... </s> <analysis> RS </analysis>

    rule <s> #subsumed? .Rules               => #false                             ... </s>
    rule <s> #subsumed? (RS , < STATE >)     => #subsumed? RS                      ... </s>
    rule <s> #subsumed? (RS , < LHS --> _ >) => (LHS subsumes?) or (#subsumed? RS) ... </s>
```

-   `begin-rule` will use the current state as the left-hand-side of a new rule in the record of rules.
-   `end-rule` uses the current state as the right-hand-side of a new rule in the record of rules.

```k
    syntax StateOp ::= "begin-rule" | "end-rule"
 // --------------------------------------------
    rule <s> begin-rule [ STATE ] => . ... </s> <analysis> RS => RS , < STATE >                </analysis> requires STATE =/=K #current
    rule <s> end-rule   [ STATE ] => . ... </s> <analysis> RS , (< LHS > => < LHS --> STATE >) </analysis> requires STATE =/=K #current
```

-   `#compile-result_` holds the result of a sbc analysis.

```k
    syntax Exception ::= "#compile-result" | "#compile-result" Rules
 // ----------------------------------------------------------------
    rule <s> #compile-result => #compile-result RS ... </s> <analysis> RS => .Analysis </analysis>
```

Finally, semantics based compilation is provided as a macro.

-   `compile-step` will generate the rule associated to the state at the top of the `states` stack.

```k
    syntax Strategy ::= "compile-step"
 // ----------------------------------
    rule <s> ( compile-step
            => if subsumed?
               then drop
               else ( pop
                    ; abstract
                    ; rename-vars
                    ; begin-rule
                    ; (step-with #transition) ?
                    ; (step-with #normal) *
                    ; end-rule
                    ; push
                    )
             )
             ...
         </s>
```

-   `compile` will initialize the stack to empty and the analysis to `.Rules`, then compile the current program to completion.

```k
    syntax Strategy ::= "compile" | "#compile"
 // ------------------------------------------
    rule <s> ( compile
            => setAnalysis .Rules
            ~> stack .States
            ~> push
            ~> #compile
            ~> #compile-result
             )
             ...
         </s>

    rule <s> #compile => .                   ... </s> <states> .States        </states>
    rule <s> (. => compile-step) ~> #compile ... </s> <states> STATE : STATES </states>
endmodule
```

### Future Work

-   Post-processing steps including hashing any components of the state that are concrete for the entire execution (eg. the `k` cell).
    This will reduce the amount of extra matching that happens in executing the compiled definition.
-   Use matching-logic implication to implement `_subsumes?` in a language-indepedent way.

Corrective Model Checking
-------------------------

Corrective model-checking extends semantics based compilation by restricting the generated transition systems to only traces which satisfy the given property.
The strategy will only allow execution to continue if the property specified is satisfied.

Not implemented yet.
