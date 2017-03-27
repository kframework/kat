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

// Strategies
// ----------

// First there is a module `STRATEGIES` which defines a small stack machine for
// controlling the symbolic execution of a program. This machine has a stack of
// program states which it can `push` to (take a snapshot of current program
// execution state) and `pop` from (set the current execution state to top of
// stack). `step` is builtin as a primitive in the language, which is implemented
// as an instrumentation of the semantics to control execution. It also has a
// memory of sort `Analysis` (the results of whatever analysis is being performed
// by the strategy). A simple imperative language is built over these primitive
// actions, which allows for simple control-flow.


// Copyright (c) 2014-2016 K Team. All Rights Reserved.

module STRATEGIES

  syntax State
  syntax Stack ::= ".Stack"
                 | State ":" Stack
  
  syntax Analysis ::= ".Analysis"

  syntax StateOp ::= "bool?"
                   | "exec"
                   | "eval"

  syntax OpResult ::= "top" | "bottom"

  syntax Command ::= "skip" | "step"
                   | "push" | "push" State
                   | "pop"  | "pop"  State
                   | "swap"
                   | "call" Command
                   | StateOp | StateOp State | OpResult
                   | "?" Command ":" Command

  syntax Command ::= "<" Strategy ">"
                   | "if" StateOp "then" Command "else" Command
                   | "while" StateOp Command
                   | "repeat" Int Command
                   | "fix" Command
                   | "swapState" | "dup"

  syntax Strategy ::= ".Strategy"
                    | Command ";" Strategy
endmodule


// Ideally, we could enter strategies on the fly (ie. in the debugger). Really,
// this `STRATEGIES` module is just about getting control over the symbolic
// execution engine from inside K itself. After experimenting with strategies in an
// interactive session, one could save out the result as a macro-command in a
// library that ships with K. This would make rapidly prototyping new analysis even
// easier; right now I'm relying on the fact that I augmented IMP with the sort
// `Program` to rapidly test new strategies.

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

// ### Language Independent {#language-independent-1}

// `assertion-failure` is used to signal that the property has been violated and
// that execution should stop. If execution in this augmented theory results in
// `assertion-failure` at the top of the `strategy` cell, then the property being
// checked was violated.

// `assert` is a helper strategy which will check that a property holds, ending in
// `assertion-failure` if the property fails.

// `bmc-invariant` is the overall strategy we're interested in. It will first check
// that the proprety is true in the initial state, then repeat `check-step` of the
// property the specified number of times.


module ANALYSIS-BMC
  imports STRATEGIES

  syntax StateOp ::= "record"

  syntax Command ::= "assertion-failure" StateOp
                   | "assert" StateOp
                   | "bmc-invariant" Int StateOp

  syntax Trace ::= ".Trace"
                 | Trace ";" State
  syntax Analysis ::= Trace
endmodule


// The analysis we'll be performing is just keeping track of the trace of the
// state. If we end and `assertion-failure` is at the top of the strategy cell,
// then the trace will be an execution which violates the invariant. If we end with
// an empty strategy cell, then the program has been verified up to the bound to
// remain within the invariant.

// Semantics Based Compilation
// ---------------------------

// Here, the result of the analysis will be a list of new rules corresponding to
// the compiled definition. I've subsorted `Rules` into `Analysis`, and defined
// `Rules` as a cons-list of rules generated. The interface to this analysis is the
// predicate `cut-point?` (to specify when a rule should be finished and a new one
// started), and the command `abstract` (to specify how to abstract the state).

// ### Language Independent {#language-independent-2}


module ANALYSIS-COMPILATION
  imports STRATEGIES

  syntax Rule ::= "<" State "-->" State ">"
  syntax Rules ::= ".Rules"
                 | Rules "," Rule

  syntax Analysis ::= Rules

  syntax StateOp ::= "new?"
                   | "#new?" Rules
                   | "cut-point?"

  syntax Command ::= "extendRule"
                   | "abstract"
                   | "newRule"
                   | "restart"
                   | "compile-step"
                   | "compile"
endmodule

