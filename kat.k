// Strategy Language
// =================

// A simple imperative strategy language is supplied here. It has sequencing,
// choice, and looping (in addition to primitives related to controlling the
// execution state).


requires "imp.k"

module KAT
  imports IMP
  imports KCELLS

  configuration <strategy>
                  initSCell(Init)
                  initImpCell(Init)
                  <analysis> .Analysis </analysis>
                </strategy>

  syntax State    ::= "#current" | Cell | Bag
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
  rule <s> #false ~> not #pred => #true  ... </s>
  rule <s> #true  ~> not #pred => #false ... </s>

  rule <s> P or Q => P ; #pred or Q ... </s>
  rule <s> #true  ~> #pred or _ => #true ... </s>
  rule <s> #false ~> #pred or Q => Q     ... </s>

  rule <s> P and Q => P ; #pred and Q ... </s>
  rule <s> #true  ~> #pred and Q => Q      ... </s>
  rule <s> #false ~> #pred and _ => #false ... </s>


// Often you'll want a way to translate from the sort `Bool` in the programming
// language to the sort `Pred` in the strategy language.

// -   `bool?` checks if the `k` cell has just the constant `true`/`false` in it.


  syntax Pred ::= "bool?"

  rule <s> bool? => #true  ... </s> <k> true  </k>
  rule <s> bool? => #false ... </s> <k> false </k>


// The current K backend will place the token `#STUCK` at the front of the `s` cell
// when execution cannot continue. Here, a wrapper around this functionality is
// provided which will try to execute the given strategy and will roll back the
// state on failure.

// -   `try?_` executes a given strategy, placing `#true` on strategy cell if it
//     succeeds and `#false` otherwise.


  syntax Pred      ::= "try?" Strategy
  syntax Exception ::= "#try" State
//---------------------------------
  rule <s> try? S => S ~> #try STATE ... </s> <imp> STATE </imp> [structural]
  rule <s> #try STATE => #true       ... </s>                    [structural]

  rule <s> #STUCK ~> #try STATE => load STATE ; #false ... </s> [structural]
  rule <s> #STUCK ~> S:Strategy => #STUCK              ... </s> [structural]
  rule <s> SA:StrategyApplied => . ... </s> [structural]


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
                    > "skip"
                    | "(" Strategy ")"          [bracket]
                    | "?" Strategy ":" Strategy
                    > Strategy "*"
                    > Strategy ";" Strategy     [right]
                    > Strategy "|" Strategy     [right]
//-----------------------------------------------------
  rule <s> skip    => .             ... </s> [structural]
  rule <s> (S1 ; S2 => S1 ~> S2) ~> _   </s> [structural]

  rule <s> #true  ~> ? S : _ => S ... </s> [structural]
  rule <s> #false ~> ? _ : S => S ... </s> [structural]

  rule <s> S*     => (try? S) ; ? S* : skip ... </s> [structural]
  rule <s> S | S' => (try? S) ; ? skip : S' ... </s> [structural]


// Strategy Primitives
// -------------------

// Strategies can manipulate the `state` cell (where program execution happens) and
// the `analysis` cell (a memory/storage for the strategy language).

// -   `load_` places the given state into the execution harness.
// -   `analysis_` sets the `analysis` cell to the given argument.


  syntax Strategy ::= "load" State
//--------------------------------
  rule <s> load #current => skip ... </s>                    [structural]
  rule <s> load STATE    => skip ... </s> <imp> STATE </imp> [structural]

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
  rule <s> step  => step-with #step                          ... </s> [structural]
  rule <s> #step => ^ lookup | ^ assignment | ^ while | ^ if ... </s> [structural]


// Strategy Macros
// ---------------

// -   `can?_` tries to execute the given strategy, but restores the
//     state afterwards.
// -   `stuck?` checks if the current state can take a step.


  syntax Pred ::= "can?" Strategy
//-------------------------------
  rule <s> can? S => (try? S) ; ? load STATE ; #true : #false ... </s> <imp> STATE </imp> [structural]

  syntax Pred ::= "stuck?"
//------------------------
  rule <s> stuck? => not can? step ... </s> [structural]



  syntax priority if_then_else_ > _*
  syntax Strategy ::= "if" Pred "then" Strategy "else" Strategy
//-------------------------------------------------------------
  rule <s> if P then S1 else S2 => P ; ? S1 : S2 ... </s> [structural]


// -   `while__` allows looping behavior (controlled by sort `Pred`), and
//     `while___` implements a bounded version.
// -   `_until_` will execute the given strategy until a predicate holds, and
//     `_until__` implements a bounded version.


  syntax priority while__ while___ > _*
  syntax Strategy ::= "while" Pred Strategy | "while" Int Pred Strategy
//---------------------------------------------------------------------
  rule <s> while   P S => if P then S ; while            P S else skip ... </s>                   [structural]
  rule <s> while 0 P S => skip                                         ... </s>                   [structural]
  rule <s> while N P S => if P then S ; while (N -Int 1) P S else skip ... </s> requires N >Int 0 [structural]

  syntax priority _until_ _until__ > _*
  syntax Strategy ::= Strategy "until" Pred | Strategy "until" Int Pred
//---------------------------------------------------------------------
  rule <s> S until   P => while   (not P) S ... </s>                   [structural]
  rule <s> S until N P => while N (not P) S ... </s> requires N >Int 0 [structural]


// -   `exec_` executes the given state to completion, and `exec__` implements a
//     bounded version. Note that `krun == exec #current`.
// -   `eval_` executes a given state to completion and checks `bool?`, and
//     `eval__` implements a bounded version.


  syntax priority exec_ exec__ > _*
  syntax Strategy ::= "exec" State | "exec" Int State
//---------------------------------------------------
  rule <s> exec         STATE => load STATE ; step until   stuck? ... </s>
  rule <s> exec (N:Int) STATE => load STATE ; step until N stuck? ... </s>

  syntax priority eval_ eval__ > _*
  syntax Strategy ::= "eval" State | "eval" Int State
//---------------------------------------------------
  rule <s> eval         STATE => exec   STATE ; if bool? then load STATE' ; #true else load STATE' ; #false ... </s> <imp> STATE' </imp>
  rule <s> eval (N:Int) STATE => exec N STATE ; if bool? then load STATE' ; #true else load STATE' ; #false ... </s> <imp> STATE' </imp>
endmodule


// K Analysis Toolset (KAT)
// ========================

// KAT is a set of formal analysis tools which can be instantiated (as needed) to
// your programming language. Each tool has a well defined interface in terms of
// the predicates and operations you must provide over your languages state.

// Bounded Invariant Model Checking
// --------------------------------

// In bounded invariant model checking, the analysis being performed is a trace of
// the execution states that we have seen.


module KAT-BIMC
  imports KAT

  syntax Trace ::= ".Trace"
                 | Trace ";" State

  syntax Analysis ::= Trace


// -   `record` copies the current execution state to the end of the trace.


  syntax Strategy ::= "record"
//----------------------------
  rule <s> record => skip ... </s> <imp> STATE </imp>
                                   <analysis> T => T ; STATE </analysis>


// Performing bounded invariant model checking is a simple predicate in our
// strategy language.

// -   `bimc` checks that the predicate holds for each step up to a
//     search-depth bound.


  syntax Pred ::= "bimc" Int Pred
//-------------------------------
  rule <s> ( bimc N P
           => analysis .Trace
            ; record
            ; (step ; record) until N (not P)
            ; P
           )
           ...
       </s>
endmodule


// ### Future Work

// -   This should extended to model checking more than invariants by defining the
//     appropriate derivatives of your favorite temporal logic's formula.
// -   We should be able to use arbitrary matching-logic patterns as sort `Pred`.

// Semantics Based Compilation
// ---------------------------

// Semantics based compilation uses symbolic execution to reduce the size of
// transition system defined by programming language semantics. As the program is
// executed symbolically, the execution state is periodically "abstracted" with a
// language-specific abstraction operator. The abstraction operator must be
// powerful enough to guarantee termination of every program in the language.
// However, if the abstraction is too strong, the transition system will not be
// reduced in size very much, yielding worse compilation results.

// As we execute, we'll collect new the states we've seen so far as a new `Rule` of
// the smaller transition system. Anytime we reach a state which is subsumed by the
// left-hand-side of one of our generated rules, we'll stop exploring that path.

// I've subsorted `Rules` into `Analysis`, and defined `Rules` as a cons-list of
// `Rule`.


module KAT-SBC
  imports KAT

  syntax Rule ::= "<" State ">"
                | "<" State "-->" State ">"

  syntax Rules ::= ".Rules"
                 | Rules "," Rule

  syntax Analysis ::= Rules


// The interface of this analysis requires you define when to abstract and how to
// abstract.

// -   `cut-point?` is a predicate that should hold when abstraction should occur.
// -   `abstract` is an operator than should abstract away enough details of the
//     state to guarantee termination. Note that `abstract` needs to also take care
//     not to destroy all information collected about the state in this execution.


  syntax Pred ::= "cut-point?"
//----------------------------

  syntax Strategy ::= "abstract"
//------------------------------


// -   `subsumed?` is a predicate that checks if any of the left-hand sides of the
//     rules `_subsumes_` the current state. Note that below we provide the
//     instantiation of `_subsumes_` to IMP manually, but in principle this
//     should inferred.


  syntax Pred ::= "subsumed?" | State "subsumes" State
//----------------------------------------------------
  rule <s> subsumed? => #subsumed? RS ... </s> <analysis> RS </analysis>

  syntax Pred ::= "#subsumed?" Rules
//----------------------------------
  rule <s> #subsumed? .Rules => #false                                              ... </s>
  rule <s> #subsumed? (RS , < LHS --> _ >) => (LHS subsumes STATE) or #subsumed? RS ... </s> <imp> STATE </imp>


// At cut-points, we'll finish the rule we've been building, abstract the state,
// start a building a new rule from that state.

// -   `begin-rule` will use the current state as the left-hand-side of a new rule
//     in the record of rules.
// -   `end-rule` uses the current state as the right-hand-side of a new rule in
//     the record of rules.


  syntax Strategy ::= "begin-rule"
//--------------------------------
  rule <s> begin-rule => skip ... </s> <analysis> RS => RS , < STATE > </analysis>
                                       <imp> STATE </imp>

  syntax Strategy ::= "end-rule"
//------------------------------
  rule <s> end-rule => skip ... </s> <analysis> RS , (< LHS > => < LHS --> STATE >) </analysis>
                                     <imp> STATE </imp>


// Finally, semantics based compilation is provided as a macro.

// -   `compile` will execute a program using the given `cut-point?` and `abstract`
//     operators until it has collected a complete set of rules.


  syntax Strategy ::= "compile"
//-----------------------------
  rule <s> ( compile
          => analysis .Rules
           ; abstract
           ; begin-rule
           ; while (not (stuck? or subsumed?))
               ( step until (stuck? or cut-point?)
               ; end-rule
               ; abstract
               ; begin-rule
               )
           ; end-rule
           )
           ...
       </s>
       <analysis> _ => .Rules </analysis>
endmodule


// ### Future Work {#future-work-1}

// -   Post-process the results of the compilation with another abstraction pass
//     which just hashes the contents of the `k` cell for each rule. This will
//     reduce the amount of extra matching that happens in executing the
//     compiled definition.
// -   Use matching-logic implication to implement `_subsumes_` in a
//     language-indepedent way.
