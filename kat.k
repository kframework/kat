// K Analysis Tools (KAT)
// ======================

// These modules define the "interfaces" to various analysis, and provide the
// implementation of those interfaces for IMP. The syntax `strategy :_=====_`
// allows specifying a strategy and a program. The strategy is loaded into the
// `strategy` cell, and the program is loaded into the `k` cell in the `imp`
// execution harness.

// Bounded Invariant Model Checking
// --------------------------------

// In bounded invariant model checking, the analysis being performed is a trace of
// the execution states that we have seen.


module STRATEGY-BIMC
  imports STRATEGY-IMP

  syntax State
  syntax Pred

  syntax Trace ::= ".Trace"
                 | Trace ";" Cell

  syntax Analysis ::= Trace


// -   `analysis-trace` sets the current analysis to a `Trace`.
// -   `record` copies the current execution state to the end of the trace.


  syntax Strategy ::= "record"
//----------------------------
//  rule <s> (record => skip) ; _ </s> <imp> S </imp>
//                                     <analysis> T => T ; S </analysis>


// -   `assertion-failure` indicates that the given predicate failed within the
//     execution bound
// -   `assertion-success` inidicates that either the depth bound has been reached,
//     or execution has terminated


  syntax Strategy ::= "assertion-failure" Pred | "assertion-success"


// Performing bounded invariant model checking is a simple macro in our strategy
// language.

// -   `bimc` checks that the predicate holds for each step up to a
//     search-depth bound.


  syntax Strategy ::= "bimc" Int Pred
//-----------------------------------
  rule <s> ( bimc N P
           => analysis .Trace
             ; record
             ; while N P
                 { step
                 ; record
                 }
             ; P ; ? assertion-success : assertion-failure P
           )
           ...
       </s>
endmodule


// ### Instantiating to IMP

// Here we provide a way to make queries about the current IMP memory using IMP's
// `BExp` sort directly.

// -   `bexp?` is a predicate that allows us to make queries about the current
//     execution memory.

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
  rule <s> (subsumed? => #subsumed? RS) ; _ </s> <analysis> RS </analysis>

  syntax Pred ::= "#subsumed?" Rules
//----------------------------------
  rule <s> (#subsumed? .Rules => #false)                                              ; _ </s>
  rule <s> (#subsumed? (RS , < LHS --> _ >) => (LHS subsumes STATE) or #subsumed? RS) ; _ </s> <imp> STATE </imp>


// At cut-points, we'll finish the rule we've been building, abstract the state,
// start a building a new rule from that state.

// -   `begin-rule` will use the current state as the left-hand-side of a new rule
//     in the record of rules.
// -   `end-rule` uses the current state as the right-hand-side of a new rule in
//     the record of rules.


  syntax Strategy ::= "begin-rule"
//--------------------------------
//  rule <s> (begin-rule => skip) ; _ </s> <analysis> RS => RS , < STATE > </analysis>
//                                         <imp> STATE </imp>

  syntax Strategy ::= "end-rule"
//------------------------------
//  rule <s> (end-rule => skip)   ; _ </s> <analysis> RS , (< LHS > => < LHS --> STATE >) </analysis>
//                                         <imp> STATE </imp>


// Finally, semantics based compilation is provided as a macro.

// -   `compile` will execute a program using the given `cut-point?` and `abstract`
//     operators until it has collected a complete set of rules.


  syntax Strategy ::= "compile"
//-----------------------------
  rule <s> ( compile
          => { analysis .Rules
             ; abstract
             ; begin-rule
             ; while (not (stuck? or subsumed?))
                 { step until (stuck? or cut-point?)
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


// ### Instantiating to IMP {#instantiating-to-imp-1}

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
