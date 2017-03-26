// Introduction
// ============

// Here I define a strategy language for controlling symbolic execution, and show
// some simple analysis we can define from within K itself. The language IMP is
// used as a running example, and the theory transformations over IMP's semantics
// are performed by hand, but in a uniform way with an eye towards automatability.

// The idea here is that once you have control over symbolic execution from within
// K, it becomes much easier to prototype the program analysis we normally would do
// in a backend. As such, some time is spent building a robust strategy language.

// Strategies
// ----------

// First there is a module `STRATEGIES` which defines a small machine for
// controlling the symbolic execution of a program. This machine has a single
// temporary register, where one `State` is stored. It also has storage for the
// results of an `Analysis`. An interface of minimal commands is exported (`step`,
// `snapshot`, and `set`) for the instrumentation of analysis tools to your
// language. A simple imerative language over these operations is built, which is
// called a `Strategy`.


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


// Ideally, we could enter strategies on the fly (ie. in the debugger). Really,
// this `STRATEGIES` module is just about getting control over the symbolic
// execution engine from inside K itself. After experimenting with strategies in an
// interactive session, one could save out the result as a macro-command in a
// library that ships with K. This would make writing future analysis tools easier.

// Analysis Tools
// ==============

// These modules define the "interfaces" to various analysis. You need to provide
// the interpretation of each thing defined as a `Pred`. By importing some
// combination of these analysis, you are importing all of their interfaces.

// Bounded Invariant Model Checking
// --------------------------------

// Here we'll define the interface for having a bounded-model checker. This does
// not define any new elements of sort `Pred`, so as long as you support the
// `STRATEGIES` interface, you support this analysis.

// ### Language Independent {#language-independent-1}

// `fail-bmc` is used to signal that the property has been violated and that
// execution should stop. If execution in this augmented theory results in
// `fail-bmc` at the top of the `strategy` cell, then the property being checked
// was violated.

// `check-step` is a helper strategy which will check that a property holds then
// take a step, ending in `fail-bmc` if the property fails.

// `bmc-invariant` is the overall strategy we're interested in. It will first check
// that the proprety is true in the initial state, then repeat `check-step` of the
// property the specified number of times.


module ANALYSIS-BMC
  imports STRATEGIES

  syntax Command ::= "fail-bmc"
                   | "check-step" PredState
                   | "bmc-invariant" Int PredState
endmodule


// Semantics Based Compilation
// ---------------------------

// One useful analysis of a program execution is to just track every state reached.
// For that, I've subsorted `Rules` into `Analysis`, and defined `Rules` as a
// cons-list of rules generated. The interface to this analysis is the predicate
// `cut-point?` (to specify when a rule should be finished and a new one started),
// and the command `abstract` (to specify how to abstract the state).

// ### Language Independent {#language-independent-2}


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

