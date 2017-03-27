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

// IMP Language
// ------------

// This is largely the same as the original `IMP-SYNTAX`, except that I've added a
// new top-sort `Program`. This only has one constructor, which takes a `Command`
// and a `Stmt`, allowing us to specify new strategies in the program itself
// without recompiling the definition (I did this for rapid prototying of new
// strategies to use). I've also moved the semantic rules which are structural (not
// proper transitions) to this module.


require "strategic-analysis.k"

module IMP-SYNTAX
  imports STRATEGIES

  syntax KResult ::= Int | Bool

  syntax Ids ::= List{Id,","}

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

  rule B:BExp => true  requires B ==K true  [structural, transition]
  rule B:BExp => false requires B ==K false [structural, transition]

  syntax Block ::= "{" "}"
                 | "{" Stmt "}"

  rule {}  => . [structural]
  rule {S} => S [structural]

  syntax Stmt  ::= Block
                 | "int" Ids ";"
                 | Id "=" AExp ";"                      [strict(2)]
                 | "if" "(" BExp ")" Block "else" Block [strict(1)]
                 | "while" "(" BExp ")" Block
                 > Stmt Stmt                            [left]

  rule int .Ids ; => . [structural]
  rule S1:Stmt S2:Stmt => S1 ~> S2 [structural]

  syntax Program ::= "command" ":" Command "=====" Stmt
endmodule


// IMP Strategies
// --------------

// This module declares the IMP configuration, with the `symbolicExecution`
// configuration grafted onto it.


module IMP-STRATEGIES
  imports IMP-SYNTAX
  imports STRATEGIES

  configuration <T>
                  <k> $PGM:Program </k>
                  <state> .Map </state>
                  <symbolicExecution>
                    <stack> .Stack </stack>
                    <analysis> .Analysis </analysis>
                    <strategy> .Strategy </strategy>
                  </symbolicExecution>
                </T>

  rule <k> command : C ===== PGM => PGM </k>
       <strategy> _ => C ; .Strategy </strategy>


// ### Language Independent

// The following code could all be moved to the file `strategic-analysis.k` if
// configurations were more composable. This makes sense because these have nothing
// to do with IMP. Contexts in K should fix this.


  // TODO: Can we make these structural rules on the strategy cell?
  rule <strategy> skip ; S => S </strategy>
  rule <strategy> C ; skip ; S => C ; S </strategy>

  rule <strategy> (< .Strategy > => skip) ; _ </strategy>
  rule <strategy> C ; (< .Strategy > => skip) ; S </strategy>
  rule <strategy> < C ; B > ; S => C ; < B > ; S </strategy>
  rule <strategy> C1 ; < C ; B > ; S => C1 ; C ; < B > ; S </strategy>

  rule <strategy> top    ; ? C : _ ; S => C ; S </strategy>
  rule <strategy> bottom ; ? _ : C ; S => C ; S </strategy>

  rule <strategy> (push S => skip) ; _ </strategy> <stack> STACK => S : STACK </stack>                
  rule <strategy> (pop => pop S)   ; _ </strategy> <stack> S : STACK => STACK </stack>                
  rule <strategy> (swap => skip)   ; _ </strategy> <stack> S1 : S2 : STACK => S2 : S1 : STACK </stack>
  rule <strategy> (dup => skip)    ; _ </strategy> <stack> S1 : STACK => S1 : S1 : STACK </stack>     

  rule <strategy> (swapState => < push ; swap ; pop ; .Strategy >) ; _ </strategy>

  rule <strategy> (call C => < swapState ; C ; swapState ; .Strategy >) ; _ </strategy>

  rule <strategy> (exec S => < push S ; call (fix step) ; .Strategy >)  ; _ </strategy>
  rule <strategy> (eval S => < exec S ; bool? ; .Strategy >) ; _ </strategy>

  rule <strategy> (if C then C1 else C2 => < C ; ? C1 : C2 ; .Strategy >) ; _ </strategy>

  rule <strategy> (while S C => if S then < C ; while S C ; .Strategy > else skip) ; _ </strategy>

  rule <strategy> (repeat 0 C => skip)                                    ; _ </strategy>
  rule <strategy> (repeat N C => < repeat (N -Int 1) C ; C ; .Strategy >) ; _ </strategy> requires N >Int 0

  rule <strategy> (fix C => < C ; fix C ; .Strategy >) ; _ </strategy>
  rule <strategy> C ; < fix C ; .Strategy > ; S => S </strategy> [owise]
  rule <strategy> C ; fix C ; S                 => S </strategy> [owise]

  rule <strategy> (OP:StateOp => OP S) ; _ </strategy> <stack> S : STACK => STACK </stack>


// ### Instantiating to IMP

// And we also must instantiate the sort `State`, as well as commands `push` and
// `pop`, to the language IMP.


  syntax State ::= "[" K "|" Map "]"

  rule <strategy> (push => push [ KCELL | STATE ]) ; _ </strategy> <k> KCELL </k>
                                                                   <state> STATE </state>

  rule <strategy> (pop [ KCELL | STATE ] => skip)  ; _ </strategy> <k> _ => KCELL </k>
                                                                   <state> _ => STATE </state>

  rule <strategy> (bool? [ true | _ ]  => top)    ; _ </strategy>
  rule <strategy> (bool? [ false | _ ] => bottom) ; _ </strategy>


// Now we give the semantics of IMP, augmented to work with the symbolic execution
// engine. Almost everything remains unchanged, except for the fact that we've
// added `<strategy> (step => skip) ; S </strategy>` to every rule. Semantically,
// if all the rules had been previously zipped up into one rule
// `rule l=>r : TopSort`, then this would be like replacing that rule with
// `rule l=>r <strategy> (step => skip) ; S </strategy>`. This gives the effect of
// taking exactly one conceptual step with the symbolic execution engine.


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
// the interpretation of each new `StateOp`. By importing some combination of these
// analysis, you are importing all of their interfaces.

// Bounded Invariant Model Checking
// --------------------------------

// Here we'll define the interface for having a bounded invariant model checker.
// This does not define any new elements of sort `Pred`, so as long as you support
// the `STRATEGIES` interface (`step`, `push`, and `push`), you support this
// analysis. Of course, any invariant you want to check yourself you'll have to
// define the semantics for.

// ### Language Independent (but tied to configuration)

// None of this instantiation is actually forced to be specific to IMP, other than
// the fact that configurations aren't composable so we have to put these rules
// after the declaration of the whole configuration.


module IMP-BMC
  imports IMP-STRATEGIES
  imports ANALYSIS-BMC

  rule <analysis> .Analysis => .Trace </analysis>
  rule <strategy> (record STATE => skip) ; _ </strategy> <analysis> TRACE => TRACE ; STATE </analysis>

  rule <strategy> (assert C => < push ; dup ; record ; if C then skip else assertion-failure C ; .Strategy >) ; _ </strategy>
  rule <strategy> (bmc-invariant N C => < assert C ; repeat N < step ; assert C ; .Strategy > ; .Strategy >)  ; _ </strategy>


// ### Instantiating to IMP {#instantiating-to-imp-1}

// We'd like to make normal `BExp` queries about the state (for starters). To do
// so, we subsort `BExp` into `StateOp`.


  syntax StateOp ::= "bool?" BExp

  rule <strategy> (bool? B [ _ | M ] => < exec [ B | M ] ; bool? ; .Strategy >) ; _ </strategy>
endmodule


// Semantics Based Compilation
// ---------------------------

// Here, the result of the analysis will be a list of new rules corresponding to
// the compiled definition. I've subsorted `Rules` into `Analysis`, and defined
// `Rules` as a cons-list of rules generated. The interface to this analysis is the
// predicate `cut-point?` (to specify when a rule should be finished and a new one
// started), and the command `abstract` (to specify how to abstract the state).

// ### Language Independent (but tied to configuration) {#language-independent-but-tied-to-configuration-1}

// First we define the `new?` predicate, which checks if the current state has been
// seen (as the left-hand side of a rule). Note that we *should* be performing an
// implication check here, *not* an exact syntactic equality check. Because of that
// this will loop forever for now. Another check that would work (in this case, at
// least) would be to match the left-hand side of the rules to the abstracted
// state, which means that the left-hand side of the rule is more general.


module IMP-COMPILATION
  imports IMP-STRATEGIES
  imports ANALYSIS-COMPILATION

  rule <strategy> (new? S:State => #new? RS S)           ; _ </strategy> <analysis> RS </analysis>
  rule <strategy> (#new? .Rules _ => top)                ; _ </strategy>
  rule <strategy> (#new? (T , < S  --> _ >) S => bottom) ; _ </strategy>
  rule <strategy> (#new? (T , < S' --> _ > => T) S)      ; _ </strategy> requires S =/=K S'


// Several helper commands are defined for performing this analysis. `extendRule`
// takes the current state and saves it to the end of the last rule generated in
// the analysis. `newRule` begins building a new rule in the analysis.


  rule <strategy> (extendRule => skip) ; _ </strategy> <stack> S' : _ </stack>
                                                       <analysis> R , < S --> (_ => S') > </analysis>

  rule <strategy> (newRule => skip)    ; _ </strategy> <stack> S : _ </stack>
                                                       <analysis> R => R , < S --> S > </analysis>


// `restart` is a macro for `newRule`, followed by `push` (to start execution at
// the beginning of the freshly generated rule). `compile-step` is a macro for
// taking a `step`, `push`ing, calling `extendRule`s, and then `abstract`ing.


  rule <strategy> (restart => < newRule ; push ; .Strategy >)                           ; _ </strategy>
  rule <strategy> (compile-step => < step ; push ; extendRule ; abstract ; .Strategy >) ; _ </strategy> 


// Finally, the command `compile` is a macro for executing the system symbolically
// until it reaches a state that should be abstracted (by checking the `cut-point?`
// predicate). If so, it begins building a new rule with the abstracted state as
// the starting point and resumes execution.


  rule <strategy> ( compile
                 => < push
                    ; newRule
                    ; compile-step
                    ; while new? < if cut-point? then restart else skip
                                 ; compile-step
                                 ; .Strategy
                                 >
                    ; .Strategy
                    >
                  ) ; _
       </strategy>


// ### Instantiating to IMP {#instantiating-to-imp-2}

// The only part of this instantiation that is specific to IMP is the `cut-point?`
// predicate and `abstract` command. Otherwise, everything could be defined prior
// to finalizing the configuration.

// Here, I specify that only when the top of the KCELL is a `while`-loop should
// state-abstraction be done. For abstraction, I specify that each value in the
// `state` map should be set to a new symbolic value.


  rule <strategy> (cut-point? [ while (_:Bool) _ ~> _ | _ ] => top) ; _ </strategy>
  rule <strategy> (cut-point? [ _ | _ ] => bottom)                  ; _ </strategy> [owise]

  syntax StateOp ::= "#abstract"
                   | "#abstract" Set
                   | "#abstractKey" Id Set

  rule <strategy> (abstract => #abstract)            ; _ </strategy>
  rule <strategy> (#abstract .Set S:State => push S) ; _ </strategy>

  rule <strategy> (#abstract [ K | STATE ] => #abstract keys(STATE) [ K | STATE ])                     ; _ </strategy>
  rule <strategy> (#abstract (SetItem(X) XS) S:State => #abstractKey X XS S)                           ; _ </strategy>
  rule <strategy> (#abstractKey X XS [ K | (X |-> _) M:Map ] => #abstract XS [ K | (X |-> ?V:Int) M ]) ; _ </strategy>
endmodule


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
