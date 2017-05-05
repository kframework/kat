// Instantiation of KAT
// ====================

// The KAT requires some programming-language specific information to work.
// Instantiation of the progamming language to KAT should happen with the language
// semantics on an as-needed basis.

// The module `IMP-KAT` includes all the supported analysis for the IMP language.


requires "imp.k"
requires "kat.k"

module IMP-KAT
  imports IMP
  imports KAT


// ### Define `push` and `pop`

// Here the definition of a `State` for IMP is given, as well as the definitions of
// how to `push` and `pop` states.


  syntax State ::= "{" K "|" Map "}"
//----------------------------------
  rule <s> push                => push { KCELL | MEM } ... </s> <imp> <k> KCELL      </k> <mem> MEM      </mem> </imp> [structural]
  rule <s> pop { KCELL | MEM } => .                    ... </s> <imp> <k> _ => KCELL </k> <mem> _ => MEM </mem> </imp> [structural]


// ### Define `#step`


  rule <s> #step => ^ lookup | ^ assignment | ^ while | ^ if ... </s> [structural]


// ### Define `bool?`


  rule <s> bool? [ { true  | _ } ] => #true  ... </s> [structural]
  rule <s> bool? [ { false | _ } ] => #false ... </s> [structural]


// ### Loading Strategy from File


  syntax Stmt ::= "strategy" ":" Strategy "=====" Stmt
//----------------------------------------------------
  rule <s> _ => STRATEGY </s> <k> strategy : STRATEGY ===== PGM => PGM </k>
endmodule


// BIMC
// ----

// Here we provide a way to make queries about the current IMP memory using IMP's
// `BExp` sort directly.

// -   `bexp?` is a predicate that allows us to make queries about the current
//     execution memory.


module IMP-BIMC
  imports IMP-KAT
  imports KAT-BIMC

  syntax StatePred ::= "bexp?" BExp
//---------------------------------
  rule <s> bexp? B [ { _ | MEM } ] => pop { B | MEM } ; eval ... </s> [structural]
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


  rule <s> cut-point? [ { while _ _ ... | MEM } ] => #true  ... </s> [structural]
  rule <s> cut-point? [ STATE                   ] => #false ... </s> [owise, structural]


// ### Define `abstract`

// IMP will abstract by turning all the values in memory into fresh symbolic
// values.


  syntax Strategy ::= "#abstract" Set State | "#abstractKey" Id Set State
//-----------------------------------------------------------------------
  rule <s> abstract [ { KCELL | MEM } ] => #abstract keys(MEM) { KCELL | MEM } ... </s> [structural]
  rule <s> #abstract .Set STATE         => pop STATE                           ... </s> [structural]

  rule <s> #abstract (SetItem(X) XS) STATE   => #abstractKey X XS STATE                   ... </s> [structural]
  rule <s> #abstractKey X XS { KCELL | MEM } => #abstract XS { KCELL | MEM[X <- ?V:Int] } ... </s> [structural]


// ### Define `_subsumes_`

// Because the memory is fully abstract every time subsumption is checked, it's
// enough to check that the `k` cell is identical for subsumption.


  rule <s> { KCELL | _ } subsumes? [ { KCELL  | _ } ] => #true  ... </s>                            [structural]
  rule <s> { KCELL | _ } subsumes? [ { KCELL' | _ } ] => #false ... </s> requires KCELL =/=K KCELL' [structural]
endmodule


// ### Example (Single Loop)

// Execute this test file with `krun --search sbc.imp`. Every solution will have
// it's own trace of generated rules.

// ### Exmaple (Collatz)

// ### Example (Memory Walk)
