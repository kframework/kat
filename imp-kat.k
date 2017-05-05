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

  syntax State ::= "{" K "|" Map "}"

  rule <s> #step => ^ lookup | ^ assignment | ^ while | ^ if ... </s> [structural]
  rule <s> push => push { KCELL | MEM } ... </s>
       <imp> <k> KCELL </k> <mem> MEM </mem> </imp>
    [structural]
  rule <s> pop { KCELL | MEM } => . ... </s>
       <imp> <k> _ => KCELL </k> <mem> _ => MEM </mem> </imp>
    [structural]
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

  syntax Pred ::= "bexp?" BExp | "#bexp?" BExp
//--------------------------------------------
  rule <s> bexp? B => push ; #bexp? B ... </s> [structural]
  rule <s> #bexp? B => eval ... </s>
       <states> { _ => B | MEM } : STATES </states>
    [structural]
endmodule


// ### Example (Invariant Failure)

// Here we check the property `x <= 7` for 5 steps of execution after the code has
// initialized (the `step` in front of the command). Run this with
// `krun --search bimc.imp`.

// ### Example (Bound Reached)

// ### Example (Execution Terminates)

// SBC
// ---


module IMP-SBC
  imports IMP
  imports KAT-SBC


// ### Define `cut-point?`

// IMP will have a cut-point at the beginning of every `while` loop, allowing every
// execution of IMP to terminate.


  rule <s> cut-point? => #true  ... </s> <k> while _ _ ... </k> [structural]
  rule <s> cut-point? => #false ... </s>                        [owise, structural]


// ### Define `abstract`

// IMP will abstract by turning all the values in memory into fresh symbolic
// values.


  rule <s> abstract => #abstract keys(MEM) ... </s> <mem> MEM </mem> [structural]

  syntax Strategy ::= "#abstract" Set | "#abstractKey" Id
//-------------------------------------------------------
  rule <s> #abstract .Set            => skip                             ... </s>   [structural]
  rule <s> #abstract (SetItem(X) XS) => #abstractKey X ; #abstract XS    ... </s>   [structural]
  rule <s> #abstractKey X => skip ... </s> <mem> ... X |-> (_ => ?V:Int) ... </mem> [structural]


// ### Define `_subsumes_`

// Because the memory is fully abstract every time subsumption is checked, it's
// enough to check that the `k` cell is identical for subsumption.


  rule <s> { KCELL | _ } subsumes { KCELL  | _ } => #true  ... </s>                            [structural]
  rule <s> { KCELL | _ } subsumes { KCELL' | _ } => #false ... </s> requires KCELL =/=K KCELL' [structural]
endmodule


// ### Example (Single Loop)

// Execute this test file with `krun --search sbc.imp`. Every solution will have
// it's own trace of generated rules.

// ### Exmaple (Collatz)

// ### Example (Memory Walk)
