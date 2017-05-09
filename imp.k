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


  syntax KItem ::= "div-zero-error"

  syntax AExp  ::= Int | Id
                 | AExp "/" AExp [left, strict]
                 | AExp "*" AExp [left, strict]
                 > AExp "-" AExp [left, strict]
                 | AExp "+" AExp [left, strict]
                 | "(" AExp ")"  [bracket]
//----------------------------------------
  rule I1 + I2 => I1 +Int I2
  rule I1 - I2 => I1 -Int I2
  rule I1 * I2 => I1 *Int I2
  rule I1 / 0  => div-zero-error                  [tag(div-success)]
  rule I1 / I2 => I1 /Int I2 requires I2 =/=Int 0 [tag(div-failure)]


// IMP has `BExp` for boolean expressions.


  syntax BExp  ::= Bool
                 | AExp "<=" AExp [seqstrict]
                 | AExp "<" AExp  [seqstrict]
                 | AExp "==" AExp [seqstrict]
                 | "!" BExp       [strict]
                 > BExp "&&" BExp [left, strict(1)]
                 | "(" BExp ")"   [bracket]
//-----------------------------------------
  rule I1 <= I2   => I1 <=Int I2
  rule I1 <  I2   => I1 <Int  I2
  rule I1 == I2   => I1 ==Int I2
  rule ! T        => notBool T
  rule true  && B => B
  rule false && _ => false


// IMP has `{_}` for creating blocks of statements.


  syntax Block ::= "{" "}" | "{" Stmt "}"
//---------------------------------------
  rule {}  => .
  rule {S} => S


// IMP has `int_;` for declaring variables, `if_then_else_` for choice, `_=_;` for
// assignment, and `while(_)_` for looping.


  syntax Ids ::= List{Id,","}
  syntax Stmt ::= Block
                | "int" Ids ";"
                | Id "=" AExp ";"                      [strict(2)]
                | "if" "(" BExp ")" Block "else" Block [strict(1)]
                | "while" "(" BExp ")" Block
                > Stmt Stmt                            [left]
//-----------------------------------------------------------
  rule S1:Stmt S2:Stmt => S1 ~> S2
  rule if (true)  B:Block else _ => B:Block [tag(if-true)]
  rule if (false) _ else B:Block => B:Block [tag(if-false)]

  rule int .Ids ; => .
  rule <k> int (X,Xs => Xs) ; ... </k>
       <mem> Rho:Map (.Map => X |-> 0) </mem>
    requires notBool (X in keys(Rho))

  rule <k> X:Id        => I ... </k> <mem> ... X |-> I        ... </mem> [tag(lookup)]
  rule <k> X = I:Int ; => . ... </k> <mem> ... X |-> (_ => I) ... </mem> [tag(assignment)]

  rule while (B) STMT => if (B) {STMT while (B) STMT} else {} [tag(while)]
endmodule

