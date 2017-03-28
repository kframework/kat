// Strategies
// ==========

// Two modules are interleaved below. If K's configurations were more composable,
// they could easily be one module defining the `symbolicExecution` machine.

// Execution Machine Syntax
// ------------------------

// The `Strategy` for `step` must be provided by the language definition (see for
// IMP below).


module STRATEGIES
  imports KCELLS

  syntax State ::= Bag
  syntax Stack ::= ".Stack"
                 | State ":" Stack

  syntax Analysis ::= ".Analysis"

  syntax Pred

  syntax Strategy ::= Pred
                    | "step"
                    | "skip" | "load" State
                    | Strategy ";" Strategy [assoc]
                    | "?" Strategy ":" Strategy


// -   `skip` will be automatically simplified out of the `Strategy` (unless it's
//     at the end)
// -   `load` places the given state into the execution harness
// -   `?_:_` (choice) uses the top of the strategy cell to determine what to
//     execute next

// Predicates
// ----------


  syntax Pred ::= "#true" | "#false" | "#pred"
                | "not" Pred | Pred "or" Pred | Pred "and" Pred

  syntax Pred ::= "bool?" | "finished?"

endmodule


// When you declare a `Pred`, make sure to provide the reduction rule to `#true` or
// `#false` on the `strategy` cell.

// -   `bool?` checks if the `k` cell has just the constant `true`/`false` in it
// -   `finished?` checks if the `k` cell is empty (ie. execution of that machine
//     has terminated)

// The boolean operators `not`, `and`, and `or` use helpers to evaluate their
// arguments from left-to-right lazily ("short-circuit").
