// Instantiation of KAT
// ====================

// The KAT requires some programming-language specific information to work.
// Instantiation of the progamming language to KAT should happen with the language
// semantics on an as-needed basis.

// The module `IMP-KAT` includes all the supported analysis for the IMP language.


requires "imp.k"
requires "kat.k"

module IMP-ANALYSIS
  imports IMP-BIMC
  imports IMP-SBC
endmodule

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


// SBC
// ---


module IMP-SBC
  imports IMP-KAT
  imports KAT-SBC

  syntax State ::= "{" K "|" Map "|" Bool "}"

  rule <s> next-states [ { . | _ } ] => skip ... </s> [structural]
  rule <s> next-states [ { while ( BEXP:BExp ) BODY ~> REST | MEM } ]
        => push { while ( BEXP ) BODY ~> REST | MEM | true  }
         ; push { while ( BEXP ) BODY ~> REST | MEM | false }
         ...
       </s>
    [structural]

  rule <s> pop { while ( BEXP ) BODY ~> REST | MEM | BOOL } => pop { while ( BOOL ) BODY ~> REST | MEM } ... </s> [structural]


// ### Define `cut-point?`

// IMP will have a cut-point at the beginning of every `while` loop, allowing every
// execution of IMP to terminate.


  rule <s> cut-point? [ STATE ] => pop STATE ; can? (^ while) ... </s> [structural]


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

  rule <s> { while ( BEXP ) BODY ~> REST | MEM | BOOL } subsumes? [ STATE ] => { while ( BOOL ) BODY ~> REST | MEM } subsumes? [ STATE ] ... </s> [structural]
endmodule

