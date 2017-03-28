// Introduction
// ============

// Here I define a strategy language for controlling symbolic execution, and show
// some simple analysis we can define from within K itself. The language IMP is
// used as a running example, and the theory transformations over IMP's semantics
// are performed by hand, but in a uniform way with an eye towards automatability.

// The idea here is that once you have control over symbolic execution from within
// K, it becomes much easier to prototype the program analysis we normally would do
// in a backend. As such, some time is spent building a robust strategy language.

// One design goal behind this effort is that the execution state of the program
// should be disturbed as little as possible by the monitoring and control-flow
// enforced by the strategy. As such, computation that the strategy needs to
// accomplish should be done in the `strategy` cell, not on the `k` cell. It would
// be nice to specify the sub-configuration `symbolicExecution` separetely, and
// only at the end say "compose this configuration with my programming language's
// configuration".

// Because the configurations of K are not yet composable, I have to interleave the
// code from two files `strategic-analysis.k` and `imp-strategies.k`.

// IMP Language
// ------------

// This is largely the same as the original `IMP-SYNTAX`, except that I've added a
// new top-sort `Program`. This only has one constructor, which takes a `Strategy`
// and a `Stmt`, allowing us to specify new strategies in the program itself
// without recompiling the definition (I did this for rapid prototying of new
// strategies to use). I've also moved the semantic rules which are structural (not
// proper transitions) to this module.


require "strategic-analysis.k"

module IMP-SYNTAX

  syntax AExp  ::= Int | Id
                 | AExp "/" AExp [left, strict]
                 > AExp "+" AExp [left, strict]
                 | "(" AExp ")"  [bracket]

  rule I1 / I2 => I1 /Int I2  requires I2 =/=Int 0
  rule I1 + I2 => I1 +Int I2

  syntax BExp  ::= Bool
                 | AExp "<=" AExp [seqstrict, latex({#1}\leq{#2})]
                 | "!" BExp       [strict]
                 > BExp "&&" BExp [left, strict(1)]
                 | "(" BExp ")"   [bracket]

  rule I1 <= I2 => I1 <=Int I2
  rule ! T => notBool T
  rule true && B => B
  rule false && _ => false

  syntax Block ::= "{" "}"
                 | "{" Stmt "}"

  syntax Ids ::= List{Id,","}

  syntax Stmt  ::= Block
                 | "int" Ids ";"
                 | Id "=" AExp ";"                      [strict(2)]
                 | "if" "(" BExp ")" Block "else" Block [strict(1)]
                 | "while" "(" BExp ")" Block
                 > Stmt Stmt                            [left]

  rule {}  => . [structural]
  rule {S} => S [structural]
  rule int .Ids ; => . [structural]
  rule S1:Stmt S2:Stmt => S1 ~> S2 [structural]

  syntax KResult ::= Int | Bool

endmodule


// IMP Configuration
// -----------------

// The configuration for IMP is given here, along with the symbolic-execution
// strategies harness. The original execution state of the program is moved into a
// new cell `state` where it will live. The `strategy` cell contains the current
// execution strategy, and the `analysis` cell contains a scratch-pad memory for
// the strategy.

// Note that this is a very simple "configuration transformation", namely one where
// the existing language's execution is nested inside the observing configuration.


module IMP-STRATEGIES
  imports IMP-SYNTAX
  imports STRATEGIES

  configuration <T>
                  <symbolicExecution multiplicity="*">
                    <strategy> skip </strategy>
                    <analysis> .Analysis </analysis>
                    <state>
                      <k> $PGM:Program </k>
                      <mem> .Map </mem>
                    </state>
                  </symbolicExecution>
                </T>

  syntax Program ::= "strategy" ":" Strategy "=====" Stmt

  rule <strategy> _ => STRAT </strategy> <k> strategy : STRAT:Strategy ===== PGM => PGM </k>

endmodule


// Strategies
// ==========

// Two modules are interleaved below. If K's configurations were more composable,
// they could easily be one module defining the `symbolicExecution` machine.

// Execution Machine Syntax
// ------------------------

// The `Strategy` for `step` must be provided by the language definition (see for
// IMP below).


module STRATEGIES-HARNESS
  imports IMP-STRATEGIES


// -   `skip` will be automatically simplified out of the `Strategy` (unless it's
//     at the end)
// -   `load` places the given state into the execution harness
// -   `?_:_` (choice) uses the top of the strategy cell to determine what to
//     execute next


  rule <strategy> skip ; S      => S      </strategy>
  rule <strategy> S ; skip ; S' => S ; S' </strategy>

  rule <strategy> (load S  => skip) ; _ </strategy> <state> _ => S </state>

  rule <strategy> (#true  ; ? S : _ => S) ; _ </strategy>
  rule <strategy> (#false ; ? _ : S => S) ; _ </strategy>


// Predicates
// ----------

// When you declare a `Pred`, make sure to provide the reduction rule to `#true` or
// `#false` on the `strategy` cell.

// -   `bool?` checks if the `k` cell has just the constant `true`/`false` in it
// -   `finished?` checks if the `k` cell is empty (ie. execution of that machine
//     has terminated)


  rule <strategy> (bool? => #true)      ; _ </strategy> <k> true  </k>
  rule <strategy> (bool? => #false)     ; _ </strategy> <k> false </k>

  rule <strategy> (finished? => #true)  ; _ </strategy> <k> . </k>
  rule <strategy> (finished? => #false) ; _ </strategy> <k> _ </k> [owise]


// The boolean operators `not`, `and`, and `or` use helpers to evaluate their
// arguments from left-to-right lazily ("short-circuit").


  rule <strategy> (not P => P ; not #pred)       ; _ </strategy>
  rule <strategy> (bottom ; not #pred => top)    ; _ </strategy>
  rule <strategy> (top    ; not #pred => bottom) ; _ </strategy>

  rule <strategy> (P or Q => P ; #pred or Q) ; _ </strategy>
  rule <strategy> (top ; #pred or _ => top)  ; _ </strategy>
  rule <strategy> (bottom ; #pred or Q => Q) ; _ </strategy>

  rule <strategy> (P and Q => P ; #pred and Q)     ; _ </strategy>
  rule <strategy> (top ; #pred and Q => Q)         ; _ </strategy>
  rule <strategy> (bottom ; #pred and Q => bottom) ; _ </strategy>

endmodule


// Auxillary Strategies
// --------------------

// Here I define several helpers which make programming in this control language.
// This can be considered a "library" for the strategies, which makes rapid
// prototyping of algorithms for analysis easier. Once configurations are
// composable, this could live in an actual library distributed with K.


module STRATEGIES-AUX
  imports STRATEGIES-HARNESS


// -   `while` executes with a given strategy until the predicate no longer holds
//     (adding an integer bounds the iterations)
// -   `step-to` executes a `step` until a predicate holds (adding an integer
//     bounds the steps)


  syntax Strategy ::= "while" Pred Strategy | "while" Int Pred Strategy
                    | "step-to" Pred | "step-to" Int Pred

  rule <strategy> (while P S   => P ; ? (S ; while P S) : skip)            ; _ </strategy>
  rule <strategy> (while 0 P S => skip)                                    ; _ </strategy>
  rule <strategy> (while N P S => P ; ? (S ; while (N -Int 1) P S) : skip) ; _ </strategy>
  rule <strategy> (step-to P   => while (not P) step)                      ; _ </strategy>
  rule <strategy> (step-to N P => while N P)                               ; _ </strategy> requires N >Int 0


// -   `exec` executes the given state to completion (adding an integer bounds
//     the steps)
// -   `eval` calls `exec` then checks the predicate `bool?`


  syntax Strategy ::= "exec" State | "exec" Int State
                    | "eval" State

  rule <strategy> (exec STATE   => load STATE ; step-to finished?)   ; _ </strategy>
  rule <strategy> (exec N STATE => load STATE ; step-to N finished?) ; _ </strategy>
  rule <strategy> (eval STATE   => exec STATE ; bool?)               ; _ </strategy>
endmodule


// Instantiating to IMP
// ====================

// The semantics of IMP remain unchanged except for the fact that we must mark the
// states which we want the `step` command to consider as "steps" to be marked. We
// do that by adding `<strategy> (step => skip) ; _ </strategy>` to each rule which
// should be seen as a "step" of execution. Note that you could define your own
// primitives and subsort them into `Strategy` which controlled execution in
// different ways too.


module IMP-SEMANTICS
  imports STRATEGIES-AUX

  rule <strategy> (step => skip) ; _ </strategy> <k> X:Id => I ...</k>
                                                 <state>... X |-> I ...</state>

  rule <strategy> (step => skip) ; _ </strategy> <k> X = I:Int ; => . ... </k>
                                                 <state> ... X |-> (_ => I) ... </state>

  rule <strategy> (step => skip) ; _ </strategy> <k> if (true)  B:Block else _ => B:Block ... </k> [transition]
  rule <strategy> (step => skip) ; _ </strategy> <k> if (false) _ else B:Block => B:Block ... </k> [transition]

  rule <strategy> (step => skip) ; _ </strategy> <k> int (X,Xs => Xs) ; ... </k>
                                                 <state> Rho:Map (.Map => X|->?V:Int) </state>
                                                 requires notBool (X in keys(Rho))

  rule <strategy> (step => skip) ; _ </strategy> <k> while (B) STMT => if (B) {STMT while (B) STMT} else {} ... </k>

endmodule


// Analysis Tools
// ==============

// These modules define the "interfaces" to various analysis. You need to provide
// the interpretation of each new `StackOp`. By importing some combination of these
// analysis, you are importing all of their interfaces.

// Bounded Invariant Model Checking
// --------------------------------

// In bounded invariant model checking, the analysis being performed is a trace of
// the execution states that we have seen.


module IMP-BMC
  imports IMP-SEMANTICS

  syntax Trace ::= ".Trace"
                 | Trace ";" State
  syntax Analysis ::= Trace


// -   `record` copies the current execution state to the end of the trace


  syntax Strategy ::= "record"

  rule <strategy> (record S => skip) ; _ </strategy> <analysis> T => T ; S </analysis>


// -   `assertion-failure` indicates that the given predicate failed within the
//     execution bound
// -   `assertion-success` inidicates that either the depth bound has been reached,
//     or execution has terminated
// -   `bmc-invariant` checks that the predicate holds for each step up to a bound


  syntax Strategy ::= "assertion-failure" Pred
                    | "assertion-success"
                    | "bmc-invariant" Int Pred

  rule <strategy> ( bmc-invariant N P
                 => record
                  ; while N P (step ; record)
                  ; P ; ? assertion-success : assertion-failure P
                  ) ; _
       </strategy>
       <analysis> _ => .Trace </analysis>


// Everything above is language independent. This is the only part specific to the
// language IMP.

// -   `bexp?` allows us to make queries about the state in the boolean expression
//     language of IMP


  syntax Pred ::= "bexp?" BExp

  rule <strategy> (bexp? B => eval (<k> B </k> <mem> MEM </mem>)) ; _ </strategy> <mem> MEM </mem>
endmodule


// ### Future Work

// -   Extend to model checking more than invariants. We could define the
//     derivatives of regular expressions, and of LTL, and from that get regular or
//     LTL model checking fairly simply here. This would be similar to how the
//     derivatives of predicates `and` and `or` are defined, only they would inject
//     extra `step` operations into the strategy. CTL is harder because the
//     symbolic execution engine doesn't generate a proper disjunction, but rather
//     splits into a family of separate states.
// 
// -   We should be able to just use normal ML patterns as sort `Cond`. This will
//     require support from a ML prover, but will allow model checking very
//     rich properties.
// 

// Semantics Based Compilation
// ---------------------------

// Here, the result of the analysis will be a list of new rules corresponding to
// the compiled definition. I've subsorted `Rules` into `Analysis`, and defined
// `Rules` as a cons-list of rules generated. The interface to this analysis is the
// predicate `cut-point?` (to specify when a rule should be finished and a new one
// started), and the command `abstract` (to specify how to abstract the state).


module IMP-COMPILATION
  imports IMP-SEMANTICS

  syntax Rule ::= "<" State ">"
                | "<" State "-->" State ">"

  syntax Rules ::= ".Rules"
                 | Rules "," Rule

  syntax Analysis ::= Rules

  syntax Pred ::= "subsumed?"
                | "cut-point?"

  syntax StateOp ::= "abstract"
                   | "end-rule"

  syntax Strategy ::= "compile"
                    | "begin-rule"


// ### Language Independent (but tied to configuration)

// First we define the `subsumed?` predicate, which checks if the current state is
// subsumed by the left-hand side of any of the generated rules. This is done in
// general using a matching-logic implication, but here with syntactic equality.


  syntax Pred ::= "#subsumed?" Rules

  rule <strategy> (subsumed?         => #subsumed? RS) ; _ </strategy> <analysis> RS </analysis>
  rule <strategy> (#subsumed? .Rules => bottom)        ; _ </strategy>

  syntax Bool ::= State "->K" State

  // TODO: Make the following an actual ML implication check
  rule <strategy> (#subsumed? (RS , < <k> KCELL </k> _ --> _ >) => top) ; _ </strategy> <state> <k> KCELL </k> _ </state>
  rule <strategy> (#subsumed? (RS , RL:Rule => RS))  ; _ </strategy> [owise]


// -   `begin-rule` creates the left-hand side of a new rule in the `analysis` cell
// -   `end-rule` adds the right-hind side to a half-finished rule in the
//     `analysis` cell


  rule <strategy> (begin-rule => skip) ; _ </strategy> <analysis> RS => RS ; < STATE > </analysis>
                                                       <state> STATE </state>

  rule <strategy> (end-rule => skip)   ; _ </strategy> <analysis> RS ; (< S > => < S --> STATE >) </analysis>
                                                       <state> STATE </state>


// Finally, the command `compile` is a macro for executing the system symbolically
// until it reaches a state that should be abstracted (by checking the `cut-point?`
// predicate). If so, it begins building a new rule with the abstracted state as
// the starting point and resumes execution.


  rule <strategy> ( compile
                 => abstract
                  ; begin-rule
                  ; while (not (finished? or subsumed?))
                       ( step-to (finished? or cut-point?)
                       ; end-rule
                       ; abstract
                       ; begin-rule
                       )
                  ; end-rule
                  ) ; _
       </strategy>
       <analysis> _ => .Rules </analysis>


// ### Instantiating to IMP {#instantiating-to-imp-1}

// The only part of this instantiation that is specific to IMP is the `cut-point?`
// predicate and `abstract` command. Here, I specify that only when the top of the
// KCELL is a `while`-loop should state-abstraction be done. At abstraction points,
// each value in the `mem` map should be set to a new symbolic value.


  rule <strategy> (cut-point? => top)    ; _ </strategy> <k> while _ _ ... </k>
  rule <strategy> (cut-point? => bottom) ; _ </strategy> [owise]

  syntax Strategy ::= "#abstract" Set
                    | "#abstractKey" Id

  rule <strategy> (abstract => #abstract keys(MEM)) ; _ </strategy> <mem> MEM </mem>

  rule <strategy> (#abstract .Set            => skip)                          ; _ </strategy>
  rule <strategy> (#abstract (SetItem(X) XS) => #abstractKey X ; #abstract XS) ; _ </strategy>

  rule <strategy> (#abstractKey X => skip) ; _ </strategy> <mem> ... (X |-> _ => ?V:Int) ... </mem>

endmodule


// ### Future Work {#future-work-1}

// -   Post-process the results of the compilation with another abstraction pass
//     which just hashes the contents of the `k` cell for each rule. This will
//     reduce the amount of extra matching that happens in executing the
//     compiled definition.
// 
// -   Get the implication check working (using ML prover or some
//     backend heuristic). Right now it just uses exact equality of the `k` cell.
// 

// Examples
// ========


module IMP-ANALYSIS
  imports IMP-BMC
  imports IMP-COMPILATION
endmodule


// Compile the file `imp-strategies.k` with the command
// `kompile --main-module IMP-ANALYSIS imp-strategies.k`.

// Bounded Invariant Model Checking {#bounded-invariant-model-checking-1}
// --------------------------------

// Here we check the property `x <= 7` for 5 steps of execution after the code has
// initialized (the `step` in front of the command). Run this with
// `krun --search test-bmc.imp`.

// Note that to develop the `bmc-invariant` strategy, I experimented by changing
// the above over and over again. Each time I had to re-`krun`, which is relatively
// slow, but there is no reason to re-start the symbolic execution engine.

// Semantics Based Compilation {#semantics-based-compilation-1}
// ---------------------------

// Execute this test file with `krun --search test-compilation.imp`. Every solution
// will have it's own trace of generated rules.
