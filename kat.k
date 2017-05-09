// Strategy Language
// =================

// A simple imperative strategy language is supplied here. It has sequencing,
// choice, and looping (in addition to primitives related to controlling the
// execution state).


module KAT
  imports KCELLS
  imports STRATEGY

  configuration <kat>
                  <analysis> .Analysis </analysis>
                  <states> .States </states>
                </kat>

  syntax State    ::= "#current"
  syntax States   ::= ".States"
                    | State ":" States
  syntax Analysis ::= ".Analysis"


// Strategy Predicates
// -------------------

// The strategy language has its own sort `Pred` for predicates, separate from the
// `Bool` usually used by programming languages. Lazy semantics ("short-circuit")
// are given via controlled heating and cooling.


  syntax PredAtom ::= "#true" | "#false"
  syntax Pred     ::= PredAtom | "#pred" | "(" Pred ")" [bracket]
                    | "not" Pred | Pred "or" Pred | Pred "and" Pred
//-----------------------------------------------------------------
  rule <s> not P               => P ; not #pred ... </s>
  rule <s> #false ~> not #pred => #true         ... </s>
  rule <s> #true  ~> not #pred => #false        ... </s>

  rule <s> P or Q               => P ; #pred or Q ... </s>
  rule <s> #true  ~> #pred or _ => #true          ... </s>
  rule <s> #false ~> #pred or Q => Q              ... </s>

  rule <s> P and Q               => P ; #pred and Q ... </s>
  rule <s> #true  ~> #pred and Q => Q               ... </s>
  rule <s> #false ~> #pred and _ => #false          ... </s>


// State predicates are evaluated over the current execution state. If you declare
// something a `StatePred`, this code will automatically load the current state for
// you (making the definition of them easier).


  syntax StatePred
  syntax Pred ::= StatePred | StatePred "[" State "]"
//---------------------------------------------------
  rule <s> SP:StatePred              => push ; SP [ #current ] ... </s>
  rule <s> SP:StatePred [ #current ] => SP [ STATE ]           ... </s> <states> STATE : STATES => STATES </states>


// -   `#pred_` is useful for propagating the result of a predicate through
//     another strategy.


  syntax Strategy ::= "#pred" Strategy
//------------------------------------
  rule <s> PA:PredAtom ~> #pred S => S ; PA ... </s>


// Often you'll want a way to translate from the sort `Bool` in the programming
// language to the sort `Pred` in the strategy language.

// -   `bool?` checks if the `k` cell has just the constant `true`/`false` in it
//     and must be defined for each programming language.


  syntax StatePred ::= "bool?"
//----------------------------


// The current K backend will place the token `#STUCK` at the front of the `s` cell
// when execution cannot continue. Here, a wrapper around this functionality is
// provided which will try to execute the given strategy and will roll back the
// state on failure.

// -   `try?_` executes a given strategy, placing `#true` on strategy cell if it
//     succeeds and `#false` otherwise.


  syntax Pred      ::= "try?" Strategy
  syntax Exception ::= "#try"
//---------------------------
  rule <s> try? S => push ; S ~> #try     ... </s>
  rule <s> #try   => drop ; #true         ... </s>
  rule <s> #STUCK ~> (S:Strategy => .)    ... </s>
  rule <s> #STUCK ~> #try => pop ; #false ... </s>
  rule <s> SA:StrategyApplied => .        ... </s>


// -   `stack-empty?` is a predicate that checks whether the stack of states is
//     empty or not.


  syntax Pred ::= "stack-empty?"
//------------------------------
  rule <s> stack-empty? => #true  ... </s> <states> .States        </states>
  rule <s> stack-empty? => #false ... </s> <states> STATE : STATES </states>


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
  rule <s> skip    => .        ... </s>
  rule <s> S1 ; S2 => S1 ~> S2 ... </s>

  rule <s> #true  ~> ? S : _ => S ... </s>
  rule <s> #false ~> ? _ : S => S ... </s>

  rule <s> S*     => (try? S) ; ? S* : skip ... </s>
  rule <s> S | S' => (try? S) ; ? skip : S' ... </s>


// Strategy Primitives
// -------------------

// Strategies can manipulate the `state` cell (where program execution happens) and
// the `analysis` cell (a memory/storage for the strategy language).

// -   `push_` copies the current execution state onto the stack of states and must
//     be provided by the programming language.
// -   `pop_` places the given state in the execution harness and must be provided
//     by the programming language.
// -   `stack_` sets the `states` cell to the given state stack.
// -   `swap` swaps the top two elements of the state stack.
// -   `dup` duplicates the top element of the state stack.
// -   `drop` removes the top element of the state stack (without placing it in the
//     execution harness).


  syntax Strategy ::= "push" | "push" State
//-----------------------------------------
  rule <s> push STATE => . ... </s> <states> STATES => STATE : STATES </states>

  syntax Strategy ::= "pop" | "pop" State
//---------------------------------------
  rule <s> pop #current => .         ... </s>
  rule <s> pop          => pop STATE ... </s> <states> STATE : STATES => STATES </states>

  syntax Strategy ::= "stack" States
//----------------------------------
  rule <s> stack STATES => . ... </s> <states> _ => STATES </states>

  syntax Strategy ::= "swap" | "dup" | "drop"
//-------------------------------------------
  rule <s> swap => . ... </s> <states> S1 : S2 : STATES => S2 : S1 : STATES       </states>
  rule <s> dup  => . ... </s> <states> STATE : STATES   => STATE : STATE : STATES </states>
  rule <s> drop => . ... </s> <states> STATE : STATES   => STATES                 </states>


// -   `analysis_` sets the `analysis` cell to the given argument.


  syntax Strategy ::= "analysis" Analysis
//---------------------------------------
  rule <s> analysis A => . ... </s> <analysis> _ => A </analysis>


// -   `step-with_` is used to specify that a given strategy should be executed
//     admist heating and cooling.
// -   `#transition` defines what is a proper transition and must be provided by
//     the programming language.
// -   `#normal` defines a normal transition in the programming language (not a
//     step for analysis).
// -   `step` is `step-with_` instantiated to `#normal | #transition`.


  syntax priority step-with_ > _*
  syntax Strategy ::= "step-with" Strategy | "#transition" | "#normal" | "step"
//-----------------------------------------------------------------------------
  rule <s> step-with S => (^ regular | ^ heat)* ; S ; (^ regular | ^ cool)* ... </s>
  rule <s> step        => step-with (#normal | #transition)                 ... </s>


// Things added to the sort `StateOp` will automatically load the current state for
// you, making it easier to define operations over the current state.


  syntax StateOp
  syntax Strategy ::= StateOp | StateOp "[" State "]"
//---------------------------------------------------
  rule <s> SO:StateOp              => push ; SO [ #current ] ... </s>
  rule <s> SO:StateOp [ #current ] => SO [ STATE ]           ... </s> <states> STATE : STATES => STATES </states>


// Strategy Macros
// ---------------

// -   `can?_` tries to execute the given strategy, but restores the
//     state afterwards.
// -   `stuck?` checks if the current state can take a step.


  syntax Pred ::= "can?" Strategy
//-------------------------------
  rule <s> can? S => push ; (try? S) ; #pred pop ... </s>

  syntax Pred ::= "stuck?"
//------------------------
  rule <s> stuck? => not can? step ... </s>


// -   `if_then_else_` provides a familiar wrapper around the more primitive
//     `?_:_` functionality.


  syntax priority if_then_else_ > _*
  syntax Strategy ::= "if" Pred "then" Strategy "else" Strategy
//-------------------------------------------------------------
  rule <s> if P then S1 else S2 => P ; ? S1 : S2 ... </s>


// -   `while__` allows looping behavior (controlled by sort `Pred`), and
//     `while___` implements a bounded version.
// -   `_until_` will execute the given strategy until a predicate holds, and
//     `_until__` implements a bounded version.


  syntax priority while__ while___ > _*
  syntax Strategy ::= "while" Pred Strategy | "while" Int Pred Strategy
//---------------------------------------------------------------------
  rule <s> while   P S => P ; ? S ; while P S : skip            ... </s>
  rule <s> while 0 P S => .                                     ... </s>
  rule <s> while N P S => P ; ? S ; while (N -Int 1) P S : skip ... </s> requires N >Int 0

  syntax priority _until_ _until__ > _*
  syntax Strategy ::= Strategy "until" Pred | Strategy "until" Int Pred
//---------------------------------------------------------------------
  rule <s> S until   P => while   (not P) S ... </s>
  rule <s> S until N P => while N (not P) S ... </s>


// -   `exec` executes the given state to completion, and `exec_` implements a
//     bounded version. Note that `krun === exec`.
// -   `eval` executes a given state to completion and checks `bool?`, and `eval_`
//     implements a bounded version.


  syntax priority exec_ > _*
  syntax Strategy ::= "exec" | "exec" Int
//---------------------------------------
  rule <s> exec         => step until   stuck? ... </s>
  rule <s> exec (N:Int) => step until N stuck? ... </s>

  syntax priority eval_ > _*
  syntax StatePred ::= "eval" | "eval" Int
//----------------------------------------
  rule <s> eval   [ STATE ] => pop STATE ; exec   ; bool? ... </s> requires STATE =/=K #current
  rule <s> eval N [ STATE ] => pop STATE ; exec N ; bool? ... </s> requires STATE =/=K #current
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

  syntax Trace    ::= ".Trace"
                    | Trace ";" State

  syntax Analysis ::= Trace


// -   `#length_` calculates the length of a trace.


  syntax Strategy ::= "#length" Trace | "#length" Int Trace | "#length" Int
//-------------------------------------------------------------------------
  rule <s> #length T         => #length 0 T          ... </s>
  rule <s> #length N .Trace  => #length N            ... </s>
  rule <s> #length N (T ; _) => #length (N +Int 1) T ... </s>


// -   `record` copies the current execution state to the end of the trace.


  syntax StateOp ::= "record"
//---------------------------
  rule <s> record [ STATE ] => . ... </s> <analysis> T => T ; STATE </analysis> requires STATE =/=K #current


// After performing BIMC, we'll need a container for the results of the analysis.

// -   `#bimc-result_in_steps` holds the result of a bimc analysis. The final state
//     reached in the analysis cell will be in the execution harness.


  syntax Exception ::= "#bimc-result" | "#bimc-result" PredAtom "in" Int "steps"
//------------------------------------------------------------------------------
  rule <s> #length N:Int ~> #bimc-result PA in -1 steps => #bimc-result PA in (N -Int 1) steps ... </s>
  rule <s> PA:PredAtom ~> #bimc-result => pop STATE ; #length T ; STATE ~> #bimc-result PA in -1 steps ... </s>
       <analysis> T ; STATE => .Analysis </analysis>


// -   `bimc?__` is a predicate that checks if an invariant holds for each step up
//     to a search-depth bound.
// -   `bimc__` turns the predicate `bimc?` into a standalone analysis.


  syntax Pred     ::= "bimc?" Int Pred
  syntax Strategy ::= "bimc"  Int Pred
//------------------------------------
  rule <s> bimc N P => bimc? N P ~> #bimc-result ... </s>
  rule <s> ( bimc? N P
          => analysis .Trace
           ; stack .States
           ; record
           ; (step ; record) until N ((not P) or stuck?)
           ; P
           ; #pred (drop until stack-empty?)
           )
           ...
       </s>

  syntax Pred ::= "bmc" Int Strategy
//----------------------------------
  rule <s> bmc 0 S => #true ... </s>
  rule <s> bmc N S => if (not try? S)
                      then #false
                      else if (try? step)
                           then bmc (N -Int 1) S
                           else #true
           ...
       </s>
    requires N >Int 0
  
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
// -   `_subsumes?` is a predicate on two states that should be provided by the
//     language definition (indicating whether the first state is more general than
//     the second).
// -   `abstract` is an operator than should abstract away enough details of the
//     state to guarantee termination of the execution of compilation. Note that
//     `abstract` needs to also take care not to destroy all information collected
//     about the state in this execution.
// -   `next-states` must push any new states to analyze onto the top of the
//     `states` stack.


  syntax StatePred ::= "cut-point?" | State "subsumes?"
//-----------------------------------------------------

  syntax StateOp ::= "abstract" | "next-states"
//---------------------------------------------


// -   `subsumed?` is a predicate that checks if any of the left-hand sides of the
//     rules `_subsumes_` the current state.


  syntax Pred ::= "subsumed?" | "#subsumed?" Rules
//------------------------------------------------
  rule <s> subsumed? => #subsumed? RS ... </s> <analysis> RS </analysis>

  rule <s> #subsumed? .Rules               => #false                             ... </s>
  rule <s> #subsumed? (RS , < STATE >)     => #subsumed? RS                      ... </s>
  rule <s> #subsumed? (RS , < LHS --> _ >) => (LHS subsumes?) or (#subsumed? RS) ... </s>


// At cut-points, we'll finish the rule we've been building, abstract the state,
// start a building a new rule from that state.

// -   `begin-rule` will use the current state as the left-hand-side of a new rule
//     in the record of rules.
// -   `end-rule` uses the current state as the right-hand-side of a new rule in
//     the record of rules.


  syntax StateOp ::= "begin-rule" | "end-rule"
//--------------------------------------------
  rule <s> begin-rule [ STATE ] => . ... </s> <analysis> RS => RS , < STATE >                </analysis> requires STATE =/=K #current
  rule <s> end-rule   [ STATE ] => . ... </s> <analysis> RS , (< LHS > => < LHS --> STATE >) </analysis> requires STATE =/=K #current


// -   `#compile-result_` holds the result of a sbc analysis.


  syntax Exception ::= "#compile-result" | "#compile-result" Rules
//----------------------------------------------------------------
  rule <s> #compile-result => #compile-result RS ... </s> <analysis> RS => .Analysis </analysis>


// Finally, semantics based compilation is provided as a macro.

// -   `compile-step` will generate the rule associated to the state at the top of
//     the `states` stack.


  syntax Strategy ::= "compile-step"
//----------------------------------
  rule <s> ( compile-step
          => if subsumed?
             then drop
             else ( pop
                  ; begin-rule
                  ; (step-with #normal)*
                  ; end-rule
                  ; abstract
                  ; next-states
                  )
           )
           ...
       </s>


// -   `compile` will initialize the stack to empty and the analysis to `.Rules`,
//     then compile the current program to completion.


  syntax Strategy ::= "compile"
//-----------------------------
  rule <s> ( compile
          => analysis .Rules
           ; stack .States
           ; push
           ; compile-step until stack-empty?
          ~> #compile-result
           )
           ...
       </s>
endmodule


// ### Future Work {#future-work-1}

// -   Post-processing steps including hashing any components of the state that are
//     concrete for the entire execution (eg. the `k` cell). This will reduce the
//     amount of extra matching that happens in executing the compiled definition.
// -   Use matching-logic implication to implement `_subsumes?` in a
//     language-indepedent way.
