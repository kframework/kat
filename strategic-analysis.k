// Strategies
// ==========

// Two modules are interleaved below. If K's configurations were more composable,
// they could easily be one module defining the `symbolicExecution` machine.

// The strategy language controls a small stack machine, which in turns controls
// the execution of the program via the sort `Prim` (for "primitive"). This stack
// machine has a stack of program symbolic states, which it can do normal
// stack-machine like things with. The sort of each type of command tells you where
// the arguments of the command will be sourced from (this will happen
// automatically for you). You must provide the reduction of your command to its
// output when it is at the top of the `strategy` cell.

// Stack Machine Syntax
// --------------------

// The syntax of the stack machine primitives are given. The `Strategy` for `step`
// must be provided by the language definition (see for IMP below).


module STRATEGIES

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


// For an `UnStackOp`, you can just put it at the top of `strategy`, and the top
// element of the stack will be loaded for you. For `BinStackOp`, it will load the
// top two elements for you. If you have a `StateOp`, it will also automatically
// load a copy of the current state for you.

// Primitive Operators
// -------------------

// `load` is the "pop" for the stack machine, and `store` is the "push".


  syntax UnStackOp ::= "load"
  syntax StateOp ::= "store"
  syntax Strategy ::= "skip"
                    | Strategy ";" Strategy [assoc]


// -   `load` places the state at the top of the stack into the execution harness
// -   `store` copies the state in the execution harness onto the stack

// -   `skip` will be automatically simplified out of the `Strategy`.

// Predicates
// ----------


  syntax AtomicPred ::= "bool?" | "finished?"

  syntax Pred ::= AtomicPred | AtomicPred State
                | "#true" | "#false" | "#pred"
                | "not" Pred | Pred "or" Pred | Pred "and" Pred

  syntax Strategy ::= Pred


// Atomic predicates automatically load a copy of the current execution state. When
// you declare an `AtomicPred`, make sure to provide the reduction rule to `#true`
// or `#false` on the `strategy` cell.

// -   `bool?` checks if the `k` cell has just the constant `true`/`false` in it
// -   `finished?` checks if the `k` cell is empty (ie. execution of that machine
//     has terminated)

// The boolean operators `not`, `and`, and `or` use helpers to evaluate their
// arguments from left-to-right lazily ("short-circuit").

// Strategy Language
// -----------------

// The basic strategy language consists of operators, predicates, and choice.


  syntax Strategy ::= Op | Pred | "?" Strategy ":" Strategy

endmodule


// The top element of the `strategy` cell determines the semantics of choice.
