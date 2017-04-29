// Strategy Language
// =================

// A simple imperative strategy language is supplied here. It has sequencing,
// choice, and looping (in addition to primitives related to controlling the
// execution state).


module STRATEGY-HARNESS
  imports STRATEGY
  imports KCELLS

  configuration <strategy>
                  <state> .State </state>
                  <analysis> .Analysis </analysis>
                </strategy>

  syntax State    ::= ".State" | "#current" | Bag
  syntax Analysis ::= ".Analysis"


// Strategy Predicates
// -------------------

// The strategy language has its own sort `Pred` for predicates, separate from the
// `Bool` usually used by programming languages. Lazy semantics ("short-circuit")
// are given via controlled heating and cooling.


  syntax Pred ::= "#true" | "#false" | "#pred" | "(" Pred ")" [bracket]
                | "not" Pred | Pred "or" Pred | Pred "and" Pred
//-------------------------------------------------------------
  rule <s> (not P => P ; not #pred) ; _ </s>
  rule <s> (#false ; not #pred => #true)  ; _ </s>
  rule <s> (#true  ; not #pred => #false) ; _ </s>

  rule <s> (P or Q => P ; #pred or Q) ; _ </s>
  rule <s> (#true  ; #pred or _ => #true) ; _ </s>
  rule <s> (#false ; #pred or Q => Q)     ; _ </s>

  rule <s> (P and Q ; S => P ; #pred and Q) ; _ </s>
  rule <s> (#true  ; #pred and Q ; S => Q)      ; _ </s>
  rule <s> (#false ; #pred and _ ; S => #false) ; _ </s>



  syntax Pred ::= "bool?"


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
  rule skip ; S => S [structural]

  rule <s> (#true  ; ? S : _ => S) ; _ </s>
  rule <s> (#false ; ? _ : S => S) ; _ </s>

  rule <s> (S*     => try S ; ? S* : skip) ; _ </s>
  rule <s> (S | S' => try S ; ? skip : S') ; _ </s>


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
  rule <s> (try S => S ; #try STATE) ; _ </s> <state> STATE </state>
  rule <s> (#try STATE => #true)     ; _ </s>

  rule <s> #STUCK ~> SA:StrategyApply ; #try STATE ; S => load STATE ; #false ; S </s>
  rule <s> SA:StrategyApplied ~> S => S </s>


// Strategies can manipulate the `state` cell (where program execution happens) and
// the `analysis` cell (a memory/storage for the strategy language).

// -   `load_` places the given state into the execution harness.
// -   `analysis_` sets the `analysis` cell to the given argument.


  syntax Strategy ::= "load" State
//--------------------------------
  rule <s> (load #current => skip) ; _ </s>
  rule <s> (load STATE    => skip) ; _ </s> <state> _ => STATE </state> requires STATE =/=K #current

  syntax Strategy ::= "analysis" Analysis
//---------------------------------------
  rule <s> (analysis A => skip) ; _ </s> <analysis> _ => A </analysis>


// -   `step-with_` is used to specify that a given strategy should be executed
//     admist heating and cooling.
// -   `#step` should be defined for each programming language, specifying which
//     transitions are proper steps.
// -   `step` is `step-with_` instantiated to `#step`.


  syntax Strategy ::= "step-with" Strategy
//----------------------------------------
  rule <s> (step-with S => (^ heat | ^ regular)* ; S ; (^ cool)*) ; _ </s>

  syntax Strategy ::= "step" | "#step"
//------------------------------------
  rule <s> (step => step-with #step) ; _ </s>


// Strategy Macros
// ---------------

// -   `can?_` tries to execute the given strategy, but restores the
//     state afterwards.
// -   `stuck?` checks if the current state can take a step.


  syntax Pred ::= "can?" Strategy
//-------------------------------
  rule <s> (can? S => try S ; ? load STATE ; #true : #false) ; _ </s> <state> STATE </state>

  syntax Pred ::= "stuck?"
//------------------------
  rule <s> (stuck? => not can? step) ; _ </s>


// -   `while__` allows looping behavior (controlled by sort `Pred`), and
//     `while___` implements a bounded version.
// -   `step-until_` will execute until a predicate holds, and `step-until__`
//     implements a bounded version.


  syntax priority while__ while___ > _*
  syntax Strategy ::= "while" Pred Strategy | "while" Int Pred Strategy
//---------------------------------------------------------------------
  rule <s> (while P S => P ; (? S ; while P S : skip)) ; _ </s>

  rule <s> (while 0 P S => skip) ; _ </s>
  rule <s> (while N P S => P ; (? S ; while (N -Int 1) P S : skip)) ; _ </s> requires N >Int 0

  syntax priority step-until_ step-until__ > _*
  syntax Strategy ::= "step-until" Pred | "step-until" Int Pred
//-------------------------------------------------------------
  rule <s> (step-until   P => while   (not P) step) ; _ </s>
  rule <s> (step-until N P => while N (not P) step) ; _ </s> requires N >Int 0


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
  rule <s> (eval         STATE => exec   STATE ; bool? ; load STATE') ; _ </s> <state> STATE' </state>
  rule <s> (eval (N:Int) STATE => exec N STATE ; bool? ; load STATE') ; _ </s> <state> STATE' </state>
endmodule

