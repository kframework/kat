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

    configuration
      <kat>
        <analysis> .Analysis </analysis>
        <states> .States </states>
      </kat>

    syntax Analysis ::= ".Analysis"
```

Basic Strategies
----------------

KAT assumes that we're working over some basic sort `State`.
Usually this will be some `*Cell` sort.
States have associated constraints as well, which are stored/restored using meta-level functionality.

```k
    syntax CState ::= State "|" K
    syntax AState ::= State | CState
    syntax States ::= ".States"
                    | AState ":" States
 // -----------------------------------

    syntax PreState
    syntax State ::= PreState
    syntax State ::= State "<" Strategy ">"
    syntax State ::= #stripStrat ( State ) [function]
 // -------------------------------------------------
    rule #stripStrat(STATE < S >) => #stripStrat(STATE)
    rule #stripStrat(STATE)       => STATE              requires isPreState(STATE)
```

-   `push_` copies the current execution state onto the stack of states and must be provided by the programming language.
-   `pop_` places the given state in the execution harness and must be provided by the programming language.

```k
    syntax Strategy ::= "push" | "push" State
 // -----------------------------------------
    rule <s> push STATE => . ... </s> <states> STATES => STATE : STATES </states>

    syntax Strategy ::= "pop" | "pop" State
 // ---------------------------------------
    rule <s> pop => pop STATE ... </s> <states> STATE : STATES => STATES </states>
    rule <s> pop STATE < S > => pop STATE ~> S ... </s>

    syntax Strategy ::= "pop-fresh" | "pop-fresh" State | "#pop-fresh" K
 // --------------------------------------------------------------------
    rule <s> pop-fresh => pop-fresh STATE </s> <states> STATE : STATES => STATES </states>
    rule <s> pop-fresh STATE:State => #pop-fresh #renameVariables(STATE) ... </s>
    rule <s> #pop-fresh STATE:State => pop STATE ... </s>
```

The current K backend will place the token `#STUCK` at the front of the `s` cell when execution cannot continue.
Here, a wrapper around this functionality is provided which will try to execute the given strategy and will roll back the state on failure.

-   `try?_` executes a given strategy, placing `#true` on strategy cell if it succeeds and `#false` otherwise.
-   `can?_` tries a given strategy, but restores the previous state on success (still reporting `#true` or `#false`).
-   `try-state?_` will check if a given state description is feasibly by executing its associated strategy.

**TODO:** constraints are not restored correctly on `can?` and `try?`.

```k
    syntax Strategy ::= "#exception" Exception
 // ------------------------------------------
    rule <s> #exception E => E ... </s>

    syntax Pred      ::= "try?" Strategy
    syntax Exception ::= "#try"
 // ---------------------------
    rule <s> try? S => push ~> S ~> #try ... </s>
    rule <s> #try   => drop ~> #true     ... </s>

    rule <s> #STUCK() ~> (S:Strategy => .)     ... </s>
    rule <s> #STUCK() ~> #try => pop ~> #false ... </s>

    rule <s> SA:StrategyApplied => . ... </s>

    syntax Pred ::= "can?" Strategy
 // -------------------------------
    rule <s> can? S => push ~> rename-vars ~> (try? S) ~> #pred pop ... </s>

    syntax Pred ::= "try-state?" State
 // ----------------------------------
    rule <s> try-state? STATE => push ~> pop-fresh STATE ~> #try ... </s>
```

-   `#exception_` can be used as a place-holder to turn an exception into a strategy.

```k
    syntax Strategy ::= "#exception" Exception
 // ------------------------------------------
    rule <s> #exception E => E ... </s>
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
    syntax Strategy ::= "#state-pred"
    syntax Pred ::= StatePred | StatePred "[" State "]"
 // ---------------------------------------------------
    rule <s> (. => push ~> #state-pred) ~> SP:StatePred  ... </s>
    rule <s> #state-pred ~> SP:StatePred => SP [ STATE ] ... </s> <states> STATE : STATES => STATES </states>
```

-   `#pred_` is useful for propagating the result of a predicate through another strategy.

```k
    syntax Strategy ::= "#pred" Strategy
 // ------------------------------------
    rule <s> PA:PredAtom ~> #pred S => S ~> PA ... </s>
```

Often you'll want a way to translate from the sort `Bool` in the programming language to the sort `Pred` in the strategy language.

-   `bool?` checks if the `k` cell has the constant `true`/`false` on the top of the K cell and it must be defined for each programming language.

```k
    syntax StatePred ::= "bool?"
 // ----------------------------
```

-   `stack-empty?` is a predicate that checks whether the stack of states is empty or not.

```k
    syntax Pred ::= "stack-empty?"
 // ------------------------------
    rule <s> stack-empty? => #true  ... </s> <states> .States        </states>
    rule <s> stack-empty? => #false ... </s> <states> STATE : STATES </states>
```

Strategy Statements
-------------------

The strategy language is a simple imperative language with sequencing and choice.

-   `skip` acts as a no-op strategy.
-   `{_}` and `(_)` are syntactically used to make blocks in the strategy language.
-   `_;_` is used to sequentially compose strategies.
-   `?_:_` (choice) uses the `Pred` value at the top of the strategy cell to determine what to execute next.
-   `if_then_else_` provides a familiar wrapper around the more primitive `?_:_` functionality.
-   `__` and `_{_,_}` allow specifying repetition patterns over strategies.
-   `_|_` tries executing the first strategy, and on failure executes the second.

```k
    syntax Strategy ::= "#eval" Pred
                      > "skip"
                      | "(" Strategy ")"                          [bracket]
                      | "?" Strategy ":" Strategy
                      | "if" Pred "then" Strategy "else" Strategy
                      > Strategy StrategyRep
                      | Strategy "{" Int "," StrategyRep "}"
                      > Strategy ";" Strategy                     [right]
                      > Strategy "|" Strategy                     [right]
 // ---------------------------------------------------------------------
    rule <s> #eval P => P ... </s>

    rule <s> skip    => .        ... </s>
    rule <s> S1 ; S2 => S1 ~> S2 ... </s>

    rule <s> #true  ~> ? S : _ => S ... </s>
    rule <s> #false ~> ? _ : S => S ... </s>

    rule <s> if P then S1 else S2 => P ~> ? S1 : S2 ... </s>

    rule <s> S | S' => (try? S) ~> ? skip : S' ... </s>
```

-   `StrategyRep` allows repeating a given strategy between a given number of times.
    This repetition is greedy, if only one bound is supplied it's both an upper bound and a lower bound.
    If both bounds are supplied the strategy fails if the lower bound is not met.
-   The repetition `?` will try a strategy at most once.
-   The repetition `*` is the "greedy Kleene star" which will attempt a strategy as many times as possible.
-   The repetition `+` is the "greedy Kleene star" which will attempt a strategy as many times as possible, but at least once.

```k
    syntax StrategyRep ::= Int | "?" | "*" | "+"
                         | #decrement ( StrategyRep ) [function]
 // ------------------------------------------------------------
    rule #decrement(0) => 0
    rule #decrement(N) => N -Int 1 requires N =/=Int 0
    rule #decrement(?) => 0
    rule #decrement(+) => *
    rule #decrement(*) => *

    rule <s> S N => S { N , N } ... </s>
    rule <s> S ? => S { 0 , 1 } ... </s>
    rule <s> S * => S { 0 , * } ... </s>
    rule <s> S + => S { 1 , * } ... </s>

    rule <s> S { 0 , N }
          => #if N =/=K 0 #then try? S ~> ? S { 0 , #decrement(N) } : skip
                          #else .
             #fi
         ...
         </s>

    rule <s> S { N , M } => S ~> S { N -Int 1 , #decrement(M) } ... </s> requires N >Int 0
```

Meta Strategies
---------------

The following strategies get information about the current state or manipulate the current state in standard ways.

-   `#error_` and `#metaTry__` can be used in conjunction for calling meta-level debugging operators.

```k
    syntax Exception ::= "#error" String
                       | "#metaTry" Bool Exception
 // ----------------------------------------------
    rule <s> #metaTry true _ => . ... </s>
```

-   `print-constraint` has the side-effect of printing the current top-level constraint.
-   `set-constraint_` replaces the current top-level constraint with the given one.

```k
    syntax Strategy ::= "print-constraint" | "set-constraint" K
 // -----------------------------------------------------------
    rule <s> print-constraint => #metaTry #printConstraint  #error "#printConstraint failure" ... </s>
    rule <s> set-constraint C => #metaTry #setConstraint(C) #error "#setConstraint failure"   ... </s>
```

-   `rename-vars` will replace the contents of the execution harness with a state with completely renamed variables.

```k
    syntax StateOp ::= "rename-vars"
 // --------------------------------
    rule <s> rename-vars [ STATE ] => pop-fresh STATE ... </s>
```

-   `stuck?` checks if the current state can take a step.

```k
    syntax Pred ::= "stuck?"
 // ------------------------
    rule <s> stuck? => not can? step ... </s>
```

-   `which-can?_` checks which of the given choices of strategies can take a step.

```k
    syntax Strategy  ::= "which-can?" Strategy
    syntax Exception ::= "#which-can" Strategy
 // ------------------------------------------
    rule <s> which-can? (S1 | S2) => which-can? S1 ~> which-can? S2 ... </s>
    rule <s> which-can? S => can? S ~> ? #exception (#which-can S) : skip ... </s>
      requires notBool #orStrategy(S)

    rule <s> #which-can S1 ~> which-can? S2 => which-can? S2 ~> #which-can S1 ... </s>
    rule <s> #which-can S1 ~> #which-can S2 => #which-can (S1 | S2)           ... </s>

    syntax Bool ::= #orStrategy ( Strategy ) [function]
 // ---------------------------------------------------
    rule #orStrategy(S1 | S2) => true
    rule #orStrategy(_)       => false [owise]
```

-   `how-many?_` will let you know how many times a given strategy can be taken.

```k
    syntax Strategy  ::= "how-many?" Strategy
    syntax Exception ::= "#how-many" Int
                       | "#how-many" Strategy Int
 // ---------------------------------------------
    rule <s> how-many? S => S ~> #how-many S 0 ... </s>

    rule <s>             #how-many S N => S ~> #how-many S (N +Int 1) ... </s>
    rule <s> #STUCK() ~> #how-many S N => #how-many N                 ... </s>
```

Strategy Primitives
-------------------

Strategies can manipulate the `state` cell (where program execution happens) and the `analysis` cell (a memory/storage for the strategy language).

-   `setStates_` sets the `states` cell to the given state stack.
-   `swap` swaps the top two elements of the state stack.
-   `dup` duplicates the top element of the state stack.
-   `drop` removes the top element of the state stack (without placing it in the execution harness).

```k
    syntax Strategy ::= "setStates" States
 // --------------------------------------
    rule <s> setStates STATES => . ... </s> <states> _ => STATES </states>

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

-   `step-with_` is used to specify that a given strategy should be executed admist regular rules (including heating and cooling).
    **TODO**: Current backend actually tags heating and cooling rules as `regular` instead, so `step-with` has been appropriately simplified.
              Perhaps we should investigate whether the backend's behaviour should be changed.
-   `#branch` defines what is a proper transition and must be provided by the programming language.
-   `#normal` defines a normal transition in the programming language (not a step for analysis).
-   `step` is `step-with_` instantiated to `#normal | #branch`.

```k
    syntax Strategy ::= "step-with" Strategy [function]
                      | "#normal"            [function]
                      | "#branch"            [function]
                      | "#loop"              [function]
                      | "step"               [function]
 // ---------------------------------------------------
    rule step-with S => (^ regular)* ; S ; (^ regular)*
    rule step        => step-with (#normal | #branch | #loop)
```

Things added to the sort `StateOp` will automatically load the current state for you, making it easier to define operations over the current state.

```k
    syntax StateOp
    syntax Strategy ::= "#state-op"
    syntax Strategy ::= StateOp | StateOp "[" State "]"
 // ---------------------------------------------------
    rule <s> (. => push ~> #state-op) ~> SO:StateOp  ... </s>
    rule <s> #state-op ~> SO:StateOp => SO [ STATE ] ... </s> <states> STATE : STATES => STATES </states>
```

-   `_until_` will execute the first strategy until the second strategy applies.

```k
    syntax Strategy ::= Strategy "until" Strategy
 // ---------------------------------------------
    rule <s> S1 until S2 => can? S2 ~> ? skip : (S1 ; (S1 until S2)) ... </s>
```

-   `exec` executes the given state to completion.
    Note that `krun === exec` if we assume that `#normal | #branch | #loop | ^ regular` is a total strategy.
-   `trace` is like `exec`, but pushes the states visited onto the `<states>` stack.
-   `eval` executes a given state to completion and checks `bool?`.

```k
    syntax Strategy ::= "exec" | "trace"
 // ------------------------------------
    rule <s> exec  => step *          ... </s>
    rule <s> trace => (step ; push) * ... </s>

    syntax Pred ::= "eval"
 // ----------------------
    rule <s> eval => push ~> exec ~> bool? ~> #pred pop ... </s>
```

-   `exec-to-branch` will execute a given state to a branch (or terminal) state (using `#normal` and `#branch` to limit choices about branch points).
    If it is a terminal state, then the `<s>` cell will be emptied.
    If it is a "fake" transition state (only one post state from `#branch`), it will continue execution.
    If there are multiple successors, they will be left on the `<s>` cell with `#which-can`.

```k
    syntax Strategy ::= "exec-to-branch" | "#exec-to-branch"
 // --------------------------------------------------------
    rule <s> exec-to-branch
          => (#normal | #loop | ^ regular) *
          ~> which-can? #branch
          ~> #exec-to-branch
         ...
         </s>

    rule <s> #exec-to-branch => . ... </s>
    rule <s> #which-can S ~> #exec-to-branch => S ~> exec-to-branch ... </s> requires notBool #orStrategy(S)
    rule <s> #which-can (S1 | S2) ~> (#exec-to-branch => .) ... </s>
```

```k
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
    rule <s> record [ STATE ] => . ... </s> <analysis> T => T ; STATE </analysis>
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

We've subsorted `Rules` into `Analysis`, and defined `Rules` as a cons-list of `Rule`.

```k
module KAT-SBC
    imports KAT
    imports K-REFLECTION

    syntax Rule ::= "<" State ">"
                  | "<" State "-->" State ">"
                  | "<" State "-->" State "requires" K ">"

    syntax Rules ::= ".Rules"
                   | Rules "," Rule

    syntax Analysis ::= Rules
```

The interface of this analysis requires you define when to abstract and how to abstract.

-   `_subsumes?_` is a predicate on two states that should be provided by the language definition (indicating whether the first state is more general than the second).
-   `abstract` is a (user defined) rule than should abstract away enough details of the state to guarantee termination of the execution of compilation.
     Note that `abstract` needs to also take care not to destroy all information collected about the state in this execution.

```k
    syntax Pred ::= State "subsumes?" State
 // ---------------------------------------

    syntax Strategy ::= "abstract"
 // ------------------------------
```

-   `subsumed?` is a predicate that checks if any of the left-hand sides of the rules `_subsumes_` the current state.

**TODO**: Need to check implication of condition as well!

```k
    syntax StatePred ::= "subsumed?"
    syntax Pred      ::= "#subsumed?" State Rules
 // ---------------------------------------------
    rule <analysis> RS </analysis>
         <s> subsumed? [ STATE ] => (#subsumed? STATE RS) ... </s>

    rule <s> #subsumed? STATE .Rules         => #false              ... </s>
    rule <s> #subsumed? STATE (RS , < LHS >) => #subsumed? STATE RS ... </s>

    rule <s> #subsumed? STATE (RS , < LHS --> _ >)
          => (LHS subsumes? STATE) or (#subsumed? STATE RS)
         ...
         </s>

    rule <s> #subsumed? STATE (RS , < LHS --> _ requires _>)
          => (LHS subsumes? STATE) or (#subsumed? STATE RS)
         ...
         </s>
```

-   `mk-rule` will build a rule given a `State`, by assuming the base of the state a the LHS of the rule and the state after executing the strategy as the RHS.
-   `init-rules` will build new rules (using `split-rules`) starting in the top-stack state with the given strategy, if the current state is not subsumed.
-   `split-rules` will take a given state + strategy and split it into all the feasible initial states to be analyzed.

```k
    syntax Strategy ::= "mk-rule" State | "#mk-rule" K | "#mk-rule"
 // ---------------------------------------------------------------
    rule <s> mk-rule STATE => #mk-rule #renameVariables(STATE) ... </s>
    rule <s> #mk-rule STATE:State => push STATE ~> pop STATE ~> push ~> #mk-rule ... </s>
    rule <analysis> RS => RS , < #stripStrat(LHS) --> RHS requires #getConstraint(< LHS --> RHS >) > </analysis>
         <states> RHS : LHS : STATES => STATES </states>
         <s> #mk-rule => . ... </s>

    syntax Strategy ::= "init-rules" Strategy | "#init-rules" Strategy
 // ------------------------------------------------------------------
    rule <s> init-rules S => push ~> #init-rules S ... </s>
    rule <states> STATE : STATES => STATES </states>
         <analysis> RS </analysis>
         <s> #init-rules S => pop-fresh STATE ~> if subsumed? then skip else split-rules STATE S ... </s>

    syntax Strategy ::= "split-rules" State Strategy
 // ------------------------------------------------
    rule <s> split-rules STATE (S1 | S2) => split-rules STATE S1 ~> split-rules STATE S2 ... </s>
    rule <s> split-rules STATE S => if try-state? STATE < S > then push STATE < S > else skip ... </s>
      requires notBool #orStrategy(S)
```

Finally, semantics based compilation is provided as a macro.

-   `compile-step` will generate the rule associated to the state at the top of the `states` stack.
    **Note**: Here we assume `#loop`, `#branch`, and `#normal | ^ regular` are disjoint strategies.

```k
    syntax Strategy ::= "compile-step"
 // ----------------------------------
    rule <states> STATE : STATES => STATES </states>
         <s> compile-step
          => if try-state? STATE < #loop >
              then ( mk-rule STATE
                   ; pop-fresh STATE
                   ; abstract
                   ; init-rules #loop
                   )
             else if try-state? STATE < #branch >
              then ( split-rules STATE #branch
                   )
             else if try-state? STATE < ^ regular | #normal >
              then ( push STATE < (^ regular | #normal) * > )
             else  ( mk-rule STATE )
             ...
         </s>
```

-   `compile` will initialize the stack to empty and the analysis to `.Rules`, then compile the current program to completion.
-   `bounded-compile_` will run the compiler for the specified number of steps.

```k
    syntax Strategy ::= "compile" | "#compile"
 // ------------------------------------------
    rule <s> compile => init-compile ~> #compile ... </s>

    rule <s> #compile => .                   ... </s> <states> .States        </states>
    rule <s> (. => compile-step) ~> #compile ... </s> <states> STATE : STATES </states>

    syntax Strategy ::= "bounded-compile" Int | "#bounded-compile" Int
 // ------------------------------------------------------------------
    rule <s> bounded-compile N => init-compile ~> #bounded-compile N ... </s>

    rule <s> #bounded-compile 0 => . ... </s>
    rule <s> #bounded-compile N => . ... </s> <states> STATE : STATES </states>
    rule <s> (. => compile-step) ~> #bounded-compile (N => N -Int 1) ... </s>
         <states> STATE : STATES </states>
      requires N =/=Int 0

    syntax Strategy ::= "init-compile"
 // ----------------------------------
    rule <s> init-compile => setAnalysis .Rules ~> setStates .States ~> push ... </s>
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
