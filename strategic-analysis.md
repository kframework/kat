---
geometry: margin=2.5cm
---

Introduction
============

Here I define a strategy language for controlling symbolic execution, and show
some simple analysis we can define from within K itself. The language IMP is
used as a running example, and the theory transformations over IMP's semantics
are performed by hand, but in a uniform way with an eye towards automatability.

The idea here is that once you have control over symbolic execution from within
K, it becomes much easier to prototype the program analysis we normally would do
in a backend. As such, some time is spent building a robust strategy language.

One design goal behind this effort is that the execution state of the program
should be disturbed as little as possible by the monitoring and control-flow
enforced by the strategy. As such, computation that the strategy needs to
accomplish should be done in the `strategy` cell, not on the `k` cell. It would
be nice to specify the sub-configuration `symbolicExecution` separetely, and
only at the end say "compose this configuration with my programming language's
configuration".

Because the configurations of K are not yet composable, I have to interleave the
code from two files `strategic-analysis.k` and `imp-strategies.k`.

IMP Language
------------

This is largely the same as the original `IMP-SYNTAX`, except that I've added a
new top-sort `Program`. This only has one constructor, which takes a `Strategy`
and a `Stmt`, allowing us to specify new strategies in the program itself
without recompiling the definition (I did this for rapid prototying of new
strategies to use). I've also moved the semantic rules which are structural (not
proper transitions) to this module.

```{.imp .k}
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
```

IMP Configuration
-----------------

The configuration for IMP is given here, along with the symbolic-execution
strategies harness. The original execution state of the program is moved into a
new cell `state` where it will live. The `strategy` cell contains the current
execution strategy, the `stack` cell contains a stack of states that the
strategy can use for execution, and the `analysis` cell contains a scratch-pad
memory for the strategy.

Note that this is a very simple "configuration transformation", namely one where
the existing language's execution is nested inside the observing configuration.

```{.imp .k}
module IMP-STRATEGIES
  imports IMP-SYNTAX
  imports STRATEGIES

  configuration <T>
                  <symbolicExecution multiplicity="*">
                    <strategy> skip </strategy>
                    <stack> .Stack </stack>
                    <analysis> .Analysis </analysis>
                    <state>
                      <k> $PGM:Program </k>
                      <mem> .Map </mem>
                    </state>
                  </symbolicExecution>
                </T>

  syntax Program ::= "strategy" ":" Strategy "=====" Stmt

  rule <strategy> _ => S </strategy> <k> strategy : S ===== PGM => PGM </k>

endmodule
```

Strategies
==========

Two modules are interleaved below. If K's configurations were more composable,
they could easily be one module defining the `symbolicExecution` machine.

The strategy language controls a small stack machine, which in turns controls
the execution of the program via the sort `Prim` (for "primitive"). This stack
machine has a stack of program symbolic states, which it can do normal
stack-machine like things with. The sort of each type of command tells you where
the arguments of the command will be sourced from (this will happen
automatically for you). You must provide the reduction of your command to its
output when it is at the top of the `strategy` cell.

Stack Machine Syntax
--------------------

The syntax of the stack machine primitives are given. The `Strategy` for `step`
must be provided by the language definition (see for IMP below).

```{.strat .k}
module STRATEGIES
  imports KCELLS

  syntax State ::= Bag
  syntax Stack ::= ".Stack"
                 | State ":" Stack

  syntax Analysis ::= ".Analysis"

  syntax UnStackOp
  syntax BinStackOp
  syntax StackOp ::= UnStackOp  | UnStackOp State
                   | BinStackOp | BinStackOp State State

  syntax StateOp
  syntax Op ::= StackOp | StateOp | StateOp State

  syntax Strategy ::= Op | "step"
```

For an `UnStackOp`, you can just put it at the top of `strategy`, and the top
element of the stack will be loaded for you. For `BinStackOp`, it will load the
top two elements for you. If you have a `StateOp`, it will also automatically
load a copy of the current state for you.

```{.imp .k}
module STRATEGIES-HARNESS
  imports IMP-STRATEGIES

  rule <strategy> (UOP:UnStackOp  => UOP S)     ; _ </strategy> <stack> S : STACK       => STACK </stack>
  rule <strategy> (BOP:BinStackOp => BOP S1 S2) ; _ </strategy> <stack> S1 : S2 : STACK => STACK </stack>
  rule <strategy> (SOP:StateOp    => SOP S)     ; _ </strategy> <state> S </state>
```

Primitive Operators
-------------------

`load` is the "pop" for the stack machine, and `store` is the "push".

```{.strat .k}
  syntax UnStackOp ::= "load"
  syntax StateOp ::= "store"
  syntax Strategy ::= "skip"
                    | Strategy ";" Strategy [assoc]
```

-   `load` places the state at the top of the stack into the execution harness
-   `store` copies the state in the execution harness onto the stack

```{.imp .k}
  rule <strategy> (load S  => skip) ; _ </strategy> <state> _     => S         </state>
  rule <strategy> (store S => skip) ; _ </startegy> <stack> STACK => S : STACK </stack>
```

-   `skip` will be automatically simplified out of the `Strategy`. 

```{.imp .k}
  rule <strategy> skip ; S      => S      </strategy>
  rule <strategy> S ; skip      => S      </strategy>
  rule <strategy> S ; skip ; S' => S ; S' </strategy>
```

Predicates
----------

```{.strat .k}
  syntax AtomicPred ::= "bool?" | "finished?"

  syntax Pred ::= AtomicPred | AtomicPred State
                | "#true" | "#false" | "#pred"
                | "not" Pred | Pred "or" Pred | Pred "and" Pred

  syntax Strategy ::= Pred
```

Atomic predicates automatically load a copy of the current execution state. When
you declare an `AtomicPred`, make sure to provide the reduction rule to `#true`
or `#false` on the `strategy` cell.

```{.imp .k}
  rule <strategy> (AP:AtomicPred => AP S) ; _ </strategy> <state> S </state>
```

-   `bool?` checks if the `k` cell has just the constant `true`/`false` in it
-   `finished?` checks if the `k` cell is empty (ie. execution of that machine has terminated)

```{.imp .k}
  rule <strategy> (bool? (<k> true  </k> _) => #true)  ; _ </strategy>
  rule <strategy> (bool? (<k> false </k> _) => #false) ; _ </strategy>

  rule <strategy> (finished? (<k> . </k> _) => #true)  ; _ </strategy>
  rule <strategy> (finished? (<k> _ </k> _) => #false) ; _ </strategy> [owise]
```

The boolean operators `not`, `and`, and `or` use helpers to evaluate their
arguments from left-to-right lazily ("short-circuit").

```{.imp .k}
  rule <strategy> (not P => P ; not #pred)       ; _ </strategy>
  rule <strategy> (bottom ; not #pred => top)    ; _ </strategy>
  rule <strategy> (top    ; not #pred => bottom) ; _ </strategy>

  rule <strategy> (P or Q => P ; #pred or Q) ; _ </strategy>
  rule <strategy> (top ; #pred or _ => top)  ; _ </strategy>
  rule <strategy> (bottom ; #pred or Q => Q) ; _ </strategy>

  rule <strategy> (P and Q => P ; #pred and Q)     ; _ </strategy>
  rule <strategy> (top ; #pred and Q => Q)         ; _ </strategy>
  rule <strategy> (bottom ; #pred and Q => bottom) ; _ </strategy>
```

Strategy Language
-----------------

The basic strategy language consists of operators, predicates, and choice.

```{.strat .k}
  syntax Strategy ::= Op | Pred | "?" Strategy ":" Strategy

endmodule
```

The top element of the `strategy` cell determines the semantics of choice.

```{.imp .k}
  rule <strategy> (#true  ; ? S : _ => S) ; _ </strategy>
  rule <strategy> (#false ; ? _ : S => S) ; _ </strategy>

endmodule
```

Helpers
-------

Here I define several helpers which make programming in this small stack machine
easier. This can be considered a "library" for the stack machine, which makes
rapid prototyping of algorithms for analysis of symbolic execution easy in K.
Once configurations are composable, this could live in an actual library
distributed with K.

-   `swap-stack` swaps the top two elements of the stack
-   `dup` duplicates the top of the stack
-   `swap` swaps the top of the stack with the current execution

```{.imp .k}
module STRATEGIES-AUX
  imports STRATEGIES-HARNESS

  syntax BinStackOp ::= "swap"
  syntax UnStackOp ::= "swap-stack" | "dup"

  rule <strategy> (swap S           => store ; load S)      ; _ </strategy>
  rule <strategy> (swap-stack S1 S2 => store S1 ; store S2) ; _ </strategy>
  rule <strategy> (dup S            => store S ; store S)   ; _ </strategy>
```

-   `while` executes with a given strategy until the predicate no longer holds (adding an integer bounds the iterations)
-   `step-to` executes a `step` until a predicate holds (adding an integer bounds the steps)

```{.imp .k}
  syntax Strategy ::= "while" Pred Strategy | "while" Int Pred Strategy
                    | "step-to" Pred | "step-to" Int Pred

  rule <strategy> (while P S   => P ; ? (S ; while P S) : skip)            ; _ </strategy>
  rule <strategy> (while 0 P S => skip)                                    ; _ </strategy>
  rule <strategy> (while N P S => P ; ? (S ; while (N -Int 1) P S) : skip) ; _ </strategy>
  rule <strategy> (step-to P   => while (not P) step)                      ; _ </strategy>
  rule <strategy> (step-to N P => while N P)                               ; _ </strategy> requires N >Int 0
```

-   `call` loads the top element of the stack and executes it given `Strategy`
-   `exec` executes the top element of the stack to completion (adding an integer bounds the steps)
-   `eval` calls `exec` then checks the predicate `bool?`

```{.imp .k}
  syntax Strategy ::= "call" Strategy

  syntax UnStackOp ::= "exec" | "exec" Int | "eval"

  rule <strategy> (call S   => swap-stack ; S ; swap-stack)          ; _ </strategy>
  rule <strategy> (exec S   => store S ; call (step-to finished?))   ; _ </strategy>
  rule <strategy> (exec N S => store S ; call (step-to N finished?)) ; _ </strategy>
  rule <strategy> (eval S   => exec S  ; bool?)                      ; _ </strategy>
endmodule
```

Instantiating to IMP
====================

The semantics of IMP remain unchanged except for the fact that we must mark the
states which we want the `step` command to consider as "steps" to be marked. We
do that by adding `<strategy> (step => skip) ; _ </strategy>` to each rule which
should be seen as a "step" of execution. Note that you could define your own
primitives and subsort them into `Strategy` which controlled execution in
different ways too.

```{.imp .k}
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
```

Analysis Tools
==============

These modules define the "interfaces" to various analysis. You need to provide
the interpretation of each new `StackOp`. By importing some combination of these
analysis, you are importing all of their interfaces.

Bounded Invariant Model Checking
--------------------------------

In bounded invariant model checking, the analysis being performed is a trace of
the execution states that we have seen.

```{.imp .k}
module IMP-BMC
  imports IMP-SEMANTICS

  syntax Trace ::= ".Trace"
                 | Trace ";" State
  syntax Analysis ::= Trace

  rule <analysis> .Analysis => .Trace </analysis>
```

-   `record` copies the current execution state to the end of the trace

```{.imp .k}
  syntax StateOp ::= "record"

  rule <strategy> (record S => skip) ; _ </strategy> <analysis> T => T ; S </analysis>
```

-   `assertion-failure` indicates that the given predicate failed within the
    execution bound
-   `assertion-success` inidicates that either the depth bound has been reached,
    or execution has terminated
-   `bmc-invariant` checks that the predicate holds for each step up to a bound

```{.imp .k}
  syntax Strategy ::= "assertion-failure" Pred
                    | "assertion-success"
                    | "bmc-invariant" Int Pred

  rule <strategy> ( bmc-invariant N P
                 => record
                  ; while N P (step ; record)
                  ; P ; ? assertion-success : assertion-failure P
                  ) ; _
       </strategy>
```

Everything above is language independent. This is the only part specific to the
language IMP.

-   `bexp?` allows us to make queries about the state in the boolean expression
    language of IMP

```{.imp .k}
  syntax AtomicPred ::= "bexp?" BExp

  rule <strategy> (bexp? B (<mem> M </mem> _) => eval (<k> B </k> <mem> M </mem>)) ; _ </strategy>
endmodule
```

### Future Work

-   Extend to model checking more than invariants. We could define the
    derivatives of regular expressions, and of LTL, and from that get regular or
    LTL model checking fairly simply here. This would be similar to how the
    derivatives of predicates `and` and `or` are defined, only they would inject
    extra `step` operations into the strategy. CTL is harder because the
    symbolic execution engine doesn't generate a proper disjunction, but rather
    splits into a family of separate states.

-   We should be able to just use normal ML patterns as sort `Cond`. This will
    require support from a ML prover, but will allow model checking very
    rich properties.

Semantics Based Compilation
---------------------------

Here, the result of the analysis will be a list of new rules corresponding to
the compiled definition. I've subsorted `Rules` into `Analysis`, and defined
`Rules` as a cons-list of rules generated. The interface to this analysis is the
predicate `cut-point?` (to specify when a rule should be finished and a new one
started), and the command `abstract` (to specify how to abstract the state).

```{.imp .k}
module IMP-COMPILATION
  imports IMP-SEMANTICS

  syntax Rule ::= "<" State ">"
                | "<" State "-->" State ">"

  syntax Rules ::= ".Rules"
                 | Rules "," Rule

  syntax Analysis ::= Rules

  syntax AtomicPred ::= "subsumed?"
                      | "cut-point?"

  syntax StateOp ::= "abstract"

  syntax Strategy ::= "compile"
```

### Language Independent (but tied to configuration)

First we define the `subsumed?` predicate, which checks if the current state is
subsumed by the left-hand side of any of the generated rules. This is done in
general using a matching-logic implication, but here with syntactic equality.

```{.imp .k}
  syntax AtomicPred ::= "#subsumed?" Rules

  rule <strategy> (subsumed? S:State => #subsumed? RS S)    ; _ </strategy> <analysis> RS </analysis>
  rule <strategy> (#subsumed? .Rules _ => bottom)           ; _ </strategy>
  rule <strategy> (#subsumed? (RS , < S  --> _ >) S => top) ; _ </strategy>

  // TODO: The following check should be an ML implication, not syntactic equality.
  rule <strategy> (#subsumed? (RS , < S' --> _ > => RS) S)  ; _ </strategy> requires S =/=K S'
```

`extend` takes the current state and saves it to the end of the last rule
generated in the analysis, and takes an execution step. `restart` begins
building a new rule in the analysis.

```{.imp .k}
  syntax UnStackOp ::= "#new-rule"

  rule <strategy> (#new-rule S => skip) ; _ </strategy> <analysis> RS => RS ; < S > </analysis>

  rule <strategy> (begin-rule => abstract ; #new-rule) ; _ </strategy>
  rule <strategy> (end-rule S => skip) ; _ </strategy> <analysis> RS ; (< S' > => < S' --> S >) > </analysis>
```

Finally, the command `compile` is a macro for executing the system symbolically
until it reaches a state that should be abstracted (by checking the `cut-point?`
predicate). If so, it begins building a new rule with the abstracted state as
the starting point and resumes execution.

```{.imp .k}
  rule <strategy> ( compile =>   begin-rule
                               ; while (not (finished? or subsumed?))
                                    ( step-to cut-point?
                                    ; end-rule
                                    ; begin-rule
                                    )
                               ; end-rule
                  ) ; _
       </strategy>
```

### Instantiating to IMP

The only part of this instantiation that is specific to IMP is the `cut-point?`
predicate and `abstract` command. Otherwise, everything could be defined prior
to finalizing the configuration.

Here, I specify that only when the top of the KCELL is a `while`-loop should
state-abstraction be done. For abstraction, I specify that each value in the
`state` map should be set to a new symbolic value.

```{.imp .k}
  rule <strategy> (cut-point? (<k> while (_:Bool) _ ~> _ </k> _) => top)    ; _ </strategy>
  rule <strategy> (cut-point? S                                  => bottom) ; _ </strategy> [owise]

  syntax UnStackOp ::= "#abstract" Set
                     | "#abstractKey" Id Set

  rule <strategy> (abstract (<state> MEM </state> C:Bag) => #abstract keys(MEM) (<state> MEM </state> C)) ; _ </strategy>

  rule <strategy> (#abstract .Set S:State            => store S)             ; _ </strategy>
  rule <strategy> (#abstract (SetItem(X) XS) S:State => #abstractKey X XS S) ; _ </strategy>

  rule <strategy> (#abstractKey X XS (<state> (X |-> _) M:Map </state> C:Bag) => #abstract XS (<state> (X |-> ?V:Int) M </state> C)) ; _ </strategy>

endmodule
```

### Future Work

-   Post-process the results of the compilation with another abstraction pass
    which just hashes the contents of the `k` cell for each rule. This will
    reduce the amount of frivilous matching that happens in executing the
    compiled definition.

-   Get a proper implication check going (instead of syntactic equality). This
    will be possible once a good matching-logic prover is integrated with `k`.

Corrective Model Checking
-------------------------

Corrective model-checking extends semantics based compilation by restricting the
generated transition systems to only traces which satisfy the given property.
The strategy will only allow execution to continue if the property specified is
satisfied.

Not implemented yet.

Examples
========

```{.imp .k}
module IMP-ANALYSIS
  imports IMP-BMC
  imports IMP-COMPILATION
endmodule
```

Compile the file `imp-strategies.k` with the command
`kompile --main-module IMP-ANALYSIS imp-strategies.k`.

Bounded Invariant Model Checking
--------------------------------

Here we check the property `x <= 7` for 5 steps of execution after the code has
initialized (the `step` in front of the command). Run this with
`krun --search test-bmc.imp`.

```{.test-bmc .k}
strategy : bmc-invariant 5 (bexp? x <= 7)

=====

int x ;
x = 0 ;
x = x + 15 ;
```

Note that to develop the `bmc-invariant` strategy, I experimented by changing
the above over and over again. Each time I had to re-`krun`, which is relatively
slow, but there is no reason to re-start the symbolic execution engine.

Semantics Based Compilation
---------------------------

Execute this test file with `krun --search test-compilation.imp`. Every solution
will have it's own trace of generated rules.

```{.test-compilation .k}
strategy : compile

=====

int n s ;

while (0 <= n) {
  n = n - 1 ;
  s = s + n ;
}
```
