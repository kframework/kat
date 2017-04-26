// IMP Language
// ============

// The IMP language is largely defined as in the [K
// tutorial](www.kframework.org/index.php/K_Tutorial). Refer there for a more
// detailed explanation of the language.

// ### IMP Syntax

// IMP has `AExp` for arithmetic expressions, `BExp` for boolean expressions, and
// `Stmt` for statements, sequenced by `_;_`. It has `if_then_else_` for control
// flow, `_:=_` for assignment, and `while (_) _` for looping.


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


// ### IMP Semantics

// First the configuration for IMP is given. The sub-configuration `imp`
// corresponds to execution in IMP, while the `strategy` cell sits outside
// controlling the execution. It would be nice to specify the sub-configuration
// `imp` separetely.


module IMP-SEMANTICS
  imports IMP-SYNTAX

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
// strategy is loaded into the `startegy` cell, and the program is loaded into the
// `k` cell in the `imp` execution harness.


  syntax Strategy ::= "strategy" ":" Strategy "=====" Stmt
//--------------------------------------------------------
  rule <strategy> strategy : STRAT:Strategy ===== PGM:Stmt => STRAT </strategy> <k> . => PGM </k>


// Here we give the semantics of IMP augmented to work with the strategy harness.
// Next to each transititon (decided by the language designer), the cell
// `<strategy> (step => skip) ; _ </strategy>` is added. These steps will only be
// executed when the strategy decides to take a `step`.


  syntax Strategy ::= "step" | "skip"
                    | Strategy ";" Strategy [assoc]
//-------------------------------------------------
  rule <strategy> (step => skip) ; _ </strategy> <k> X:Id => I ... </k>
                                                 <mem> ... X |-> I ... </mem>

  rule <strategy> (step => skip) ; _ </strategy> <k> X = I:Int ; => . ... </k>
                                                 <mem> ... X |-> (_ => I) ... </mem>

  rule <strategy> (step => skip) ; _ </strategy> <k> if (true)  B:Block else _ => B:Block ... </k> [transition]
  rule <strategy> (step => skip) ; _ </strategy> <k> if (false) _ else B:Block => B:Block ... </k> [transition]

  rule <strategy> (step => skip) ; _ </strategy> <k> int (X,Xs => Xs) ; ... </k>
                                                 <mem> Rho:Map (.Map => X|->?V:Int) </mem>
                                                 requires notBool (X in keys(Rho))

  rule <strategy> (step => skip) ; _ </strategy> <k> while (B) STMT => if (B) {STMT while (B) STMT} else {} ... </k>
endmodule


// Strategy Language
// =================

// The strategy language used here is a simple imperative language. It has
// sequencing, choice, and looping (in addition to primitives related to
// controlling the `imp` execution state).

// -   Sort `State` is for the bag of cells in the `state` execution harness.


module STRATEGY-IMP
  imports KCELLS
  imports IMP-SEMANTICS

  syntax State ::= Bag


// Strategy Statements
// -------------------

// -   `_;_` is used to sequence primitives in the language (provided above)
// -   `skip` acts as a no-op (provided above)
// -   `step` is used to specify an execution step for your language
// -   `load_` places the given state into the `imp` execution harness
// -   `?_:_` (choice) uses the `Pred` value at the top of the strategy cell to
//     determine what to execute next


  rule <strategy> (skip ; S)      => S      </strategy>
  rule <strategy> (S ; skip ; S') => S ; S' </strategy>

  syntax Strategy ::= "load" State
//--------------------------------
  rule <strategy> (load S  => skip) ; _ </strategy> <state> _ => S </state>

  syntax Pred ::= "#true" | "#false"
  syntax Strategy ::= Pred
                    | "?" Strategy ":" Strategy
//---------------------------------------------
  rule <strategy> (#true  ; ? S : _ => S) ; _ </strategy>
  rule <strategy> (#false ; ? _ : S => S) ; _ </strategy>


// Strategy Predicates
// -------------------

// Predicates serve as the boolean sort for the strategy language. Lazy semantics
// ("short-circuit") are given via controlled heating and cooling.


  syntax Pred ::= "#pred" | "not" Pred | Pred "or" Pred | Pred "and" Pred
//-----------------------------------------------------------------------
  rule <strategy> (not P => P ; not #pred)       ; _ </strategy>
  rule <strategy> (#false ; not #pred => #true)  ; _ </strategy>
  rule <strategy> (#true  ; not #pred => #false) ; _ </strategy>

  rule <strategy> (P or Q => P ; #pred or Q)     ; _ </strategy>
  rule <strategy> (#true  ; #pred or _ => #true) ; _ </strategy>
  rule <strategy> (#false ; #pred or Q => Q)     ; _ </strategy>

  rule <strategy> (P and Q => P ; #pred and Q)     ; _ </strategy>
  rule <strategy> (#true  ; #pred and Q => Q)      ; _ </strategy>
  rule <strategy> (#false ; #pred and Q => #false) ; _ </strategy>


// -   `bool?` checks if the `k` cell has just the constant `true`/`false` in it
// -   `finished?` checks if the `k` cell is empty (ie. execution of that machine
//     has terminated) or just has a boolean


  syntax Pred ::= "bool?"
//-----------------------
  rule <strategy> (bool? => #true)  ; _ </strategy> <k> true  </k>
  rule <strategy> (bool? => #false) ; _ </strategy> <k> false </k>

  syntax Pred ::= "finished?"
//---------------------------
  rule <strategy> (finished? => #true)  ; _ </strategy> <k> .     </k>
  rule <strategy> (finished? => #true)  ; _ </strategy> <k> true  </k>
  rule <strategy> (finished? => #true)  ; _ </strategy> <k> false </k>
  rule <strategy> (finished? => #false) ; _ </strategy> <k> _     </k> [owise]


// Strategy Macros
// ---------------

// -   `while__` allows looping behavior (controlled by sort `Pred`), and
//     `while___` implements a bounded version.
// -   `step-to_` will execute until a predicate holds, and `step-to__` implements
//     a bounded version.


  syntax Strategy ::= "while" Pred Strategy | "while" Int Pred Strategy
//---------------------------------------------------------------------
  rule <strategy> (while   P S => P ; ? (S ; while P S) : skip)            ; _ </strategy>
  rule <strategy> (while 0 P S => skip)                                    ; _ </strategy>
  rule <strategy> (while N P S => P ; ? (S ; while (N -Int 1) P S) : skip) ; _ </strategy> requires N >Int 0

  syntax Strategy ::= "step-to" Pred | "step-to" Int Pred
//--------------------------------------------------------
  rule <strategy> (step-to   P => while   (not P) step) ; _ </strategy>
  rule <strategy> (step-to N P => while N (not P) step) ; _ </strategy> requires N >Int 0


// -   `exec_` executes the given state to completion, and `exec__` implements a
//     bounded version. Note that `krun == exec_`.
// -   `eval_` executes a given state to completion and checks `bool?`, and
//     `eval__` implements a bounded version.


  syntax Strategy ::= "exec" State | "exec" Int State
//---------------------------------------------------
  rule <strategy> (exec   STATE => load STATE ; step-to   finished? ; load STATE') ; _ </strategy> <state> STATE' </state>
  rule <strategy> (exec N STATE => load STATE ; step-to N finished? ; load STATE') ; _ </strategy> <state> STATE' </state>

  syntax Strategy ::= "eval" State | "exec" Int State
//---------------------------------------------------
  rule <strategy> (eval   STATE => exec   STATE ; bool?) ; _ </strategy>
  rule <strategy> (eval N STATE => exec N STATE ; bool?) ; _ </strategy>
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


// -   `record` copies the current execution state to the end of the trace.


  syntax Strategy ::= "record"
//----------------------------
  rule <strategy> (record S => skip) ; _ </strategy> <analysis> T => T ; S </analysis>


// -   `assertion-failure` indicates that the given predicate failed within the
//     execution bound
// -   `assertion-success` inidicates that either the depth bound has been reached,
//     or execution has terminated


  syntax Strategy ::= "assertion-failure" Pred | "assertion-success"


// Performing bounded invariant model checking is a simple macro in our strategy
// language.

// -   `bimc` checks that the predicate holds for each step up to a
//     search-depth bound.


  syntax Strategy ::= "bmc-invariant" Int Pred
//--------------------------------------------
  rule <strategy> ( bmc-invariant N P
                 => record
                  ; while N P (step ; record)
                  ; P ; ? assertion-success : assertion-failure P
                  ) ; _
       </strategy>
       <analysis> _ => .Trace </analysis>
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
  rule <strategy> (bexp? B => eval (<k> B </k> <mem> MEM </mem>)) ; _ </strategy> <mem> MEM </mem>
endmodule


// ### Future Work

// -   This should extended to model checking more than invariants by defining the
//     appropriate derivatives of your favorite temporal logic's formula.
// -   We should be able to use arbitrary ML patterns as sort `Pred`.

// Semantics Based Compilation
// ---------------------------

// Semantics based compilation corresponds to reducing the size of transition
// system defined by programming language semantics. A much tighter approximation
// of the transition system is generated by executing the program symbolically.
// Termination is guaranteed by providing an "abstract enough" abstraction
// operator, which ensures that all executions in that language terminates.
// Providing an abstraction operator that is too abstract will yield worse
// compilation results.

// As we execute, we'll collect new the states we've seen so far as a new `Rule` of
// the smaller transition system. Anytime we reach a state which is subsumed by the
// left-hand-side of one of our generated rules, we'll stop exploring that path.

// I've subsorted `Rules` into `Analysis`, and defined `Rules` as a cons-list of
// `Rule`.


module STRATEGY-SBC
  imports STRATEGY

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
  rule <strategy> (#subsumed? .Rules => bottom)                                             ; _ </strategy>
  rule <strategy> (#subsumed? (RS , < LHS --> _ >) => (LHS subsumes STATE) or #subsumed? RS ; _ </strategy> <state> STATE </state>


// At cut-points, we'll finish the rule we've been building, abstract the state,
// start a building a new rule from that state.

// -   `begin-rule` will use the current state as the left-hand-side of a new rule
//     in the record of rules.
// -   `end-rule` uses the current state as the right-hand-side of a new rule in
//     the record of rules.


  syntax Strategy ::= "begin-rule"
//--------------------------------
  rule <strategy> (begin-rule => skip) ; _ </strategy> <analysis> RS => RS ; < STATE > </analysis>
                                                       <state> STATE </state>

  syntax Strategy ::= "end-rule"
//------------------------------
  rule <strategy> (end-rule => skip)   ; _ </strategy> <analysis> RS ; (< S > => < S --> STATE >) </analysis>
                                                       <state> STATE </state>


// Finally, semantics based compilation is provided as a macro.

// -   `compile` will execute a program using the given `cut-point?` and `abstract`
//     operators until it has collected a complete set of rules.


  syntax Strategy ::= "compile"
//-----------------------------
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
endmodule


// ### Instantiating to IMP {#instantiating-to-imp-1}


module IMP-SBC
  imports STRATEGY-SBC

// Define `cut-point?`
//--------------------
  rule <strategy> (cut-point? => top)    ; _ </strategy> <k> while _ _ ... </k>
  rule <strategy> (cut-point? => bottom) ; _ </strategy> [owise]

// Define `abstract`
//------------------
  rule <strategy> (abstract => #abstract keys(MEM)) ; _ </strategy> <mem> MEM </mem>

  syntax Strategy ::= "#abstract" Set | "#abstractKey" Id
//-------------------------------------------------------
  rule <strategy> (#abstract .Set            => skip)                          ; _ </strategy>
  rule <strategy> (#abstract (SetItem(X) XS) => #abstractKey X ; #abstract XS) ; _ </strategy>
  rule <strategy> (#abstractKey X => skip) ; _ </strategy> <mem> ... (X |-> _ => ?V:Int) ... </mem>

// Define `_subsumes_`
//--------------------
  rule <strategy> ((<imp> <k> KCELL </k> _ </imp> subsumes <imp> <k> KCELL  </k> _ </imp>) => #true)  ; _ </strategy>
  rule <strategy> ((<imp> <k> KCELL </k> _ </imp> subsumes <imp> <k> KCELL' </k> _ </imp>) => #false) ; _ </strategy> requires KCELL =/=K KCELL'
endmodule


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
