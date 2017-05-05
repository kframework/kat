// Instantiation of KAT
// ====================

// The KAT requires some programming-language specific information to work.
// Instantiation of the progamming language to KAT should happen with the language
// semantics on an as-needed basis.

// The module `IMP-KAT` includes all the supported analysis for the IMP language.


requires "imp.k"
requires "kat.k"

module IMP-KAT
  imports IMP-BIMC
  imports IMP-SBC
endmodule


// BIMC
// ----

// Here we provide a way to make queries about the current IMP memory using IMP's
// `BExp` sort directly.

// -   `bexp?` is a predicate that allows us to make queries about the current
//     execution memory.


module IMP-BIMC
  imports IMP
  imports KAT-BIMC

  syntax Pred ::= "bexp?" BExp
//----------------------------
  rule <s> bexp? B => eval (<k> B </k> <mem> MEM </mem>) ... </s> <mem> MEM </mem>
endmodule


// ### Example (Invariant Failure)

// Here we check the property `x <= 7` for 5 steps of execution after the code has
// initialized (the `step` in front of the command). Run this with
// `krun --search bimc.imp`. Every solution should be checked for
// `assertion-failure_` or `assertion-success`.

// ### Example (Bound Reached)

// ### Example (Execution Terminates)

// SBC
// ---


module IMP-SBC
  imports IMP
  imports KAT-SBC

// Define `cut-point?`
//--------------------
  rule <s> cut-point? => #true  ... </s> <k> while _ _ ... </k>
  rule <s> cut-point? => #false ... </s> [owise]

// Define `abstract`
//------------------
  rule <s> abstract => #abstract keys(MEM) ... </s> <mem> MEM </mem>

  syntax Strategy ::= "#abstract" Set | "#abstractKey" Id
//-------------------------------------------------------
  rule <s> #abstract .Set            => skip                          ... </s>
  rule <s> #abstract (SetItem(X) XS) => #abstractKey X ; #abstract XS ... </s>
  rule <s> #abstractKey X => skip ... </s> <mem> ... X |-> (_ => ?V:Int) ... </mem>

// Define `_subsumes_`
//--------------------
  rule <s> (<k> KCELL </k> <mem> _ </mem>) subsumes (<k> KCELL  </k> <mem> _ </mem>) => #true  ... </s>
  rule <s> (<k> KCELL </k> <mem> _ </mem>) subsumes (<k> KCELL' </k> <mem> _ </mem>) => #false ... </s> requires KCELL =/=K KCELL'
endmodule


// ### Example (Single Loop)

// Execute this test file with `krun --search sbc.imp`. Every solution will have
// it's own trace of generated rules.

// ### Exmaple (Collatz)

// ### Example (Memory Walk)
