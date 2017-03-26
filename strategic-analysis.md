Introduction
============

Here I define a strategy language for controlling symbolic execution, and show
some simple analysis we can define from within K itself. The language IMP is
used as a running example, and the theory transformations over IMP's semantics
are performed by hand, but in a uniform way with an eye towards automatability.

The idea here is that once you have control over symbolic execution from within
K, it becomes much easier to prototype the program analysis we normally would do
in a backend. As such, some time is spent building a robust strategy language.

IMP Language
------------

This is largely the same as the original `IMP-SYNTAX`, except that I've added a
new top-sort `Program`. This only has one constructor, which takes a `Strategy`
and a `Stmt`, allowing us to specify new strategies in the program itself
without recompiling the definition. I've also moved the semantic rules which are
structural (not proper transitions) to this module.

```{.imp .k}
require "strategic-analysis.k"

module IMP-SYNTAX
  imports STRATEGIES

  syntax KResult ::= Int | Bool

  syntax Ids ::= List{Id,","}

  syntax AExp  ::= Int | Id
                 | AExp "/" AExp              [left, strict]
                 > AExp "+" AExp              [left, strict]
                 | "(" AExp ")"               [bracket]

  rule I1 / I2 => I1 /Int I2  requires I2 =/=Int 0
  rule I1 + I2 => I1 +Int I2

  syntax BExp  ::= Bool
                 | AExp "<=" AExp             [seqstrict, latex({#1}\leq{#2})]
                 | "!" BExp                   [strict]
                 > BExp "&&" BExp             [left, strict(1)]
                 | "(" BExp ")"               [bracket]
                 
  rule I1 <= I2 => I1 <=Int I2
  rule ! T => notBool T
  rule true && B => B
  rule false && _ => false

  syntax Block ::= "{" "}"
                 | "{" Stmt "}"

  rule {}       => . [structural]
  rule {S:Stmt} => S [structural]

  syntax Stmt  ::= Block
                 | Id "=" AExp ";"            [strict(2)]
                 | "int" Ids ";"
                 | "if" "(" BExp ")"
                   Block "else" Block         [strict(1)]
                 | "while" "(" BExp ")" Block
                 > Stmt Stmt                  [left]

  rule int .Ids ; => . [structural]
  rule S1:Stmt S2:Stmt => S1 ~> S2 [structural]

  syntax Program ::= "strategy" ":" Strategy "=====" Stmt
endmodule
```

Strategies
----------

First there is a module `STRATEGIES` which defines a small machine for
controlling the symbolic execution of a program. This machine has a single
temporary register, where one `State` is stored. It also has storage for the
results of an `Analysis`. An interface of minimal commands is exported (`step`,
`snapshot`, and `set`) for the instrumentation of analysis tools to your
language. A simple imerative language over these operations is built, which is
called a `Strategy`.

```{.strat .k}
// Copyright (c) 2014-2016 K Team. All Rights Reserved.

module STRATEGIES

  syntax State ::= ".State"
  syntax Analysis ::= ".Analysis"
  
  syntax PredState
  syntax PredAnalysis
  syntax PredBoth
  syntax Pred ::= PredState | PredState "[" State "]"
                | PredAnalysis | PredAnalysis "[" Analysis "]"
                | PredBoth | PredBoth "[" State "|" Analysis "]"
                | "predTrue" | "predFalse"

  syntax Primitive ::= "step"
                     | "snapshot"
                     | "set"

  syntax Command ::= Primitive
                   | Pred
                   | "skip"
                   | "{" Strategy "}"
                   | "if" Pred "then" Command "else" Command
                   | "while" Pred Command
                   | "repeat" Int Command

  syntax Block ::= "{" Strategy "}"

  syntax Strategy ::= ".Strategy"
                    | Command ";" Strategy
                    | Strategy "++" Strategy
endmodule
```

Ideally, we could enter strategies on the fly (ie. in the debugger). Really,
this `STRATEGIES` module is just about getting control over the symbolic
execution engine from inside K itself. After experimenting with strategies in an
interactive session, one could save out the result as a macro-command in a
library that ships with K. This would make writing future analysis tools easier.

IMP Strategies
--------------

This module declares the IMP configuration, with the `symbolicExecution`
configuration grafted onto it.

```{.imp .k}
module IMP-STRATEGIES
  imports IMP-SYNTAX
  imports STRATEGIES

  configuration <T>
                  <k> $PGM:Program </k>
                  <state> .Map </state>
                  <symbolicExecution>
                    <currState> .State </currState>
                    <analysis> .Analysis </analysis>
                    <strategy> .Strategy </strategy>
                  </symbolicExecution>
                </T>
```

### Language Independent

The following code could all be moved to the file `strategic-analysis.k` if
configurations were more composable. This makes sense because these have nothing
to do with IMP.

```{.imp .k}
  rule <strategy> .Strategy ++ S => S </strategy>
  rule <strategy> (C ; S) ++ S' => C ; (S ++ S') </strategy>

  rule <currState> S </currState>
       <analysis> A </analysis>
       <strategy> (P:PredBoth => P [ S | A ]) ; _ </strategy>

  rule <currState> S </currState>
       <strategy> (P:PredState => P [ S ]) ; _ </strategy>

  rule <analysis> A </analysis>
       <strategy> (P:PredAnalysis => P [ A ]) ; _ </strategy>

  rule <strategy> skip ; S => S </strategy> [owise]
 
  rule <strategy> { S } ; S' => S ++ S' </strategy>
  
  rule <strategy> predTrue  ; if _ then C else _ ; S => C ; S </strategy>
  rule <strategy> predFalse ; if _ then _ else C ; S => C ; S </strategy>
  rule <strategy> (if P then C else C' => { P ; if P then C else C' ; .Strategy }) ; _ </strategy>

  rule <strategy> ( while P C
                  => if P then { C ; while P C ; .Strategy }
                          else skip
                  ) ; _
       </strategy>

  rule <strategy> (repeat 0 C => skip) ; _ </strategy>
  rule <strategy> (repeat N C => { repeat (N -Int 1) C ; C ; .Strategy }) ; _ </strategy>
       requires N >Int 0
```

### Instantiating to IMP

Now we give the semantics of `IMP`, augmented to work with the symbolic
execution engine. Almost everything remains unchanged, except for the fact that
we've added `<strategy> (step => skip) ; S </strategy>` to every rule.
Semantically, if all the rules had been previously zipped up into one rule
`rule l=>r : TopSort`, then this would be like replacing that rule with
`rule l=>r <strategy> (step => skip) ; S </strategy>`. This gives the effect of
taking exactly one step with the symbolic execution engine.

```{.imp .k}
  rule <k> X:Id => I ...</k>
       <state>... X |-> I ...</state>
       <strategy> (step => skip) ; _ </strategy>
       
  rule <k> X = I:Int ; => . ... </k>
       <state> ... X |-> (_ => I) ... </state>
       <strategy> (step => skip) ; _ </strategy>

  rule <k> if (true)  B:Block else _ => B:Block ... </k>
       <strategy> (step => skip) ; _ </strategy>
       [transition]
  rule <k> if (false) _ else B:Block => B:Block ... </k>
       <strategy> (step => skip) ; _ </strategy>
       [transition]

  rule <k> int (X,Xs => Xs) ; ... </k>
       <state> Rho:Map (.Map => X|->?V:Int) </state>
       <strategy> (step => skip) ; _ </strategy>
       requires notBool (X in keys(Rho))

  rule <k> while (B) STMT => if (B) {STMT while (B) STMT} else {} ... </k>
       <strategy> (step => skip) ; _ </strategy>
```

And we also must instantiate the sort `State`, as well as commands `snapshot`
and `set`, to the language IMP.

```{.imp .k}
  syntax KResult ::= Bool | Int

  rule <k> strategy : S ===== PGM => PGM </k>
       <strategy> _ => S </strategy>

  syntax State ::= "[" K "," Map "]"

  rule <k> KCELL </k>
       <state> STATE </state>
       <strategy> (snapshot => skip) ; _ </strategy>

  rule <k> _ => KCELL </k>
       <state> _ => STATE </state>
       <currState> [ KCELL , STATE ] </currState>
       <strategy> (set => skip) ; _ </strategy>
endmodule
```

Analysis Tools
==============

These modules define the "interfaces" to various analysis. You need to provide
the interpretation of each thing defined as a `Pred`. By importing some
combination of these analysis, you are importing all of their interfaces.

Bounded Invariant Model Checking
--------------------------------

Here we'll define the interface for having a bounded-model checker. This does
not define any new elements of sort `Pred`, so as long as you support the
`STRATEGIES` interface, you support this analysis.

### Language Independent

`fail-bmc` is used to signal that the property has been violated and that
execution should stop. If execution in this augmented theory results in
`fail-bmc` at the top of the `strategy` cell, then the property being checked
was violated.

`check-step` is a helper strategy which will check that a property holds
then take a step, ending in `fail-bmc` if the property fails.

`bmc-invariant` is the overall strategy we're interested in. It will first check
that the proprety is true in the initial state, then repeat `check-step` of the
property the specified number of times.

```{.strat .k}
module ANALYSIS-BMC
  imports STRATEGIES

  syntax Command ::= "fail-bmc"
                   | "check-step" PredState
                   | "bmc-invariant" Int PredState
endmodule
```

### Language Independent (but tied to configuration)

None of this instantiation is actually forced to be specific to IMP, other than
the fact that configurations aren't composable so we have to put these rules
after the declaration of the whole configuration.

```{.imp .k}
module IMP-BMC
  imports IMP-STRATEGIES
  imports ANALYSIS-BMC

  rule <strategy> ( check-step P
                 => { snapshot ; if P then step else fail-bmc ; .Strategy }
                  ) ; _
       </strategy>

  rule <strategy> ( bmc-invariant N P
                 => { repeat N (check-step P) ; check-step P ; .Strategy }
                  ) ; _
       </strategy>
endmodule
```

Semantics Based Compilation
---------------------------

One useful analysis of a program execution is to just track every state reached.
For that, I've subsorted `Rules` into `Analysis`, and defined `Rules` as a
cons-list of rules generated. The interface to this analysis is the
predicate `cut-point?` (to specify when a rule should be finished and a new one
started), and the command `abstract` (to specify how to abstract the state).

### Language Independent

```{.strat .k}
module ANALYSIS-COMPILATION
  imports STRATEGIES

  syntax Rule ::= "<" State "-->" State ">"
  syntax Rules ::= ".Rules"
                 | Rules "," Rule

  syntax Analysis ::= Rules

  syntax PredBoth ::= "new?"
  syntax PredState ::= "cut-point?"

  syntax Command ::= "save"
                   | "abstract"
                   | "compile-step"
                   | "newRule"
                   | "compile"
endmodule
```

### Language Independent (but tied to configuration)

First we define the `new?` predicate, which checks if the current state is 

```{.imp .k}
module IMP-COMPILATION
  imports IMP-STRATEGIES
  imports ANALYSIS-COMPILATION

  rule <strategy> (new? [ S | .Rules ] => predTrue) ; _ </strategy>
  rule <strategy> (new? [ S | (T , < S  --> _ >) ] => predFalse) ; _ </strategy>
  rule <strategy> (new? [ S | (T , < S' --> _ >) ] => new? [ S | T ]) ; _ </strategy>
       requires S =/=K S'
```

Several helper commands are defined for performing this analysis. `save` takes
the current state and saves it to the end of the last rule generated in the
analysis. `compile-step` takes a step, `snapshot`s the state, then `save`s it,
and then `abstract`s it. `newRule` begins building a new rule in the analysis.

```{.imp .k}
  rule <currState> S' </currState>
       <analysis> R , < S --> (_ => S') > </analysis>
       <strategy> (save => skip) ; _ </strategy>

  rule <strategy> (compile-step => { step ; snapshot ; save ; abstract ; .Strategy }) ; _ </strategy>

  rule <currState> S </currState>
       <analysis> R => R , < S --> S > </analysis>
       <strategy> (newRule => skip) ; _ </strategy>
```

Finally, the command `compile` will execute the system symbolically until it
reaches a state that should be abstracted (by checking the `abstract?`
predicate). If so, it abstracts the state then begins building a new rule with
teh abstracted state as the starting point and resumes execution.

```{.imp .k}
  rule <strategy> compile ; .Strategy
               => snapshot
                ; newRule
                ; compile-step
                ; while new? { if cut-point? then newRule else skip
                             ; compile-step
                             ; .Strategy
                             }
                ; .Strategy
       </strategy>
```

### Instantiating to IMP

The only part of this instantiation that is specific to IMP is the `abstract?`
predicate and `abstract` command. Otherwise, everything could be defined prior
to finalizing the configuration.

Here, I specify that only when the top of the KCELL is a `while`-loop should
state-abstraction be done. When it is done, I specify that each value in the
`state` map should be set to a new symbolic value.

```{.imp .k}
  rule <strategy> (cut-point? [ [ while (_:Bool) _ ~> _ , _ ] ] => predTrue) ; _ </strategy>
  rule <strategy> (cut-point? [ [ _ , _ ] ] => predFalse) ; _ </strategy>
       [owise]

  syntax Command ::= "#abstract" Set
                   | "#abstractKey" Id Set

  rule <currState> [ KCELL , STATE ] </currState>
       <strategy> (abstract => #abstract keys(STATE)) ; _ </strategy>

  rule <strategy> (#abstract .Set => skip) ; _ </strategy>
  rule <strategy> (#abstract (SetItem(X) XS) => #abstractKey X XS) ; _ </strategy>
  rule <currState> [ _ , X |-> (_ => ?V:Int) M:Map ] </currState>
       <strategy> (#abstractKey X XS => #abstract XS) ; _ </strategy>
endmodule
```

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

Here I'll demonstrate three analysis using this technique, bounded model
checking, semantics based compilation, and corrective monitoring.

Bounded Invariant Model Checking
--------------------------------

Here we check the property `x > 7` for 10 steps of execution. The example is run
using `krun --search test-bmc.imp`. If any of the solutions contains `fail-bmc`
at the top of the `strategy` cell, then the property is violated in 10 steps.

```test-bmc
strategy : bmc-invariant 10 (x > 7) ; .Strategy

=====

int x ;
x = 0 ;
x = x + 15 ;
```

Semantics Based Compilation
---------------------------

Execute this test file with `krun --search test-compilation.imp`. Every solution
will have it's own trace of generated rules.

```test-compilation
strategy : compile ; .Strategy

=====

int n s ;

while (0 <= n) {
  n = n - 1 ;
  s = s + n ;
}
```
