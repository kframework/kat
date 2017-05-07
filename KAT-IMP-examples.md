IMP Exmaples
============

In this file several tests are provided for KAT.

Straight Line Code
------------------

These programs are "straight-line code" in IMP; they don't have any branching or looping.

```{.imp .straight-line-1 .k}
int x ;
x = 0 ;
x = x + 15 ;
```

```{.imp .straight-line-2 .k}
int x ;
x = 0 ;
x = x + 15 ;
x = x + -10 ;
```

Branching
---------

This example exhibits a "dead" if statement; any good compiler would optimize it away.

```{.imp .dead-if .k}
int x ;

x = 7 ;
if (x <= 7) {
  x = 1 ;
} else {
  x = -1 ;
}
```

Looping
-------

This is the classic `sum` program, which just sums the numbers from 1 to 10.

```{.imp .sum .k}
int n , s ;

n = 10 ;
while (0 <= n) {
  n = n + -1 ;
  s = s + n ;
}
```

This version of the `sum` proogram has additional statements after the main while loop.

```{.imp .sum-plus .k}
int n , s ;

n = 10 ;
while (0 <= n) {
  n = n + -1 ;
  s = s + n ;
}

s = s + 300 ;
```

Here the Collatz loop is provided, which calculates how many steps it takes a given number to go to 1 using Collatz update.

```{.imp .collatz .k}
int n , x ;

n = 782 ;
x = 0 ;

while (2 <= n) {
  if (n <= ((n / 2) * 2)) {
    n = n / 2 ;
  } else {
    n = (3 * n) + 1 ;
  }
  x = x + 1 ;
}
```

Running KAT
===========

BIMC
----

Here, we allow each program to initialize (get through variable declarations) by running `step-with skip`.
Then we issue some `bimc` query to check if the program obeys the given invariant up to the depth-bound.

### Straight Line 1

Assertion not violated at step 2:

```{.sh .runtests}
krun --directory '../' -cSTRATEGY='step-with skip ; bimc 2 (bexp? x <= 7)' straight-line-1.imp
```

```{.k .straight-line-1-bimc-2-output}
<kat> <s> #STUCK ~> #bimc-result #true </s> <imp> <k> x = 15 ; </k> <mem> x |-> 0 </mem> </imp> <analysis> ( ( .Trace ; { x = 0 ; ~> ( x = x + 15 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( 15 ) ~> #freezer_=_;0 ( x ) | x |-> 0 } ) ; { x = 15 ; | x |-> 0 } </analysis> <states> .States </states> </kat>
```

Assertion violation at step 3:

```{.sh .runtests}
krun --directory '../' -cSTRATEGY='step-with skip ; bimc 3 (bexp? x <= 7)' straight-line-1.imp
```

```{.k .straight-line-1-bimc-1-output}
<kat> <s> #STUCK ~> #bimc-result #false </s> <imp> <k> . </k> <mem> x |-> 15 </mem> </imp> <analysis> ( ( ( .Trace ; { x = 0 ; ~> ( x = x + 15 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( 15 ) ~> #freezer_=_;0 ( x ) | x |-> 0 } ) ; { x = 15 ; | x |-> 0 } ) ; { . | x |-> 15 } </analysis> <states> .States </states> </kat>
```

### Straight Line 2

Assertion not violated up to step 2:

```{.sh .runtests}
krun --directory '../' -cSTRATEGY='step-with skip ; bimc 2 (bexp? x <= 7)' straight-line-2.imp
```

```
<kat> <s> #STUCK ~> #bimc-result #true </s> <imp> <k> x = 15 ; ~> ( x = x + -10 ; ) </k> <mem> x |-> 0 </mem> </imp> <analysis> ( ( .Trace ; { x = 0 ; ~> ( x = x + 15 ; ) ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( 15 ) ~> #freezer_=_;0 ( x ) ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x = 15 ; ~> ( x = x + -10 ; ) | x |-> 0 } </analysis> <states> .States </states> </kat>
```

Assertion violated at step 3:

```{.sh .runtests}
krun --directory '../' -cSTRATEGY='step-with skip ; bimc 3 (bexp? x <= 7)' straight-line-2.imp
```

```
<kat> <s> #STUCK ~> #bimc-result #false </s> <imp> <k> x ~> #freezer_+_1 ( -10 ) ~> #freezer_=_;0 ( x ) </k> <mem> x |-> 15 </mem> </imp> <analysis> ( ( ( .Trace ; { x = 0 ; ~> ( x = x + 15 ; ) ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( 15 ) ~> #freezer_=_;0 ( x ) ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x = 15 ; ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( -10 ) ~> #freezer_=_;0 ( x ) | x |-> 15 } </analysis> <states> .States </states> </kat>
```

Assertion still violated at step 3 (with extended bound):

```{.sh .runtests}
krun --directory '../' -cSTRATEGY='step-with skip ; bimc 500 (bexp? x <= 7)' straight-line-2.imp
```

```
<kat> <s> #STUCK ~> #bimc-result #false </s> <imp> <k> x ~> #freezer_+_1 ( -10 ) ~> #freezer_=_;0 ( x ) </k> <mem> x |-> 15 </mem> </imp> <analysis> ( ( ( .Trace ; { x = 0 ; ~> ( x = x + 15 ; ) ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( 15 ) ~> #freezer_=_;0 ( x ) ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x = 15 ; ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( -10 ) ~> #freezer_=_;0 ( x ) | x |-> 15 } </analysis> <states> .States </states> </kat>
```

### Sum

Query with large bound to find which step pushed the sum above `32`:

```{.sh .runtests}
krun --directory '../' -cSTRATEGY='step-with skip ; bimc 500 (bexp? s <= 32)' sum.imp
```

```
<kat> <s> #STUCK ~> #bimc-result #false in 40 steps : { while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | s |-> 35 n |-> 5 } </s> <imp> <k> while ( 0 <= n ) { n = n + -1 ; s = s + n ; } </k> <mem> s |-> 35 n |-> 5 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>
```

Show that the returned number is the correct step that an assertion violation happens at:

```{.sh .runtests}
krun --directory '../' -cSTRATEGY='step-with skip ; bimc 40 (bexp? s <= 32)' sum.imp
```

```
<kat> <s> #STUCK ~> #bimc-result #false in 40 steps : { while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | s |-> 35 n |-> 5 } </s> <imp> <k> while ( 0 <= n ) { n = n + -1 ; s = s + n ; } </k> <mem> s |-> 35 n |-> 5 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>
```

And that one step prior the assertion was not violated:

```{.sh .runtests}
krun --directory '../' -cSTRATEGY='step-with skip ; bimc 39 (bexp? s <= 32)' sum.imp
```

```
<kat> <s> #STUCK ~> #bimc-result #true in 39 steps : { s = 35 ; ~> while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | s |-> 30 n |-> 5 } </s> <imp> <k> s = 35 ; ~> while ( 0 <= n ) { n = n + -1 ; s = s + n ; } </k> <mem> s |-> 30 n |-> 5 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>
```

### Collatz

Check if calculating Collatz of 782 ever goes above 10000:

```{.sh .runtests}
krun --directory '../' -cSTRATEG='step-with skip ; bimc 5000 (bexp? n <= 10000)' collatz.imp
```

```
// TODO: Place output here
```

SBC
---

Here, we compile each program into a simpler set of rules specific to that program.

### Straight Line

Straight line programs should yield one rule which summarizes the effect of the entire program on the IMP memory.

`straight-line-1` just has the effect of setting `x` to 15, skipping all intermediate steps.

```{.sh .runtests}
krun --directory '../' -cSTRATEGY='compile' straight-line-1.imp
```

```
<kat> <s> #STUCK ~> #compile-result ( .Rules , < { int x , .Ids ; x = 0 ; x = x + 15 ; | .Map } --> { . | x |-> 15 } > ) </s> <imp> <k> . </k> <mem> x |-> V0 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>
```

`straight-line-2` just has the effect of setting `x` to 5, skipping all intermediate steps.
Note that before setting it to `5`, the original program sets it to 0 and then 15, but the generated program does not have these steps.
Because we are using the operational semantics of the language directly, we get this dead-code elimination practically for free.

```{.sh .runtests}
krun --directory '../' -cSTRATEGY='compile' straight-line-2.imp
```

```
<kat> <s> #STUCK ~> #compile-result ( .Rules , < { int x , .Ids ; x = 0 ; x = x + 15 ; x = x + -10 ; | .Map } --> { . | x |-> 5 } > ) </s> <imp> <k> . </k> <mem> x |-> V0 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>
```

### Dead `if`

Because we are compiling using symbolic execution, we will often know if a branch is dead (only ever evaluates to `true`/`false`).
In the `dead-if` program, the condition on the `if` is always true, so our rule summary only generates a single rule corresponding to the true branch of the `if`.
Once again, because we are using symbolic execution of the operational semantics directly, we get this branch elimination for free.

```{.sh .runtests}
krun --directory '../' -cSTRATEGY='compile' dead-if.imp
```

```
<kat> <s> #STUCK ~> #compile-result ( .Rules , < { int x , .Ids ; x = 7 ; if ( x <= 7 ) { x = 1 ; } else { x = -1 ; } | .Map } --> { . | x |-> 1 } > ) </s> <imp> <k> . </k> <mem> x |-> V0 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>
```

### Sum and Sum Plus

Sum should generate three rules:

1. One rule to get us to the beginning of the `while` loop (initialization).
2. One rule corresponding to an iteration of the `while` loop (if the condition on the loop is true).
3. One rule corresponding to jumping over the `while` loop (if the condition on the loop is false).

```{.sh .runtests}
krun --directory '../' -cSTRATEGY='compile' sum.imp
```

```
<kat> <s> #STUCK ~> #compile-result ( ( ( .Rules , < { int n , ( s , .Ids ) ; n = 10 ; while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | .Map } --> { while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | s |-> 0 n |-> 10 } > ) , < { while ( false ) { n = n + -1 ; s = s + n ; } | s |-> V0 n |-> V1 } --> { . | s |-> V0 n |-> V1 } > ) , < { while ( true ) { n = n + -1 ; s = s + n ; } | s |-> V0 n |-> V1 } --> { while ( true ) { n = n + -1 ; s = s + n ; } | s |-> ( V0 +Int ( V1 +Int -1 ) ) n |-> ( V1 +Int -1 ) } > ) </s> <imp> <k> while ( true ) { n = n + -1 ; s = s + n ; } </k> <mem> s |-> V2 n |-> V3 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>
```

Sum Plus should generate the same rules, but the rule for the false branch of the `while` loop should also include the effect of the code after the `while` loop.

```{.sh .runtests}
krun --directory '../' -cSTRATEGY='compile' sum-plus.imp
```

```
<kat> <s> #STUCK ~> #compile-result ( ( ( .Rules , < { int n , ( s , .Ids ) ; n = 10 ; while ( 0 <= n ) { n = n + -1 ; s = s + n ; } s = s + 300 ; | .Map } --> { ( while ( 0 <= n ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) | s |-> 0 n |-> 10 } > ) , < { ( while ( false ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) | s |-> V0 n |-> V1 } --> { . | s |-> ( V0 +Int 300 ) n |-> V1 } > ) , < { ( while ( true ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) | s |-> V0 n |-> V1 } --> { ( while ( true ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) | s |-> ( V0 +Int ( V1 +Int -1 ) ) n |-> ( V1 +Int -1 ) } > ) </s> <imp> <k> ( while ( true ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) </k> <mem> s |-> V2 n |-> V3 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>
```

### Collatz

Finally, we pick a program that has a conditional inside the `while` loop.
Because the conditional splits execution state, we must use `--search` instead to get all paths.
Indeed, we get a summary of the Collatz program with four rules:

1.  A rule that gets us to the beginning of the `while` loop (initialization).
2.  A rule that has the effect of the `while` loop if the branch inside is true (roughly, "if the number is not 1 and even, divide it by 2").
3.  A rule that has the effect of the `while` loop if the branch inside is false (roughly, "if the number is not 1 and odd, multiply by 3 and add 1").
4.  A rule that gets us past the `while` loop once we reach 1.

Rules 1 and 4 above will be generated in both solutions for `--search`, but rules 2 and 3 are each only generated in one of the solutions.
Note that we effectively get a "summary" of the Collatz algorithm which is independent of how it's written down in IMP.

```{.sh .runtests}
krun --directory '../' --search -cSTRATEGY='compile' collatz.imp
```

```
Solution 1
<kat> <s> #STUCK ~> #compile-result ( ( ( .Rules , < { int n , ( x , .Ids ) ; n = 782 ; x = 0 ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | .Map } --> { while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> 0 n |-> 782 } > ) , < { while ( false ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> V0 n |-> V1 } --> { . | x |-> V0 n |-> V1 } > ) , < { while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> V0 n |-> V1 } --> { while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> ( V0 +Int 1 ) n |-> ( 3 *Int V1 +Int 1 ) } > ) </s> <imp> <k> while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k> <mem> x |-> V2 n |-> V3 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>
Solution 2
<kat> <s> #STUCK ~> #compile-result ( ( ( .Rules , < { int n , ( x , .Ids ) ; n = 782 ; x = 0 ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | .Map } --> { while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> 0 n |-> 782 } > ) , < { while ( false ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> V0 n |-> V1 } --> { . | x |-> V0 n |-> V1 } > ) , < { while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> V0 n |-> V1 } --> { while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> ( V0 +Int 1 ) n |-> ( V1 /Int 2 ) } > ) </s> <imp> <k> while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k> <mem> x |-> V2 n |-> V3 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>
```
