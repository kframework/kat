// Strategy Language
// =================

// A simple imperative strategy language is supplied here. It has sequencing,
// choice, and looping (in addition to primitives related to controlling the
// execution state).


requires "imp.k"

module STRATEGY-IMP
  imports IMP
  imports KCELLS

  syntax State    ::= "#current" | Cell
  syntax Analysis ::= ".Analysis"


// Strategy Predicates
// -------------------

// The strategy language has its own sort `Pred` for predicates, separate from the
// `Bool` usually used by programming languages. Lazy semantics ("short-circuit")
// are given via controlled heating and cooling.


  syntax Pred ::= "#true" | "#false" | "#pred" | "(" Pred ")" [bracket]
                | "not" Pred | Pred "or" Pred | Pred "and" Pred
//-------------------------------------------------------------
  rule <s> not P => P ; not #pred ... </s>
  rule <s> #false ; not #pred => #true  ... </s>
  rule <s> #true  ; not #pred => #false ... </s>

  rule <s> P or Q => P ; #pred or Q ... </s>
  rule <s> #true  ; #pred or _ => #true ... </s>
  rule <s> #false ; #pred or Q => Q     ... </s>

  rule <s> P and Q ; S => P ; #pred and Q ... </s>
  rule <s> #true  ; #pred and Q ; S => Q      ... </s>
  rule <s> #false ; #pred and _ ; S => #false ... </s>


// Often you'll want a way to translate from the sort `Bool` in the programming
// language to the sort `Pred` in the strategy language.

// -   `bool?` checks if the `k` cell has just the constant `true`/`false` in it.


  syntax Pred ::= "bool?"

  rule <s> bool? => #true  ... </s> <imp> <k> true  </k> ... </imp>
  rule <s> bool? => #false ... </s> <imp> <k> false </k> ... </imp>


// Strategy Statements
// -------------------

// The strategy language is a simple imperative language with sequencing and
// choice.

// -   `skip` acts as a no-op strategy.
// -   `{_}` and `(_)` are syntactically used to make blocks in the
//     strategy language.
// -   `_;_` is used to sequentially compose strategies.
// -   `?_:_` (choice) uses the `Pred` value at the top of the strategy cell to
//     determine what to execute next.
// -   `_*` executes the given strategy until it cannot be executed anymore
//     ("greedy Kleene star").
// -   `_|_` tries executing the first strategy, and on failure executes
//     the second.


  syntax Strategy ::= Pred
                    | "skip"
                    | "{" Strategy "}"          [bracket]
                    | "(" Strategy ")"          [bracket]
                    | "?" Strategy ":" Strategy
                    > Strategy "*"
                    > Strategy ";" Strategy     [right]
                    > Strategy "|" Strategy     [right]
//-----------------------------------------------------
  rule <s> skip ; S                 => S ...          </s> [structural]
  rule <s> ( SA:StrategyApply ) ; S => SA ; S         </s> [structural]
  rule <s> (S1 ; S2) ; S3           => S1 ; (S2 ; S3) </s> [structural]

  rule <s> #true  ; ? S : _ => S ... </s> [structural]
  rule <s> #false ; ? _ : S => S ... </s> [structural]

  rule <s> S*     => try S ; ? S* : skip ... </s> [structural]
  rule <s> S | S' => try S ; ? skip : S' ... </s> [structural]


// Strategy Primitives
// -------------------

// The current K backend will place the token `#STUCK` at the front of the `s` cell
// when execution cannot continue. Here, a wrapper around this functionality is
// provided which will try to execute the given strategy and will roll back the
// state on failure.

// -   `try_` executes a given strategy, placing `#true` on strategy cell if it
//     succeeds and `#false` otherwise.


  syntax priority try_ > _*
  syntax Strategy ::= "try" Strategy | "#try" State
//-------------------------------------------------
  rule <s> try S => S ; #try STATE ... </s> <imp> STATE </imp> [structural]
  rule <s> #try STATE => #true     ... </s>                    [structural]

  rule <s> ^ RT ; S => ^ RT ~> S ... </s>                                                   [structural]
  rule <s> #STUCK ~> SA:StrategyApply ~> (#try STATE ; S) => (load STATE ; #false ; S) </s> [structural]
  rule <s> SA:StrategyApplied => . ... </s>                                                 [structural]


// Strategies can manipulate the `state` cell (where program execution happens) and
// the `analysis` cell (a memory/storage for the strategy language).

// -   `load_` places the given state into the execution harness.
// -   `analysis_` sets the `analysis` cell to the given argument.


  syntax Strategy ::= "load" State
//--------------------------------
  rule <s> load #current => skip ... </s>                         [structural]
  rule <s> load STATE    => skip ... </s> <imp> _ => STATE </imp> [structural]

  syntax Strategy ::= "analysis" Analysis
//---------------------------------------
  rule <s> analysis A => skip ... </s> <analysis> _ => A </analysis> [structural]


// -   `step-with_` is used to specify that a given strategy should be executed
//     admist heating and cooling.
// -   `#step` should be defined for each programming language, specifying which
//     transitions are proper steps.
// -   `step` is `step-with_` instantiated to `#step`.


  syntax Strategy ::= "step-with" Strategy
//----------------------------------------
  rule <s> step-with S => (^ heat | ^ regular)* ; S ; (^ cool)* ... </s> [structural]

  syntax Strategy ::= "step" | "#step"
//------------------------------------
  rule <s> step => step-with #step ... </s>                           [structural]
  rule <s> #step => ^ lookup | ^ assignment | ^ while | ^ if ... </s> [structural]


// Strategy Macros
// ---------------

// -   `can?_` tries to execute the given strategy, but restores the
//     state afterwards.
// -   `stuck?` checks if the current state can take a step.


  syntax Pred ::= "can?" Strategy
//-------------------------------
  rule <s> (can? S => try S ; ? load STATE ; #true : #false) ; _ </s> <imp> STATE </imp> [structural]

  syntax Pred ::= "stuck?"
//------------------------
  rule <s> (stuck? => not can? step) ; _ </s> [structural]


// -   `while__` allows looping behavior (controlled by sort `Pred`), and
//     `while___` implements a bounded version.
// -   `step-until_` will execute until a predicate holds, and `step-until__`
//     implements a bounded version.


  syntax priority while__ while___ > _*
  syntax Strategy ::= "while" Pred Strategy | "while" Int Pred Strategy
//---------------------------------------------------------------------
  rule <s> (while   P S => P ; (? S ; while P S : skip)) ; _ </s> [structural]
  rule <s> (while 0 P S => skip) ; _ </s> [structural]
  rule <s> (while N P S => P ; (? S ; while (N -Int 1) P S : skip)) ; _ </s> requires N >Int 0 [structural]

  syntax priority step-until_ step-until__ > _*
  syntax Strategy ::= "step-until" Pred | "step-until" Int Pred
//-------------------------------------------------------------
  rule <s> (step-until   P => while   (not P) step) ; _ </s>                   [structural]
  rule <s> (step-until N P => while N (not P) step) ; _ </s> requires N >Int 0 [structural]


// -   `exec_` executes the given state to completion, and `exec__` implements a
//     bounded version. Note that `krun == exec #current`.
// -   `eval_` executes a given state to completion and checks `bool?`, and
//     `eval__` implements a bounded version.


  syntax priority exec_ exec__ > _*
  syntax Strategy ::= "exec" State | "exec" Int State
//---------------------------------------------------
  rule <s> (exec         STATE => load STATE ; step-until   stuck?) ; _ </s>
  rule <s> (exec (N:Int) STATE => load STATE ; step-until N stuck?) ; _ </s>

  syntax priority eval_ eval__ > _*
  syntax Strategy ::= "eval" State | "eval" Int State
//---------------------------------------------------
  rule <s> (eval         STATE => exec   STATE ; bool? ; ? { load STATE' ; #true } : { load STATE' ; #false }) ; _ </s> <imp> STATE' </imp>
  rule <s> (eval (N:Int) STATE => exec N STATE ; bool? ; ? { load STATE' ; #true } : { load STATE' ; #false }) ; _ </s> <imp> STATE' </imp>
endmodule

