// IMP Language
// ============

// The IMP language is largely defined as in the [K
// tutorial](www.kframework.org/index.php/K_Tutorial). Refer there for a more
// detailed explanation of the language.

// ### IMP Syntax

// IMP has `AExp` for arithmetic expressions, `BExp` for boolean expressions, and
// `Stmt` for statements, sequenced by `_;_`. It has `if_then_else_` for control
// flow, `_:=_` for assignment, and `while (_) _` for looping.


module IMP
  imports MAP

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

  rule I1 <= I2   => I1 <=Int I2
  rule ! T        => notBool T
  rule true  && B => B
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

  rule {}              => .        [structural]
  rule {S}             => S        [structural]
  rule int .Ids ;      => .        [structural]
  rule S1:Stmt S2:Stmt => S1 ~> S2 [structural]

  syntax KResult ::= Int | Bool
endmodule


// ### IMP Semantics

// First the configuration for IMP is given. The sub-configuration `imp`
// corresponds to execution in IMP, while the `strategy` cell sits outside
// controlling the execution. It would be nice to specify the sub-configuration
// `imp` separetely.


module IMP-SEMANTICS
  imports IMP

  configuration <T>
                  <symbolicExecution multiplicity="*">
                    <strategy> $PGM:Strategy </strategy>
                    <analysis> .Analysis </analysis>
                    <state>
                      <imp>
                        <k> . </k>
                        <mem> .Map </mem>
                      </imp>
                    </state>
                  </symbolicExecution>
                </T>


// -   Sort `Analysis` corresponds to the results of running the strategy program.


  syntax Analysis ::= ".Analysis"


// The sort `Strategy` will correspond to a program in the strategy language. The
// syntax `strategy :_=====_` allows specifying a strategy and a program. The
// strategy is loaded into the `strategy` cell, and the program is loaded into the
// `k` cell in the `imp` execution harness.


  syntax Strategy ::= ".Strategy"
                    | Command ";" Strategy
                    | "strategy" ":" Command "=====" Stmt
//-------------------------------------------------------
  rule <strategy> strategy : C ===== PGM => C ; .Strategy </strategy> <k> . => PGM </k>


// Here we give the semantics of IMP augmented to work with the strategy harness.
// Next to each transititon (decided by the language designer), the cell
// `<strategy> (step => skip) ; _ </strategy>` is added. These steps will only be
// executed when the strategy decides to take a `step`.


  syntax Command ::= "step" | "skip"
//----------------------------------
  rule <strategy> (step => skip) ; _ </strategy> <k> X:Id => I ... </k>
                                                 <mem> ... X |-> I ... </mem>

  rule <strategy> (step => skip) ; _ </strategy> <k> X = I:Int ; => . ... </k>
                                                 <mem> ... X |-> (_ => I) ... </mem>

  rule <strategy> (step => skip) ; _ </strategy> <k> if (true)  B:Block else _ => B:Block ... </k> [transition]
  rule <strategy> (step => skip) ; _ </strategy> <k> if (false) _ else B:Block => B:Block ... </k> [transition]

  rule <strategy> (step => skip) ; _ </strategy> <k> while (B) STMT => if (B) {STMT while (B) STMT} else {} ... </k>


// When we figure out subconfigurations we'll be able to put this with the rest of
// the IMP semantics.


  rule <k> int (X,Xs => Xs) ; ... </k> <mem> Rho:Map (.Map => X |-> ?V:Int) </mem>
    requires notBool (X in keys(Rho))
endmodule


// Strategy Language
// =================

// The strategy language used here is a simple imperative language. It has
// sequencing, choice, and looping (in addition to primitives related to
// controlling the `imp` execution state).

// -   Sort `State` is for the bag of cells in the `state` execution harness.
// -   `#current` is used as a marker to indicate that the current state should
//     be used.


module STRATEGY-IMP
  imports KCELLS
  imports IMP-SEMANTICS

  syntax State ::= Bag
                 | "#current"


// Strategy Statements
// -------------------

// -   `_;_` is used to sequence primitives in the language (provided above)
// -   `{_}` is used to turn a `Strategy` into a single `Command`
// -   `?_:_` (choice) uses the `Pred` value at the top of the strategy cell to
//     determine what to execute next


  syntax Command ::= "{" Strategy "}"
//-----------------------------------
  rule <strategy> ({ .Strategy } => skip) ; _ </strategy>
  rule <strategy> { C ; S }      ; S' => C ; { S }      ; S' </strategy>
  rule <strategy> C ; { C' ; S } ; S' => C ; C' ; { S } ; S' </strategy>

  syntax Pred ::= "#true" | "#false"
  syntax Command ::= Pred
                   | "?" Command ":" Command
//------------------------------------------
  rule <strategy> #true  ; ? C : _ ; S => C ; S </strategy>
  rule <strategy> #false ; ? _ : C ; S => C ; S </strategy>


// -   `skip` acts as a no-op (provided above)
// -   `step` is used to specify an execution step for your language
// -   `load_` places the given state into the `imp` execution harness


  rule <strategy> skip ; S     => S     </strategy>
  rule <strategy> C ; skip ; S => C ; S </strategy>

  syntax Command ::= "load" State
//-------------------------------
  rule <strategy> (load #current => skip) ; _ </strategy>
  rule <strategy> (load S        => skip) ; _ </strategy> <state> _ => S </state> requires S =/=K #current

  syntax Command ::= "analysis" K
//-------------------------------
  rule <strategy> (analysis K => skip) ; _ </strategy> <analysis> _ => K </analysis>


// Strategy Predicates
// -------------------

// Predicates serve as the boolean sort for the strategy language. Lazy semantics
// ("short-circuit") are given via controlled heating and cooling.


  syntax Pred ::= "#pred" | "(" Pred ")" [bracket]
                | "not" Pred | Pred "or" Pred | Pred "and" Pred
//-------------------------------------------------------------
  rule <strategy> not P ; S => P ; not #pred ; S </strategy>
  rule <strategy> #false ; not #pred ; S => #true  ; S </strategy>
  rule <strategy> #true  ; not #pred ; S => #false ; S </strategy>

  rule <strategy> P or Q ; S => P ; #pred or Q ; S </strategy>
  rule <strategy> #true  ; #pred or _ ; S => #true ; S </strategy>
  rule <strategy> #false ; #pred or Q ; S => Q     ; S </strategy>

  rule <strategy> P and Q ; S => P ; #pred and Q ; S </strategy>
  rule <strategy> #true  ; #pred and Q ; S => Q      ; S </strategy>
  rule <strategy> #false ; #pred and _ ; S => #false ; S </strategy>


// -   `bool?` checks if the `k` cell has just the constant `true`/`false` in it
// -   `finished?` checks if the `k` cell is empty (ie. execution of that machine
//     has terminated) or just has a boolean.


  syntax Pred ::= "bool?"
//-----------------------
  rule <strategy> (bool? => #true)  ; _ </strategy> <k> true  </k>
  rule <strategy> (bool? => #false) ; _ </strategy> <k> false </k>

  syntax Pred ::= "finished?"
//---------------------------
  rule <strategy> (finished? => #true)  ; _ </strategy> <state> <k> .K    </k> ... </state>
  rule <strategy> (finished? => #true)  ; _ </strategy> <state> <k> true  </k> ... </state>
  rule <strategy> (finished? => #true)  ; _ </strategy> <state> <k> false </k> ... </state>
  rule <strategy> (finished? => #false) ; _ </strategy> <state> <k> KCELL </k> ... </state> [owise]


// Strategy Macros
// ---------------

// -   `while__` allows looping behavior (controlled by sort `Pred`), and
//     `while___` implements a bounded version.
// -   `step-to_` will execute until a predicate holds, and `step-to__` implements
//     a bounded version.


  syntax Command ::= "while" Pred Command | "while" Int Pred Command
//------------------------------------------------------------------
  rule <strategy> (while   P C => { P ; ? { C ; while P C ; .Strategy }            : skip ; .Strategy }) ; _ </strategy>
  rule <strategy> (while 0 P C => skip)                                                                  ; _ </strategy>
  rule <strategy> (while N P C => { P ; ? { C ; while (N -Int 1) P C ; .Strategy } : skip ; .Strategy }) ; _ </strategy> requires N >Int 0

  syntax Command ::= "step-to" Pred | "step-to" Int Pred
//------------------------------------------------------
  rule <strategy> (step-to   P => while   (not P) step) ; _ </strategy>
  rule <strategy> (step-to N P => while N (not P) step) ; _ </strategy> requires N >Int 0


// -   `exec_` executes the given state to completion, and `exec__` implements a
//     bounded version. Note that `krun == exec #current`.
// -   `eval_` executes a given state to completion and checks `bool?`, and
//     `eval__` implements a bounded version.


  syntax Command ::= "exec" State | "exec" Int State
//--------------------------------------------------
  rule <strategy> (exec         S => { load S ; step-to   finished? ; .Strategy }) ; _ </strategy>
  rule <strategy> (exec (N:Int) S => { load S ; step-to N finished? ; .Strategy }) ; _ </strategy>

  syntax Command ::= "eval" State | "eval" Int State
//--------------------------------------------------
  rule <strategy> (eval         S => { exec   S ; bool? ; load S' ; .Strategy }) ; _ </strategy> <state> S' </state>
  rule <strategy> (eval (N:Int) S => { exec N S ; bool? ; load S' ; .Strategy }) ; _ </strategy> <state> S' </state>
endmodule


// Analysis Tools
// ==============

// These modules define the "interfaces" to various analysis, and provide the
// implementation of those interfaces for IMP.


module IMP-ANALYSIS
  imports IMP-BIMC
  imports IMP-SBC
endmodule


// Bounded Invariant Model Checking
// --------------------------------

// In bounded invariant model checking, the analysis being performed is a trace of
// the execution states that we have seen.


module STRATEGY-BIMC
  imports STRATEGY-IMP

  syntax State
  syntax Pred

  syntax Trace ::= ".Trace"
                 | Trace ";" State

  syntax Analysis ::= Trace


// -   `analysis-trace` sets the current analysis to a `Trace`.
// -   `record` copies the current execution state to the end of the trace.


  syntax Command ::= "record"
//---------------------------
  rule <strategy> (record => skip) ; _ </strategy> <analysis> T => T ; S </analysis>
                                                   <state> S </state>


// -   `assertion-failure` indicates that the given predicate failed within the
//     execution bound
// -   `assertion-success` inidicates that either the depth bound has been reached,
//     or execution has terminated


  syntax Command ::= "assertion-failure" Pred | "assertion-success"


// Performing bounded invariant model checking is a simple macro in our strategy
// language.

// -   `bimc` checks that the predicate holds for each step up to a
//     search-depth bound.


  syntax Command ::= "bimc" Int Pred
//----------------------------------
  rule <strategy> ( bimc N P
                 => { analysis .Trace
                    ; record
                    ; while N P
                        { step
                        ; record
                        ; .Strategy
                        }
                    ; P ; ? assertion-success : assertion-failure P
                    ; .Strategy
                    }
                  )
                  ; _
       </strategy>
endmodule


// ### Instantiating to IMP

// Here we provide a way to make queries about the current IMP memory using IMP's
// `BExp` sort directly.

// -   `bexp?` is a predicate that allows us to make queries about the current
//     execution memory.


module IMP-BIMC
  imports STRATEGY-BIMC

  syntax Pred ::= "bexp?" BExp
//----------------------------
  rule <strategy> (bexp? B => eval (<imp> <k> B </k> <mem> MEM </mem> </imp>)) ; _ </strategy> <mem> MEM </mem>
endmodule


// ### BIMC Examples

// Here we check the property `x <= 7` for 5 steps of execution after the code has
// initialized (the `step` in front of the command). Run this with
// `krun --search bimc.imp`. Every solution should be checked for
// `assertion-failure_` or `assertion-success`.

// ### Future Work

// -   This should extended to model checking more than invariants by defining the
//     appropriate derivatives of your favorite temporal logic's formula.
// -   We should be able to use arbitrary matching-logic patterns as sort `Pred`.

// Semantics Based Compilation
// ---------------------------

// Semantics based compilation uses symbolic execution to reduce the size of
// transition system defined by programming language semantics. As the program is
// executed symbolically, the execution state is periodically "abstracted" with a
// language-specific abstraction operator. The abstraction operator must be
// powerful enough to guarantee termination of every program in the language.
// However, if the abstraction is too strong, the transition system will not be
// reduced in size very much, yielding worse compilation results.

// As we execute, we'll collect new the states we've seen so far as a new `Rule` of
// the smaller transition system. Anytime we reach a state which is subsumed by the
// left-hand-side of one of our generated rules, we'll stop exploring that path.

// I've subsorted `Rules` into `Analysis`, and defined `Rules` as a cons-list of
// `Rule`.


module STRATEGY-SBC
  imports STRATEGY-IMP

  syntax State
  syntax Pred

  syntax Rule ::= "<" State ">"
                | "<" State "-->" State ">"

  syntax Rules ::= ".Rules"
                 | Rules "," Rule

  syntax Analysis ::= Rules


// The interface of this analysis requires you define when to abstract and how to
// abstract. The instantiation to IMP is provided.

// -   `cut-point?` is a predicate that should hold when abstraction should occur.
// -   `abstract` is an operator than should abstract away enough details of the
//     state to guarantee termination. Note that `abstract` needs to also take care
//     not to destroy all information collected about the state in this execution.


  syntax Pred ::= "cut-point?" | "abstract"


// -   `subsumed?` is a predicate that checks if any of the left-hand sides of the
//     rules `_subsumes_` the current state. Note that below we provide the
//     instantiation of `_subsumes_` to IMP manually, but in principle this
//     should inferred.


  syntax Pred ::= "subsumed?" | State "subsumes" State
//----------------------------------------------------
  rule <strategy> (subsumed? => #subsumed? RS) ; _ </strategy> <analysis> RS </analysis>

  syntax Pred ::= "#subsumed?" Rules
//----------------------------------
  rule <strategy> (#subsumed? .Rules => #false)                                              ; _ </strategy>
  rule <strategy> (#subsumed? (RS , < LHS --> _ >) => (LHS subsumes STATE) or #subsumed? RS) ; _ </strategy> <state> STATE </state>


// At cut-points, we'll finish the rule we've been building, abstract the state,
// start a building a new rule from that state.

// -   `begin-rule` will use the current state as the left-hand-side of a new rule
//     in the record of rules.
// -   `end-rule` uses the current state as the right-hand-side of a new rule in
//     the record of rules.


  syntax Command ::= "begin-rule"
//-------------------------------
  rule <strategy> (begin-rule => skip) ; _ </strategy> <analysis> RS => RS , < STATE > </analysis>
                                                       <state> STATE </state>

  syntax Command ::= "end-rule"
//-----------------------------
  rule <strategy> (end-rule => skip)   ; _ </strategy> <analysis> RS , (< LHS > => < LHS --> STATE >) </analysis>
                                                       <state> STATE </state>


// Finally, semantics based compilation is provided as a macro.

// -   `compile` will execute a program using the given `cut-point?` and `abstract`
//     operators until it has collected a complete set of rules.


  syntax Command ::= "compile"
//----------------------------
  rule <strategy> ( compile
                 => { analysis .Rules
                    ; abstract
                    ; begin-rule
                    ; while (not (finished? or subsumed?))
                        { step-to (finished? or cut-point?)
                        ; end-rule
                        ; abstract
                        ; begin-rule
                        ; .Strategy
                        }
                    ; end-rule
                    ; .Strategy
                    }
                  )
                  ; _
       </strategy>
       <analysis> _ => .Rules </analysis>
endmodule


// ### Instantiating to IMP {#instantiating-to-imp-1}


module IMP-SBC
  imports STRATEGY-SBC

// Define `cut-point?`
//--------------------
  rule <strategy> (cut-point? => #true)  ; _ </strategy> <k> while _ _ ... </k>
  rule <strategy> (cut-point? => #false) ; _ </strategy> [owise]

// Define `abstract`
//------------------
  rule <strategy> (abstract => #abstract keys(MEM)) ; _ </strategy> <mem> MEM </mem>

  syntax Command ::= "#abstract" Set | "#abstractKey" Id
//------------------------------------------------------
  rule <strategy> (#abstract .Set            => skip)                                          ; _ </strategy>
  rule <strategy> (#abstract (SetItem(X) XS) => { #abstractKey X ; #abstract XS ; .Strategy }) ; _ </strategy>
  rule <strategy> (#abstractKey X => skip) ; _ </strategy> <mem> ... X |-> (_ => ?V:Int) ... </mem>

// Define `_subsumes_`
//--------------------
  rule <strategy> ((<imp> <k> KCELL </k> _ </imp>) subsumes (<imp> <k> KCELL  </k> _ </imp>) => #true)  ; _ </strategy>
  rule <strategy> ((<imp> <k> KCELL </k> _ </imp>) subsumes (<imp> <k> KCELL' </k> _ </imp>) => #false) ; _ </strategy> requires KCELL =/=K KCELL'
endmodule


// ### SBC Examples

// Execute this test file with `krun --search sbc.imp`. Every solution will have
// it's own trace of generated rules.

// ### Future Work {#future-work-1}

// -   Post-process the results of the compilation with another abstraction pass
//     which just hashes the contents of the `k` cell for each rule. This will
//     reduce the amount of extra matching that happens in executing the
//     compiled definition.
// -   Use matching-logic implication to implement `_subsumes_` in a
//     language-indepedent way.

// Corrective Model Checking
// -------------------------

// Corrective model-checking extends semantics based compilation by restricting the
// generated transition systems to only traces which satisfy the given property.
// The strategy will only allow execution to continue if the property specified is
// satisfied.

// Not implemented yet.
