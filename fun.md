Abstract
========

This is the K semantic definition of the untyped FUN language.
FUN is a pedagogical and research language that captures the essence of the functional programming paradigm, extended with several features often encountered in functional programming languages.
Like many functional languages, FUN is an expression language, that is, everything, including the main program, is an expression.
Functions can be declared anywhere and are first class values in the language.
FUN is call-by-value here, but it has been extended (as student homework assignments) with other parameter-passing styles.
To make it more interesting and to highlight some of K's strengths, FUN includes the following features:

-   The basic builtin data-types of integers, booleans and strings.

-   Builtin lists, which can hold any elements, including other lists.
    Lists are enclosed in square brackets and their elements are comma-separated; e.g., `[1,2,3]`.

-   User-defined data-types, by means of constructor terms.
    Constructor names start with a capital letter (while any other identifier in the language starts with a lowercase letter), and they can be followed by an arbitrary number of comma-separated arguments enclosed in parentheses; parentheses are not needed when the constructor takes no arguments.
    For example, `Pair(5,7)` is a constructor term holding two numbers, `Cons(1,Cons(2,Cons(3,Nil)))` is a list-like constructor term holding 3 elements, and `Tree(Tree(Leaf(1), Leaf(2)), Leaf(3))` is a tree-like constructor term holding 3 elements.
    In the untyped version of the FUN language, no type checking or inference is performed to ensure that the data constructors are used correctly.
    The execution will simply get stuck when they are misused. Moreover, since no type checking is performed, the data-types are not even declared in the untyped version of FUN.

-   Functions and `let`/`letrec` binders can take multiple space-separated arguments, but these are desugared to ones that only take one argument, by currying.
    For example, the expressions

    ```
    fun x y -> x y
    let x y = y in x
    ```

    are desugared, respectively, into the following expressions:

    ```
    fun x -> fun y -> x y
    let x = fun y -> y in x
    ```

-   Functions can be defined using pattern matching over the available data-types.
    For example, the program

    ```
    letrec max = fun [h] -> h
                 |   [h|t] -> let x = max t
                              in  if h > x then h else x
    in max [1, 3, 5, 2, 4, 0, -1, -5]
    ```

    defines a function `max` that calculates the maximum element of a non-empty list, and the function

    ```
    letrec ack = fun Pair(0,n) -> n + 1
                 |   Pair(m,0) -> ack Pair(m - 1, 1)
                 |   Pair(m,n) -> ack Pair(m - 1, ack Pair(m, n - 1))
    in ack Pair(2,3)
    ```

    calculates the Ackermann function applied to a particular pair of numbers.
    Patterns can be nested.
    Patterns can currently only be used in function definitions, and not directly in `let`/`letrec` binders.
    For example, this is not allowed:

    ```
    letrec Pair(x,y) = Pair(1,2) in x+y
    ```

    But this is allowed:

    ```
    let f Pair(x,y) = x+y in f Pair(1,2)
    ```

    because it is first reduced to

    ```
    let f = fun Pair(x,y) -> x+y in f Pair(1,2)
    ```

    by uncurrying of the `let` binder, and pattern matching is allowed in function arguments.

-   We include a `callcc` construct, for two reasons: first, several functional languages support this construct; second, some semantic frameworks have difficulties defining it.
    Not K.

-   Finally, we include mutables by means of referencing an expression, getting the reference of a variable, dereferencing and assignment.
    We include these for the same reasons as above: there are languages which have them, and they are not easy to define in some semantic frameworks.

Like in many other languages, some of FUN's constructs can be desugared into a smaller set of basic constructs.
We do that as usual, using macros, and then we only give semantics to the core constructs.

#### Note:

We recommend the reader to first consult the dynamic semantics of the LAMBDA++ language in the first part of the K Tutorial.
To keep the comments below small and focused, we will not re-explain functional or K features that have already been explained in there.

Syntax
======

```k
module FUN-UNTYPED-COMMON
    imports DOMAINS
```

```kcompile
    imports STRATEGY
```

FUN is an expression language.
The constructs below fall into several categories: names, arithmetic constructs, conventional functional constructs, patterns and pattern matching, data constructs, lists, references, and call-with-current-continuation (callcc).
The arithmetic constructs are standard; they are present in almost all our K language definitions.
The meaning of FUN's constructs are discussed in more depth when we define their semantics in the next module.

The Syntactic Constructs
------------------------

We start with the syntactic definition of FUN names.
We have several categories of names: ones to be used for functions and variables, others to be used for data constructors, others for types and others for type variables.
We will introduce them as needed, starting with the former category.
We prefer the names of variables and functions to start with lower case letters.
Three special names `$h`, `$t`, and `$k` are used in the semantics for desugaring builtin functions to actual functions (they will not parse in real programs).

```k
    syntax Name  ::= "$h" | "$t" | "$k"
    syntax Names ::= List{Name,","}
 // -------------------------------
```

### Symbolic Integers

```kcompile
    syntax Int ::= "symbolicInt" [function]
 // ---------------------------------------
    rule symbolicInt => ?V:Int
```

### Values

Expression constructs will be defined throughtout the syntax module.
Below are the very basic ones, namely the builtins, the names, and the parentheses used as brackets for grouping.
Lists of expressions are declared strict, so all expressions in the list get evaluated whenever the list is on a position which can be evaluated:

```k
    syntax KResult ::= Val | Vals
 // -----------------------------

    syntax ConstructorName
    syntax ClosureVal
    syntax ConstructorVal ::= ConstructorName
                            | ConstructorVal Val [left]
 // ---------------------------------------------------

    syntax ApplicableVal ::= ConstructorVal
                           | ClosureVal
                           | ApplicableVal Val [left]
 // -------------------------------------------------

    syntax Val ::= Int | Bool | String
                 | ApplicableVal
 // ----------------------------

    syntax Exp ::= Val | Name
                 | "(" Exp ")" [bracket]
 // ------------------------------------
```

```k
    syntax Exp ::= Exp Exp [left]
 // -----------------------------

    syntax Bool ::= isApplication ( Exp ) [function]
 // ------------------------------------------------
    rule isApplication(E:Exp E':Exp) => true
    rule isApplication(_:Exp)        => false [owise]
```

### Builtin Lists

FUN's builtin lists are `_:_` separated cons-lists like many functional languages support.
A list is turned back into a regular element by wrapping it in the `[_]` operator.

```k
    syntax Exps ::= Vals
    syntax Vals ::= Val | ".Vals" [klabel(.Vals)] | Val ":" Vals
    syntax Exps ::= Exp | ".Exps" [klabel(.Vals)] | Exp ":" Exps [seqstrict]
 // ------------------------------------------------------------------------

    syntax Val ::= "[" Vals "]"
    syntax Exp ::= "[" Exps "]" [strict]
 // ------------------------------------

    syntax Exp ::= "[" "]" [function]
 // ---------------------------------
    rule [ ] => [ .Vals ]
```

### Expressions

We next define the syntax of arithmetic constructs, together with their relative priorities and left-/non-associativities.
We also tag all these rules with a new tag, "arith", so we can more easily define global syntax priirities later (at the end of the syntax module).

**TODO**: Left attribute on `_^_` and `_+_` should not be necessary; currently a parsing bug.
          The "prefer" attribute above is to not parse x-1 as x(-1).
          Due to some parsing problems, we currently cannot add a unary minus (`3 + - 3`).

```k
    syntax Exp ::= left:
                   Exp "*" Exp    [seqstrict, arith]
                 | Exp "/" Exp    [seqstrict, arith]
                 | Exp "%" Exp    [seqstrict, arith]
                 > left:
                   Exp "+" Exp    [seqstrict, left, arith]
                 | Exp "^" Exp    [seqstrict, left, arith]
                 | Exp "-" Exp    [seqstrict, prefer, arith]
                 | "-" Exp        [seqstrict, arith]
                 > non-assoc:
                   Exp "<"  Exp   [seqstrict, arith]
                 | Exp "<=" Exp   [seqstrict, arith]
                 | Exp ">"  Exp   [seqstrict, arith]
                 | Exp ">=" Exp   [seqstrict, arith]
                 | Exp "==" Exp   [seqstrict, arith]
                 | Exp "!=" Exp   [seqstrict, arith]
                 > "!" Exp        [seqstrict, arith]
                 > Exp "&&" Exp   [strict(1), left, arith]
                 > Exp "||" Exp   [strict(1), left, arith]
 // ------------------------------------------------------
```

The conditional construct has the expected evaluation strategy, stating that only the first argument always evaluated:

```k
    syntax Exp ::= "if" Exp "then" Exp "else" Exp  [strict(1)]
 // ----------------------------------------------------------
```

### Algebraic Data Types

FUN also allows polymorphic datatype declarations.
These will be useful when we define the type system later on.

**NOTE**: In a future version of K, we want the datatype declaration to be a construct by itself, but that is not possible currently because K's parser wronly identifies the BLAH operation allowing a declaration to appear in front of an expression with the function application construct, giving ambiguous parsing errors.

```k
    syntax Exp ::= "datatype" Type "=" TypeCases Exp
 // ------------------------------------------------
    rule datatype T = TCS E => E [macro]
```

Data constructors start with capital letters and they may or may not have arguments.
We need to use the attribute "prefer" to make sure that, e.g., `Cons(a)` parses as constructor `Cons` with argument `a`, and not as the expression `Cons` applied (as a function) to argument `a`.
Also, note that the constructor is strict in its second argument, because we want to evaluate its arguments but not the constuctor name itsef.

### (Lambda) Functions

A function is essentially a "`|`"-separated ordered sequence of cases, each case of the form "`pattern -> expression`", preceded by the language construct `fun`.
Patterns will be defined shortly, both for the builtin lists and for user-defined constructors.
Recall that the syntax we define in K is not meant to serve as a ultimate parser for the defined language, but rather as a convenient notation for K abstract syntax trees, which we prefer when we write the semantic rules.
It is therefore often the case that we define a more "generous" syntax than we want to allow programs to use.

Specifically, the syntax of `Cases` below allows any expressions to appear as pattern.
This syntactic relaxation permits many wrong programs to be parsed, but that is not a problem because we are not going to give semantics to wrong combinations, so those programs will get stuck; moreover, our type inferencer will reject those programs anyway.
Function application is just concatenation of expressions, without worrying about type correctness.
Again, the type system will reject type-incorrect programs.

```k
    syntax Exp ::= "fun" Cases
 // --------------------------

    syntax Case ::= "->" Exp
                  | Exp Case [klabel(casePattern)]
 // ----------------------------------------------

    syntax Cases ::= List{Case, "|"}
 // --------------------------------
```

### Binding Environments

The `let` and `letrec` binders have the usual syntax and functional meaning. We allow multiple and-separated bindings.
Like for the function cases above, we allow a more generous syntax for the left-hand sides of bindings, noting that the semantics will get stuck on incorrect bindings and that the type system will reject those programs.

**TODO**: The "prefer" attribute for letrec currently needed due to tool bug, to make sure that "letrec" is not parsed as "let rec".

```k
    syntax Exp ::= "let"    Bindings "in" Exp
                 | "letrec" Bindings "in" Exp [prefer]
 // --------------------------------------------------

    syntax Binding  ::= Exp "=" Exp
    syntax Bindings ::= List{Binding,"and"}
 // ---------------------------------------

    syntax Name  ::= #name  ( Binding  ) [function]
    syntax Names ::= #names ( Bindings ) [function]
 // -----------------------------------------------
    rule #names(.Bindings)        => .Names
    rule #names(B:Binding and BS) => #name(B) , #names(BS)

    rule #name(N:Name = _) => N
    rule #name((E:Exp E':Exp => E) = _)

    syntax Exp  ::= #exp  ( Binding  ) [function]
    syntax Exps ::= #exps ( Bindings ) [function]
 // ---------------------------------------------
    rule #exps(.Bindings)        => .Exps
    rule #exps(B:Binding and BS) => #exp(B) : #exps(BS)

    rule #exp(_:Name = E) => E
    rule #exp(E:Exp E':Exp = fun C:Case => E = fun E' C     )
    rule #exp(E:Exp E':Exp = E''        => E = fun E' -> E'') [owise]
```

References are first class values in FUN.
The construct `ref` takes an expression, evaluates it, and then it stores the resulting value at a fresh location in the store and returns that reference.
Syntactically, `ref` is just an expression constant.
The construct `&` takes a name as argument and evaluates to a reference, namely the store reference where the variable passed as argument stores its value.
The construct `@` takes a reference and evaluates to the value stored there.
The construct `:=` takes two expressions, the first expected to evaluate to a reference; the value of its second argument will be stored at the location to which the first points (the old value is thus lost).
Finally, since expression evaluation now has side effects, it makes sense to also add a sequential composition construct, which is sequentially strict.
This evaluates to the value of its second argument; the value of the first argument is lost (which has therefore been evaluated only for its side effects.

```k
    syntax Exp ::= "ref"
                 | "&" Name
                 | "@" Exp      [seqstrict]
                 | Exp ":=" Exp [seqstrict]
                 | Exp ";"  Exp [strict(1), right]
 // ----------------------------------------------
```

### Jumps in Control Flow

Call-with-current-continuation, named `callcc` in FUN, is a powerful control operator that originated in the Scheme programming language, but it now exists in many other functional languages.
It works by evaluating its argument, expected to evaluate to a function, and by passing the current continuation, or evaluation context (or computation, in K terminology), as a special value to it.
When/If this special value is invoked, the current context is discarded and replaced with the one held by the special value and the computation continues from there.
It is like taking a snapshot of the execution context at some moment in time and then, when desired, being able to get back in time to that point.
If you like games, it is like saving the game now (so you can work on your homework!) and then continuing the game tomorrow or whenever you wish.
To issustrate the strength of `callcc`, we also allow exceptions in FUN by means of a conventional `try-catch` construct, which will desugar to `callcc`.
We also need to introduce the special expression contant `throw`, but we need to use it as a function argument name in the desugaring macro, so we define it as a name instead of as an expression constant:

```k
    syntax Exp ::= "callcc"
                 | "try" Exp "catch" "(" Name ")" Exp
 // -------------------------------------------------
    rule try E catch(X) E' => callcc (fun $k -> (fun $t -> E) (fun X -> $k E')) [macro]
```

### Types

We next need to define the syntax of types and type cases that appear in datatype declarations.
Like in many functional languages, type parameters/variables in user-defined types are quoted identifiers.

```k
    syntax TypeVar
    syntax TypeVars ::= List{TypeVar,","}
 // -------------------------------------
```

Types can be basic types, function types, or user-defined parametric types.
In the dynamic semantics we are going to simply ignore all the type declations, so here the syntax of types below is only useful for generating the desired parser.
To avoid syntactic ambiguities with the arrow construct for function cases, we use the symbol `-->` as a constructor for function types:

```k
    syntax TypeName
    syntax Type ::= "int" | "bool" | "string"
                  | Type "-->" Type           [right]
                  | "(" Type ")"              [bracket]
                  | TypeVar
                  | TypeName                  [klabel(TypeName), avoid]
                  | Type TypeName             [klabel(Type-TypeName)]
                  | "(" Types ")" TypeName    [prefer]
 // --------------------------------------------------
    rule Type-TypeName(T:Type, Tn:TypeName) => (T) Tn [macro]

    syntax Types ::= List{Type,","}
    syntax Types ::= TypeVars
 // -------------------------

    syntax TypeCase  ::= ConstructorName
                       | TypeCase Type
    syntax TypeCases ::= List{TypeCase,"|"}            [klabel(_|TypeCase_)]
 // ------------------------------------------------------------------------
```

Additional Priorities
---------------------

These inform the parser of precedence information when ambiguous parses show up.

```k
    syntax priorities @__FUN-UNTYPED-COMMON
                    > casePattern
                    > ___FUN-UNTYPED-COMMON
                    > arith
                    > _:=__FUN-UNTYPED-COMMON
                    > let_in__FUN-UNTYPED-COMMON
                      letrec_in__FUN-UNTYPED-COMMON
                      if_then_else__FUN-UNTYPED-COMMON
                    > _;__FUN-UNTYPED-COMMON
                    > fun__FUN-UNTYPED-COMMON
                    > datatype_=___FUN-UNTYPED-COMMON
endmodule
```

FUN Identifier Instantiation
----------------------------

The following module instantiates the empty identifier sorts declared above with their corresponding regular expressions.

```k
module FUN-UNTYPED-SYNTAX
    imports FUN-UNTYPED-COMMON
    imports BUILTIN-ID-TOKENS

    syntax Name            ::= r"[a-z][_a-zA-Z0-9]*"      [autoReject, token, prec(2)]
                             | #LowerId                   [autoReject, token]
    syntax ConstructorName ::= #UpperId                   [autoReject, token]
    syntax TypeVar         ::= r"['][a-z][_a-zA-Z0-9]*"   [autoReject, token]
    syntax TypeName        ::= Name                       [autoReject, token]
endmodule
```

Semantics
=========

The semantics below is environment-based. A substitution-based
definition of FUN is also available, but that drops the `&` construct as
explained above.

```k
module FUN-UNTYPED
    imports FUN-UNTYPED-COMMON
    imports DOMAINS
```

Configuration
-------------

The [k]{.sans-serif}, [env]{.sans-serif}, and [store]{.sans-serif} cells
are standard (see, for example, the definition of LAMBDA++ or IMP++ in
the first part of the K tutorial).

```k
    configuration
      <FUN>
        <k>         $PGM:Exp </k>
        <callStack> .List    </callStack>
        <env>       .Map     </env>
        <store>     .Map     </store>
        <nextLoc>   0        </nextLoc>
      </FUN>
```

Lookup
------

```k
    rule <k> X:Name => V ... </k>
         <env>   ... X |-> L       ... </env>
         <store> ...       L |-> V ... </store>
      [tag(lookup)]
```

Expressions
-----------

```k
    rule <k> I1 * I2 => I1 *Int I2 ... </k>
    rule <k> I1 / I2 => I1 /Int I2 ... </k> requires I2 =/=K 0
    rule <k> I1 % I2 => I1 %Int I2 ... </k> requires I2 =/=K 0
    rule <k> I1 + I2 => I1 +Int I2 ... </k>
    rule <k> I1 - I2 => I1 -Int I2 ... </k>
    rule <k>    - I  => 0  -Int I  ... </k>

    rule <k> S1 ^ S2 => S1 +String S2 ... </k>

    rule <k> I1 <  I2 => I1  <Int I2 ... </k>
    rule <k> I1 <= I2 => I1 <=Int I2 ... </k>
    rule <k> I1 >  I2 => I1  >Int I2 ... </k>
    rule <k> I1 >= I2 => I1 >=Int I2 ... </k>

    rule <k> V1:Val == V2:Val => V1  ==K V2 ... </k>
    rule <k> V1:Val != V2:Val => V1 =/=K V2 ... </k>

    rule <k>        ! T => notBool(T) ... </k>
    rule <k> true  && E => E          ... </k>
    rule <k> false && _ => false      ... </k>
    rule <k> true  || _ => true       ... </k>
    rule <k> false || E => E          ... </k>
```

Conditional
-----------

```k
    rule <k> if  true then E else _ => E ... </k> [tag(iftrue)]
    rule <k> if false then _ else E => E ... </k> [tag(iffalse)]
```

Lists
-----

We have already declared the syntactic list of expressions strict, so we
can assume that all the elements that appear in a FUN list are
evaluated. The only thing left to do is to state that a list of values
is a value itself, that is, that the list square-bracket construct is
indeed a constructor, and to give the semantics of `cons`. Since `cons`
is a builtin function and is expected to take two arguments, we have to
also state that `cons` itself is a value (specifically, a
function/closure value, but we do not need that level of detail here),
and also that `cons` applied to a value is a value (specifically, it
would be a function/closure value that expects the second, list
argument):

Functions and Closures
----------------------

Like in the environment-based semantics of LAMBDA++ in the first part of
the K tutorial, functions evaluate to closures. A closure includes the
current environment besides the function contents; the environment will
be used at execution time to lookup all the variables that appear free
in the function body (we want static scoping in FUN).

```k
    syntax ClosureVal ::= closure ( Map , Cases )
 // ---------------------------------------------
    rule <k> fun CASES => closure(RHO, CASES) ... </k>
         <env> RHO </env>

    syntax Exp ::= muclosure ( Map , Cases )
 // ----------------------------------------
    rule <k> muclosure(RHO, CS) => closure(RHO, CS) ... </k> [tag(recCall)]

    syntax Arg   ::= #arg   ( Val  )
    syntax KItem ::= #apply ( Exp  )
                   | #args  ( Vals )
 // --------------------------------
    rule <k> E:Exp V => E ~> #arg(V) ... </k>
      requires notBool isVal(E)
      [tag(applicationFocusFunction)]

    rule <k> CV:ConstructorVal ~> #arg(V) => CV V ... </k>

    rule <k> E E':Exp => E' ~> #apply(E) ... </k>
      requires notBool isVal(E')
      [tag(applicationFocusArgument)]

    rule <k> V:Val ~> #apply(E) => E V ... </k>

    syntax KItem ::= #closure ( Map , Cases , Vals )
 // ------------------------------------------------
    rule <k> (closure(RHO, CS) ~> REST) => matchResult(.Names, .Vals) ~> #closure(RHO, CS, #collectArgs(REST)) ~> #args(#collectArgs(REST)) ~> #stripArgs(REST) </k> requires #collectArgs(REST) =/=K .Vals
    rule <k> (. => getMatching(P, V)) ~> matchResult(_, _) ~> #closure(RHO, ((P:Exp C:Case => C) | _), (V : VS => VS)) ... </k>
    rule <k> (matchFailure => matchResult(.Names, .Vals)) ~> #closure(RHO, (C:Case | CS => CS), (_ => VS)) ~> #args(VS) ~> REST </k>
    rule <k> matchResult(XS, VS) ~> #closure(RHO, -> ME | _, .Vals) ~> #args(_) => binds(XS, VS) ~> ME ~> setEnv(RHO') ... </k>
         <env> RHO' => RHO </env>

    syntax Vals ::= #collectArgs ( K ) [function]
 // ---------------------------------------------
    rule #collectArgs(#arg(V) ~> KS) => V : #collectArgs(KS)
    rule #collectArgs(_)             => .Vals                [owise]

    syntax K ::= #stripArgs ( K ) [function]
 // ----------------------------------------
    rule #stripArgs(#arg(V) ~> KS) => #stripArgs(KS)
    rule #stripArgs(KS)            => KS             [owise]
```

#### Note:

The reader may want to get familiar with how the pre-defined pattern matching works before proceeding.
The best way to do that is to consult `k/include/modules/pattern-matching.k`.

We distinguish two cases when the closure is applied.
If the first pattern matches, then we pick the first case: switch to the closed environment, get the binding from the match, evaluate the function body in the combined environment, making sure that the environment is properly recovered afterwards.
If the first pattern does not match, then we drop it and thus move on to the next one.

Let and Letrec
--------------

To highlight the similarities and differences between `let` and
`letrec`, we prefer to give them direct semantics instead of to desugar
them like in LAMBDA. See the formal definitions of `bind` and `binds`.
Informally, `bindTo(\it Xs,\it Es)` first evaluates the expressions
${\it Es}\in\textit{Exps}$ in the current environment (i.e., it is
strict in its second argument), then it binds the variables in
${\it Xs}\in\textit{Names}$ to new locations and adds those bindings to
the environment, and finally writes the values previously obtained after
evaluating the expressions $\it Es$ to those new locations;
`bind(\it Xs)` does only the bindings of $\it Xs$ to new locations and
adds those bindings to the environment; and `assignTo(\it Xs,\it Es)`
evaluates the expressions $\it Es$ in the current environment and then
it writes the resulting values to the locations to which the variables
$\it Xs$ are already bound to in the environment.

Therefore, "`let \it Xs=\it Es in \it E`" first evaluates $\it Es$ in
the current environment, then adds new bindings for $\it Xs$ to fresh
locations in the environment, then writes the values of $\it Es$ to
those locations, and finally evaluates *E* in the new environment,
making sure that the environment is properly recovered after the
evaluation of *E*. On the other hand, `letrec` does the same things but
in a different order: it first adds new bindings for $\it Xs$ to fresh
locations in the environment, then it evaluates $\it Es$ in the new
environment, then it writes the resulting values to their corresponding
locations, and finally it evaluates *E* and recovers the environment.
The crucial difference is that the expressions $\it Es$ now see the
locations of the variables $\it Xs$ in the environment, so if they are
functions, which is typically the case with `letrec`, their closures
will encapsulate in their environments the bindings of all the bound
variables, including themselves (thus, we may have a closure value
stored at location *L*, whose environment contains a binding of the form
$\textit{F} \mapsto \textit{L}$; this way, the closure can invoke
itself).

```k
    rule <k> let BS in E ~> REST => binds(#names(BS), #exps(BS)) ~> E </k>
         <env> RHO </env>
         <callStack> (.List => ListItem(setEnv(RHO) ~> REST)) ... </callStack>
      [tag(letBinds)]

    rule <k> letrec BS in E ~> REST => bindsRec(#names(BS), #exps(BS)) ~> E </k>
         <env> RHO </env>
         <callStack> (.List => ListItem(setEnv(RHO) ~> REST)) ... </callStack>
      [tag(letRecBinds)]

    rule <k> V:Val ~> (. => CALLSTACK) </k>
         <callStack> (ListItem(CALLSTACK) => .List) ... </callStack>
```

Recall that our syntax allows `let` and `letrec` to take any
expression in place of its binding. This allows us to use the already
existing function application construct to bind names to functions, such
as, e.g., "`let x y = y in ...`". The desugaring macro in the syntax
module uncurries such declarations, and then the semantic rules above
only work when the remaining bindings are identifiers, so the semantics
will get stuck on programs that misuse the `let` and `letrec` binders.

References
----------

The semantics of references is self-explanatory, except maybe for the
desugaring rule of `ref`, which is further discussed. Note that `&X`
grabs the location of $X$ from the environment. Sequential composition,
which is needed only to accumulate the side effects due to assignments,
was strict in the first argument. Once evaluated, its first argument is
simply discarded:

```k
    syntax Name ::= "$x"
 // --------------------
    rule ref => fun $x -> & $x [macro]

    rule <k> & X              => L     ... </k> <env>   ... X |-> L        ... </env>
    rule <k> @ L:Int          => V:Val ... </k> <store> ... L |-> V        ... </store>
    rule <k>   L:Int := V:Val => V     ... </k> <store> ... L |-> (_ => V) ... </store>

    rule <k> V:Val; E => E ... </k>
```

The desugaring rule of `ref` (first rule above) works because `&`
takes a variable and returns its location (like in C). Note that some
"pure" functional programming researchers strongly dislike the `&`
construct, but favor `ref`. We refrain from having a personal opinion on
this issue here, but support `&` in the environment-based definition of
FUN because it is, technically speaking, more powerful than `ref`. From
a language design perspective, it would be equally easy to drop `&` and
instead give a direct semantics to `ref`. In fact, this is precisely
what we do in the substitution-based definition of FUN, because there
appears to be no way to give a substitution-based definition to the `&`
construct.

Callcc
------

As we know it from the LAMBDA++ tutorial, call-with-current-continuation
is quite easy to define in K. We first need to define a special value
wrapping an execution context, that is, an environment saying where the
variables should be looked up, and a computation structure saying what
is left to execute (in a substitution-based definition, this special
value would be even simpler, as it would only need to wrap the
computation structure---see, for example, the substitution-based
semantics of LAMBDA++ in the the first part of the K tutorial, or the
substitution-based definition of FUN). Then `callcc` creates such a
value containing the current environment and the current remaining
computation, and passes it to its argument function. When/If invoked,
the special value replaces the current execution context with its own
and continues the execution normally.

```k
    syntax Val ::= cc ( Map , K )
 // -----------------------------
    rule isVal(callcc) => true

    rule <k> (callcc V:Val => V cc(RHO, K)) ~> K </k>
         <env> RHO </env>

    rule <k> cc(RHO, K) V:Val ~> _ => V ~> K </k>
         <env> _ => RHO </env>
```

Auxiliary operations
--------------------

### Environment recovery

The environment recovery operation is the same as for the LAMBDA++
language in the K tutorial and many other languages provided with the
K distribution. The first "anywhere" rule below shows an elegant way to
achieve the benefits of tail recursion in K.

```k
    syntax KItem ::= setEnv ( Map )
 // -------------------------------
    rule <k> _:Val ~> (setEnv(RHO) => .) ... </k>
         <env> _ => RHO </env>
      [tag(resetEnv)]
```

### `bind`, `binds`, and `bindsRec`

These operations add a single binding (or list of binding) into the current environment/store.

```k
    syntax KItem ::=  binds    ( Names , Exps ) [strict(2)]
                   |  bindsRec ( Names , Exps )
                   | #bindsRec ( Names , Exps ) [strict(2)]
                   | #bind     ( Name  , Val  )
                   | #bindRec  ( Name  , Val  )
                   | #assign   ( Name  , Exp  )
                   | #allocate ( Names        )
 // -------------------------------------------
    rule <k> binds(.Names,              .Vals)           => .                            ... </k>
    rule <k> binds((X:Name , XS:Names), V:Val : VS:Vals) => #bind(X, V) ~> binds(XS, VS) ... </k>

    rule <k> bindsRec(XS, VS) => #allocate(XS) ~> #bindsRec(XS, VS) ... </k>

    rule <k> #bindsRec((X:Name , XS:Names), V:Val : VS:Vals) => #bindRec(X, V) ~> #bindsRec(XS, VS) ... </k>
    rule <k> #bindsRec(.Names,              .Vals)           => .                                   ... </k>

    rule <k> #bind(X, V)                   => #allocate(X, .Names) ~> #assign(X, V) ... </k>
    rule <k> #bindRec(X, V)                => #assign(X, V)                         ... </k> requires notBool isClosureVal(V)
    rule <k> #bindRec(X, closure(RHO, CS)) => #assign(X, muclosure(RHO, CS))        ... </k>

    rule <k> #assign(X, #listTailMatch(V)) => . ... </k>
         <env> ... X |-> L ... </env>
         <store> STORE => STORE[L <- V] </store>
      [tag(listAssignment)]

    rule <k> #assign(X, V) => . ... </k>
         <env> ... X |-> L ... </env>
         <store> STORE => STORE[L <- V] </store>
      requires notBool #isListTailMatch(V)
      [tag(assignment)]

    rule <k> #allocate(.Names)              => .             ... </k>
    rule <k> #allocate((X:Name , XS:Names)) => #allocate(XS) ... </k>
         <env>     RHO   => RHO[X <- NLOC]   </env>
         <nextLoc> NLOC  => NLOC +Int 1      </nextLoc>
      [tag(allocate)]
```

### Getters

The following auxiliary operations extract the list of identifiers and
of expressions in a binding, respectively.

```k
    /* Matching */
    syntax MatchResult ::= "matchFailure" [smtlib(matchFailure)]
                         | matchResult  ( Names , Vals )
                         | getMatching  ( Exp   , Val  )
                         | getMatchings ( Exps  , Vals )
 // ----------------------------------------------------
    rule <k> matchFailure ~> (_:MatchResult => .) ... </k>

    rule <k> matchResult(XS, VS) ~> matchResult(XS', VS') => matchResult(XS ++Names XS', VS ++Vals VS') ... </k>
      requires intersectSet(#asSet(XS), #asSet(XS')) ==K .Set
      [tag(caseLinearMatchJoinSuccess)]

    rule <k> matchResult(XS, VS) ~> matchResult(XS', VS') => matchFailure ... </k>
      requires intersectSet(#asSet(XS), #asSet(XS')) =/=K .Set
      [tag(caseLinearMatchJoinFailure)]

    rule <k> matchResult(XS, VS) ~> getMatchings(ES, VS') => getMatchings(ES, VS') ~> matchResult(XS, VS) ... </k>
    rule <k> matchResult(XS, VS) ~> getMatching (E , V  ) => getMatching (E , V  ) ~> matchResult(XS, VS) ... </k>

    rule <k> getMatching(B:Bool,   B':Bool)   => matchResult(.Names, .Vals) ... </k> requires B  ==Bool   B' [tag(caseBoolSuccess)]
    rule <k> getMatching(B:Bool,   B':Bool)   => matchFailure               ... </k> requires B =/=Bool   B' [tag(caseBoolFailure)]
    rule <k> getMatching(I:Int,    I':Int)    => matchResult(.Names, .Vals) ... </k> requires I  ==Int    I' [tag(caseIntSuccess)]
    rule <k> getMatching(I:Int,    I':Int)    => matchFailure               ... </k> requires I =/=Int    I' [tag(caseIntFailure)]
    rule <k> getMatching(S:String, S':String) => matchResult(.Names, .Vals) ... </k> requires S  ==String S' [tag(caseStringSuccess)]
    rule <k> getMatching(S:String, S':String) => matchFailure               ... </k> requires S =/=String S' [tag(caseStringFailure)]

    rule <k> getMatching(N:Name, V:Val) => matchResult((N , .Names), V : .Vals) ... </k> [tag(caseNameSuccess)]

    rule <k> getMatching(C:ConstructorName , C':ConstructorName) => matchResult(.Names, .Vals) ... </k> requires C  ==K C' [tag(caseConstructorNameSuccess)]
    rule <k> getMatching(C:ConstructorName , C':ConstructorName) => matchFailure               ... </k> requires C =/=K C' [tag(caseConstructorNameFailure)]

    rule <k> getMatching(E:Exp E':Exp , AV:ApplicableVal V':Val) => getMatching(E, AV) ~> getMatching(E', V') ... </k> [tag(caseConstructorArgsSuccess)]
    rule <k> getMatching(E:Exp E':Exp , AV:ApplicableVal       ) => matchFailure                              ... </k> requires notBool isApplication(AV) [tag(caseConstructorArgsFailure1)]
    rule <k> getMatching(E:Exp        , AV:ApplicableVal V':Val) => matchFailure                              ... </k> requires notBool isApplication(E)  [tag(caseConstructorArgsFailure2)]

    rule <k> getMatching([ES:Exps], [VS:Vals]) => getMatchings(ES, VS) ... </k> [tag(caseListSuccess)]

    rule <k> getMatchings(.Exps,             (_:Val : _:Vals) ) => matchFailure                                          ... </k>                            [tag(caseListEmptyFailure3)]
    rule <k> getMatchings(.Exps,             .Vals            ) => matchResult(.Names, .Vals)                            ... </k>                            [tag(caseListEmptySuccess)]
    rule <k> getMatchings(X:Name,            VS:Vals          ) => matchResult((X , .Names), #listTailMatch(VS) : .Vals) ... </k>                            [tag(caseListSingletonSuccess)]
    rule <k> getMatchings(E:Exp,             .Vals            ) => matchFailure                                          ... </k> requires notBool isName(E) [tag(caseListEmptyFailure1)]
    rule <k> getMatchings((_:Exp : _:Exps ), .Vals            ) => matchFailure                                          ... </k>                            [tag(caseListEmptyFailure2)]
    rule <k> getMatchings((E:Exp : ES:Exps), (V:Val : VS:Vals)) => getMatching(E, V) ~> getMatchings(ES, VS)             ... </k>                            [tag(caseListNonemptySuccess)]

    syntax Val ::= #listTailMatch ( Vals )
 // --------------------------------------

    syntax Bool ::= #isListTailMatch ( Exp ) [function]
 // ---------------------------------------------------
    rule #isListTailMatch(#listTailMatch(_)) => true
    rule #isListTailMatch(_)                 => false [owise]

    syntax Names ::= Names "++Names" Names [function]
 // -------------------------------------------------
    rule .Names   ++Names XS' => XS'
    rule (X , XS) ++Names XS' => X , (XS ++Names XS')

    syntax Vals ::= Vals "++Vals" Vals [function]
 // ---------------------------------------------
    rule .Vals    ++Vals VS' => VS'
    rule (V : VS) ++Vals VS' => V : (VS ++Vals VS')

    syntax Set ::= #asSet ( Names ) [function]
 // ------------------------------------------
    rule #asSet(.Names) => .Set
    rule #asSet(X , XS) => SetItem(X) #asSet(XS)
endmodule
```
