// IMP Language
// ============

// The IMP language is largely defined as in the [K
// tutorial](www.kframework.org/index.php/K_Tutorial). Refer there for a more
// detailed explanation of the language.

// Configuration
// -------------

// The IMP language has a `k` cell for execution and a `mem` cell for storage. In
// IMP, base values are of sorts `Int` and `Bool`.


module IMP
  imports MAP
  imports STRATEGY

  configuration <imp>
                  <k> $PGM:Stmt </k>
                  <mem> .Map </mem>
                </imp>

  syntax KResult  ::= Int | Bool


// Expressions
// -----------

// IMP has `AExp` for arithmetic expressions (over integers).


  syntax AExp  ::= Int | Id
                 | AExp "/" AExp [left, strict]
                 | AExp "*" AExp [left, strict]
                 > AExp "-" AExp [left, strict]
                 | AExp "+" AExp [left, strict] 
                 | "(" AExp ")"  [bracket]
//----------------------------------------
  rule I1 + I2 => I1 +Int I2                      [structural]
  rule I1 - I2 => I1 -Int I2                      [structural]
  rule I1 * I2 => I1 *Int I2                      [structural]
  rule I1 / I2 => I1 /Int I2 requires I2 =/=Int 0 [structural]


// IMP has `BExp` for boolean expressions.


  syntax BExp  ::= Bool
                 | AExp "<=" AExp [seqstrict]
                 | AExp "<" AExp  [seqstrict]
                 | AExp "==" AExp [seqstrict]
                 | "!" BExp       [strict]
                 > BExp "&&" BExp [left, strict(1)]
                 | "(" BExp ")"   [bracket]
//-----------------------------------------
  rule I1 <= I2   => I1 <=Int I2 [structural]
  rule I1 <  I2   => I1 <Int  I2 [structural]
  rule I1 == I2   => I1 ==Int I2 [structural]
  rule ! T        => notBool T   [structural]
  rule true  && B => B           [structural]
  rule false && _ => false       [structural]


// Statements
// ----------

// IMP has `{_}` for creating blocks and `int_;` for declaring variables.


  syntax Block ::= "{" "}" | "{" Stmt "}"
//---------------------------------------
  rule {}              => .        [structural]
  rule {S}             => S        [structural]

  syntax Ids ::= List{Id,","}
  syntax Stmt ::= "int" Ids ";"
//-----------------------------
  rule <k> int .Ids ; => .    ... </k> [structural]
  rule <k> int (X,Xs => Xs) ; ... </k>
       <mem> Rho:Map (.Map => X |-> 0) </mem>
     requires notBool (X in keys(Rho))
     [structural]


// IMP has `if_then_else_` for choice, `_=_;` for assignment, and `while(_)_` for
// looping.


  syntax Stmt  ::= Block
                 | Id "=" AExp ";"                      [strict(2)]
                 | "if" "(" BExp ")" Block "else" Block [strict(1)]
                 | "while" "(" BExp ")" Block
                 > Stmt Stmt                            [left]
//------------------------------------------------------------
  rule S1:Stmt S2:Stmt => S1 ~> S2 [structural]


// Semantics
// ---------

// All the rules above are "regular" rules, not to be considered transition steps
// by analysis tools. The rules below are named (with the attribute `tag`) so that
// strategy-based analysis tools can treat them specially.


  rule <k> X:Id        => I ... </k> <mem> ... X |-> I        ... </mem> [tag(lookup)]
  rule <k> X = I:Int ; => . ... </k> <mem> ... X |-> (_ => I) ... </mem> [tag(assignment)]

  rule if (true)  B:Block else _ => B:Block [tag(if), transition]
  rule if (false) _ else B:Block => B:Block [tag(if), transition]

  rule while (B) STMT => if (B) {STMT while (B) STMT} else {} [tag(while)]
endmodule

