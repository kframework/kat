IMP Exmaples
============

In this file several tests are provided for KAT.
K commit `e14da0a` should be used to kompile the definition and run the examples.
Compile the definition with `kompile --main-module IMP-ANALYSIS --syntax-module IMP-ANALYSIS imp-kat.k`.
Run the tests with `bash runtests.sh` in the `tests` directory.

Straight Line Code
------------------

These programs are "straight-line code" in IMP; they don't have any branching or looping.

### `straight-line-1.imp`

```{.imp .straight-line-1 .k}
int x ;
x = 0 ;
x = x + 15 ;
```

### `straight-line-2.imp`

```{.imp .straight-line-2 .k}
int x ;
x = 0 ;
x = x + 15 ;
x = x + -10 ;
```

Branching
---------

### `dead-if.imp`

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

### `sum.imp`

This is the classic `sum` program, which just sums the numbers from 1 to 10.

```{.imp .sum .k}
int n , s ;

n = 10 ;
while (0 <= n) {
  n = n + -1 ;
  s = s + n ;
}
```

### `sum-plus.imp`

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

### `collatz.imp`

Here the Collatz loop is provided, which calculates how many steps it takes a given number (in this case 782) to go to 1 using Collatz update.

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

IMP-KAT Tests
=============

We'll use a simple testing harness in `bash` which just checks the output of `krun --search` against a supplied file.
Run this with `bash runtests.sh`.

```{.sh .test}
gecho() {
    echo -e '\e[32m'$@'\e[39m'
}
recho() {
    echo -e '\e[31m'$@'\e[39m'
}
strip_output() {
    grep -v -e '^$' -e '^\s*//' | tr '\n' ' ' | tr --squeeze-repeats ' '
}

return_code="0"

test() {
    strategy="$1"
    imp_file="$2"
    out_file="output/$3"
    for file in "$imp_file" "$out_file"; do
        [[ ! -f "$file" ]] && recho "File '$out_file' does not exist ..." && exit 1
    done

    echo -e "Running '$imp_file' with '$strategy' and comparing to '$out_file' ..."
    diff <(cat "$out_file" | strip_output) <(krun --search --directory '../' -cSTRATEGY="$strategy" "$imp_file" | strip_output)
    if [[ "$?" == '0' ]]; then
        gecho "SUCCESS"
    else
        recho "FAILURE"
        return_code="1"
    fi
}
```

BIMC
----

Here, we allow each program to initialize (get through variable declarations) by running `step-with skip`.
Then we issue some `bimc` query to check if the program obeys the given invariant up to the depth-bound.

### Straight Line 1

Assertion not violated at step 2:

```{.sh .test}
test 'step-with skip ; bimc 2 (bexp? x <= 7)' straight-line-1.imp straight-line-1-bimc1.out
```

```{.k .straight-line-1-bimc1}
Solution 1
<kat-imp>
 <s> #STUCK ~> #bimc-result #true in 2 steps </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> x = 15 ; </k>
  <mem> x |-> 0 </mem>
 </imp>
</kat-imp>
```

Assertion violation at step 3:

```{.sh .test}
test 'step-with skip ; bimc 3 (bexp? x <= 7)' straight-line-1.imp straight-line-1-bimc2.out
```

```{.k .straight-line-1-bimc2}
Solution 1
<kat-imp>
  <s> #STUCK ~> #bimc-result #false in 3 steps </s>
  <kat>
   <analysis> .Analysis </analysis>
   <states> .States </states>
  </kat>
  <imp>
   <k> . </k>
   <mem> x |-> 15 </mem>
  </imp>
</kat-imp>
```

### Straight Line 2

Assertion not violated up to step 2:

```{.sh .test}
test 'step-with skip ; bimc 2 (bexp? x <= 7)' straight-line-2.imp straight-line-2-bimc1.out
```

```{.k .straight-line-2-bimc1}
Solution 1
<kat-imp>
 <s> #STUCK ~> #bimc-result #true in 2 steps </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> x = 15 ; ~> ( x = x + -10 ; ) </k>
  <mem> x |-> 0 </mem>
 </imp>
</kat-imp>
```

Assertion violated at step 3:

```{.sh .test}
test 'step-with skip ; bimc 3 (bexp? x <= 7)' straight-line-2.imp straight-line-2-bimc2.out
```

```{.k .straight-line-2-bimc2}
Solution 1
<kat-imp>
 <s> #STUCK ~> #bimc-result #false in 3 steps </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> x ~> #freezer_+_1 ( -10 ) ~> #freezer_=_;0 ( x ) </k>
  <mem> x |-> 15 </mem>
 </imp>
</kat-imp>
```

Assertion still violated at step 3 (with extended bound):

```{.sh .test}
test 'step-with skip ; bimc 500 (bexp? x <= 7)' straight-line-2.imp straight-line-2-bimc3.out
```

```{.k .straight-line-2-bimc3}
Solution 1
<kat-imp>
 <s> #STUCK ~> #bimc-result #false in 3 steps </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> x ~> #freezer_+_1 ( -10 ) ~> #freezer_=_;0 ( x ) </k>
  <mem> x |-> 15 </mem>
 </imp>
</kat-imp>
```

### Sum

Query with large bound to find which step pushed the sum above `32`:

```{.sh .test}
test 'step-with skip ; bimc 500 (bexp? s <= 32)' sum.imp sum-bimc1.out
```

```{.k .sum-bimc1}
Solution 1
<kat-imp>
 <s> #STUCK ~> #bimc-result #false in 41 steps </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> while ( 0 <= n ) { n = n + -1 ; s = s + n ; } </k>
  <mem> s |-> 35 n |-> 5 </mem>
 </imp>
</kat-imp>
```

Show that the returned number is the correct step that an assertion violation happens at:

```{.sh .test}
test 'step-with skip ; bimc 41 (bexp? s <= 32)' sum.imp sum-bimc2.out
```

```{.k .sum-bimc2}
Solution 1
<kat-imp>
 <s> #STUCK ~> #bimc-result #false in 41 steps </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> while ( 0 <= n ) { n = n + -1 ; s = s + n ; } </k>
  <mem> s |-> 35 n |-> 5 </mem>
 </imp>
</kat-imp>
```

And that one step prior the assertion was not violated:

```{.sh .test}
test 'step-with skip ; bimc 40 (bexp? s <= 32)' sum.imp sum-bimc3.out
```

```{.k .sum-bimc3}
Solution 1
<kat-imp>
 <s> #STUCK ~> #bimc-result #true in 40 steps </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> s = 35 ; ~> while ( 0 <= n ) { n = n + -1 ; s = s + n ; } </k>
  <mem> s |-> 30 n |-> 5 </mem>
 </imp>
</kat-imp>
```

### Collatz

Here we test if the Collatz sequence for `782` contains any numbers greater than `1000`.

```{.sh .test}
test 'step-with skip ; bimc 5000 (bexp? n <= 1000)' collatz.imp collatz-bimc.out
```

```{.k .collatz-bimc}
Solution 1
<kat-imp>
 <s> #STUCK ~> #bimc-result #false in 20 steps </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> x ~> #freezer_+_1 ( 1 ) ~> #freezer_=_;0 ( x ) ~> while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k>
  <mem> x |-> 1 n |-> 1174 </mem>
 </imp>
</kat-imp>
```

SBC
---

Here, we compile each program into a simpler set of rules specific to that program.
Compilation must be run with `--search` so that when the state of symbolic execution splits at branch points (eg. `if(_)_else_` in IMP) we collect rules for both branches.

### Straight Line

Straight line programs should yield one rule which summarizes the effect of the entire program on the IMP memory.

`straight-line-1` just has the effect of setting `x` to 15, skipping all intermediate steps.

```{.sh .test}
test 'compile' straight-line-1.imp straight-line-1-sbc.out
```

```{.k .straight-line-1-sbc}
Solution 1
<kat-imp>
 <s> #STUCK ~> #compile-result ( .Rules
                               , < { int x , .Ids ; x = 0 ; x = x + 15 ; | .Map } --> { . | x |-> 15 } >
                               ) </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> . </k>
  <mem> x |-> V0 </mem>
 </imp>
</kat-imp>
```

`straight-line-2` just has the effect of setting `x` to 5, skipping all intermediate steps.
Note that before setting it to `5`, the original program sets it to 0 and then 15, but the generated program does not have these steps.
Because we are using the operational semantics of the language directly, we get this dead-code elimination practically for free.

```{.sh .test}
test 'compile' straight-line-2.imp straight-line-2-sbc.out
```

```{.k .straight-line-2-sbc}
Solution 1
<kat-imp>
 <s> #STUCK ~> #compile-result ( .Rules
                               , < { int x , .Ids ; x = 0 ; x = x + 15 ; x = x + -10 ; | .Map } --> { . | x |-> 5 } >
                               ) </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> . </k>
  <mem> x |-> V0 </mem>
 </imp>
</kat-imp>
```

### Dead `if`

Because we are compiling using symbolic execution, we will often know if a branch is dead (only ever evaluates to `true`/`false`).
In the `dead-if` program, the condition on the `if` is always true, so our rule summary only generates a single rule corresponding to the true branch of the `if`.
Once again, because we are using symbolic execution of the operational semantics directly, we get this branch elimination for free.

```{.sh .test}
test 'compile' dead-if.imp dead-if-sbc.out
```

```{.k .dead-if-sbc}
Solution 1
<kat-imp>
 <s> #STUCK ~> #compile-result ( .Rules
                               , < { int x , .Ids ; x = 7 ; if ( x <= 7 ) { x = 1 ; } else { x = -1 ; } | .Map } --> { . | x |-> 1 } >
                               ) </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> . </k>
  <mem> x |-> V0 </mem>
 </imp>
</kat-imp>
```

### Sum and Sum Plus

Sum should generate three rules:

1. One rule to get us to the beginning of the `while` loop (initialization).
2. One rule corresponding to jumping over the `while` loop (if the condition on the loop is false).
3. One rule corresponding to an iteration of the `while` loop (if the condition on the loop is true).

```{.sh .test}
test 'compile' sum.imp sum-sbc.out
```

```{.k .sum-sbc}
Solution 1
<kat-imp>
 <s> #STUCK ~> #compile-result ( ( ( .Rules

                                     // RULE 1
                                   , < { int n , ( s , .Ids ) ; n = 10 ; while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | .Map } --> { while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | s |-> 0 n |-> 10 } > )

                                     // RULE 2
                                   , < { while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | s |-> V0 n |-> V1 | false }            --> { . | s |-> V0 n |-> V1 } > )

                                     // RULE 3
                                   , < { while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | s |-> V0 n |-> V1 | true }             --> { while ( true ) { n = n + -1 ; s = s + n ; } | s |-> ( V0 +Int ( V1 +Int -1 ) ) n |-> ( V1 +Int -1 ) } >
                                   ) </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> while ( true ) { n = n + -1 ; s = s + n ; } </k>
  <mem> s |-> V2 n |-> V3 </mem>
 </imp>
</kat-imp>
```

Sum Plus should generate the same rules, but the rule for the false branch of the `while` loop should also include the effect of the code after the `while` loop (rule 2').

```{.sh .test}
test 'compile' sum-plus.imp sum-plus-sbc.out
```

```{.k .sum-plus-sbc}
Solution 1
<kat-imp>
 <s> #STUCK ~> #compile-result ( ( ( .Rules

                                     // RULE 1
                                   , < { int n , ( s , .Ids ) ; n = 10 ; while ( 0 <= n ) { n = n + -1 ; s = s + n ; } s = s + 300 ; | .Map } --> { ( while ( 0 <= n ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) | s |-> 0 n |-> 10 } > )

                                     // RULE 2'
                                   , < { ( while ( 0 <= n ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) | s |-> V0 n |-> V1 | false } --> { . | s |-> ( V0 +Int 300 ) n |-> V1 } > )

                                     // RULE 3
                                   , < { ( while ( 0 <= n ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) | s |-> V0 n |-> V1 | true }  --> { ( while ( true ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) | s |-> ( V0 +Int ( V1 +Int -1 ) ) n |-> ( V1 +Int -1 ) } >
                                   ) </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> ( while ( true ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) </k>
  <mem> s |-> V2 n |-> V3 </mem>
 </imp>
</kat-imp>
```

### Collatz

Finally, we pick a program that has a conditional inside the `while` loop.
Indeed, we get a summary of the Collatz program with four rules:

1.  A rule that gets us to the beginning of the `while` loop (initialization).
2.  A rule that gets us past the `while` loop once we reach 1.
3.  A rule that has the effect of the `while` loop if the branch inside is false (roughly, "if the number is not 1 and odd, multiply by 3 and add 1").
4.  A rule that has the effect of the `while` loop if the branch inside is true (roughly, "if the number is not 1 and even, divide it by 2").

Rules 1 and 2 above will be generated in both solutions for `--search`, but rules 3 and 4 are each only generated in one of the solutions.
Note that we effectively get a "summary" of the Collatz algorithm which is independent of how it's written down in IMP.

```{.sh .test}
test 'compile' collatz.imp collatz-sbc.out

exit $return_code
```

```{.k .collatz-sbc}
Solution 1
<kat-imp>
 <s> #STUCK ~> #compile-result ( ( ( .Rules

                                     // RULE 1
                                   , < { int n , ( x , .Ids ) ; n = 782 ; x = 0 ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | .Map } --> { while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> 0 n |-> 782 } > )

                                     // RULE 2
                                   , < { while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> V0 n |-> V1 | false }                     --> { . | x |-> V0 n |-> V1 } > )

                                     // RULE 3
                                   , < { while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> V0 n |-> V1 | true }                      --> { while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> ( V0 +Int 1 ) n |-> ( 3 *Int V1 +Int 1 ) } >
                                   ) </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k>
  <mem> x |-> V2 n |-> V3 </mem>
 </imp>
</kat-imp>

Solution 2
<kat-imp>
 <s> #STUCK ~> #compile-result ( ( ( .Rules

                                     // RULE 1
                                   , < { int n , ( x , .Ids ) ; n = 782 ; x = 0 ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | .Map } --> { while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> 0 n |-> 782 } > )

                                     // RULE 2
                                   , < { while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> V0 n |-> V1 | false }                     --> { . | x |-> V0 n |-> V1 } > )

                                     // RULE 4
                                   , < { while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> V0 n |-> V1 | true }                      --> { while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> ( V0 +Int 1 ) n |-> ( V1 /Int 2 ) } >
                                   ) </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k>
  <mem> x |-> V2 n |-> V3 </mem>
 </imp>
</kat-imp>
```

SBC Benchmarking
----------------

The above `compile` result for Collatz corresponds to the following K definition.
We've replaced the `k` cells with constants, which can be done automatically using hashing but here is done manually.

-   `INIT` corresponds to the entire program: `int n , ( x , .Ids ) ; n = 782 ; x = 0 ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; }`
-   `LOOP` corresponds to just the loop: `while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; }`
-   `FINISH` corresponds to the final state: `.`

```{.k .collatz-compiled}
requires "../../imp-kat.k"

module COLLATZ-COMPILED
  imports IMP-ANALYSIS
  imports MAP
  imports ID

  syntax Stmt ::= "INIT" | "LOOP" | "FINISHED"
  syntax Id ::= "x" | "n"

  rule <imp> <k> INIT => LOOP      </k> <mem> .Map => x |-> 0                 n |-> 782                        </mem> </imp>
  rule <imp> <k> LOOP => FINISHED  </k> <mem>         x |-> V0                n |-> V1                         </mem> </imp> requires notBool (2 <=Int V1)                                         [tag(while)]
  rule <imp> <k> LOOP              </k> <mem>         x |-> (V0 => V0 +Int 1) n |-> (V1 => V1 /Int 2)          </mem> </imp> requires (2 <=Int V1) andBool (V1 <=Int ((V1 /Int 2) *Int 2))         [tag(while)]
  rule <imp> <k> LOOP              </k> <mem>         x |-> (V0 => V0 +Int 1) n |-> (V1 => (3 *Int V1) +Int 1) </mem> </imp> requires (2 <=Int V1) andBool notBool (V1 <=Int ((V1 /Int 2) *Int 2)) [tag(while)]
endmodule
```

### Concrete Execution Time

First we'll demonstrate that execution time decreases drastically by running `collatz.imp` with the original semantics, and running `INIT` with the new semantics.
Note that in both cases this is not as fast as an actual compiled definition could be because we're still using the strategy harness to control execution (which introduces overhead).

```{.sh .benchmark-collatz}
echo "Timing IMP Collatz concrete ..."
time krun --directory '../' -cSTRATEGY='step until stuck?' collatz.imp
echo "Timing Compiled Collatz concrete ..."
time krun --directory 'collatz-compiled/' -cSTRATEGY='step until stuck?' -cPGM='INIT'
```

### BIMC Execution Time

In addition to concrete execution speedup, we get a speedup in the other analysis tools that can be run after SBC.
Here we'll check the runtime of BIMC for the Collatz program, then compare to the time of BIMC of the system generated by SBC.

To do this, we'll find the highest number that is reached on Collatz of 782 by incrementally increasing the maximum bound we check for as an invariant.

```{.sh .benchmark-collatz}
for bound in 1000 1174 1762 2644 3238 4858 7288 9323; do
    echo
    echo "Timing Collatz bimc with bound '$bound' ..."
    echo "Using concrete execution ..."
    time krun --directory '../' -cSTRATEGY='step-with skip ; bimc 5000 (bexp? n <= '"$bound"')' collatz.imp

    echo "Using compiled execution ..."
    time krun --directory 'collatz-compiled/' -cSTRATEGY='step-with skip ; bimc 5000 (bexp? n <= '"$bound"')' -cPGM='INIT'
done
```

The first number is the `bound` on how high we'll let Collatz go.
The second number is the number of steps it took to get there.
The third number is how long it took to run on my laptop on a Sunday.

1.  1000 at 20 steps in 19s
2.  1174 at 40 steps in 22s
3.  1762 at 60 steps in ??s
4.  2644 at 730 steps in 2m34s
5.  3238 at 750 steps in 3m07s
6.  4858 at 770 steps in 3m44s
7.  7288 at 870 steps in 9m01s
8.  9232 at ??? steps in ?m??s

```
Timing IMP Collatz concrete ...
<kat-imp> <s> #STUCK </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> . </k> <mem> x |-> 121 n |-> 1 </mem> </imp> </kat-imp>

real	0m37.876s
user	1m1.012s
sys	0m1.138s
Timing Compiled Collatz concrete ...
<kat-imp> <s> #STUCK </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> FINISHED </k> <mem> n |-> 1 x |-> 121 </mem> </imp> </kat-imp>

real	0m11.371s
user	0m34.304s
sys	0m1.445s

Timing Collatz bimc with bound '1000' ...
Using concrete execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 20 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> x ~> #freezer_+_1 ( 1 ) ~> #freezer_=_;0 ( x ) ~> while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k> <mem> x |-> 1 n |-> 1174 </mem> </imp> </kat-imp>

real	0m9.133s
user	0m31.784s
sys	0m1.050s
Using compiled execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 2 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> LOOP </k> <mem> n |-> 1174 x |-> 2 </mem> </imp> </kat-imp>

real	0m9.014s
user	0m27.511s
sys	0m1.199s

Timing Collatz bimc with bound '1174' ...
Using concrete execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 40 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> x ~> #freezer_+_1 ( 1 ) ~> #freezer_=_;0 ( x ) ~> while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k> <mem> x |-> 3 n |-> 1762 </mem> </imp> </kat-imp>

real	0m10.398s
user	0m35.278s
sys	0m1.103s
Using compiled execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 4 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> LOOP </k> <mem> n |-> 1762 x |-> 4 </mem> </imp> </kat-imp>

real	0m8.945s
user	0m27.801s
sys	0m1.158s

Timing Collatz bimc with bound '1762' ...
Using concrete execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 60 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> x ~> #freezer_+_1 ( 1 ) ~> #freezer_=_;0 ( x ) ~> while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k> <mem> x |-> 5 n |-> 2644 </mem> </imp> </kat-imp>

real	0m11.679s
user	0m36.563s
sys	0m1.149s
Using compiled execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 6 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> LOOP </k> <mem> n |-> 2644 x |-> 6 </mem> </imp> </kat-imp>

real	0m9.642s
user	0m29.451s
sys	0m1.334s

Timing Collatz bimc with bound '2644' ...
Using concrete execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 730 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> x ~> #freezer_+_1 ( 1 ) ~> #freezer_=_;0 ( x ) ~> while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k> <mem> x |-> 72 n |-> 3238 </mem> </imp> </kat-imp>

real	0m50.636s
user	1m16.623s
sys	0m1.227s
Using compiled execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 73 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> LOOP </k> <mem> n |-> 3238 x |-> 73 </mem> </imp> </kat-imp>

real	0m12.544s
user	0m35.295s
sys	0m1.246s

Timing Collatz bimc with bound '3238' ...
Using concrete execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 750 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> x ~> #freezer_+_1 ( 1 ) ~> #freezer_=_;0 ( x ) ~> while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k> <mem> x |-> 74 n |-> 4858 </mem> </imp> </kat-imp>

real	0m51.281s
user	1m18.253s
sys	0m1.247s
Using compiled execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 75 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> LOOP </k> <mem> n |-> 4858 x |-> 75 </mem> </imp> </kat-imp>

real	0m13.276s
user	0m36.625s
sys	0m1.329s

Timing Collatz bimc with bound '4858' ...
Using concrete execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 770 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> x ~> #freezer_+_1 ( 1 ) ~> #freezer_=_;0 ( x ) ~> while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k> <mem> x |-> 76 n |-> 7288 </mem> </imp> </kat-imp>

real	0m59.565s
user	1m26.290s
sys	0m1.430s
Using compiled execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 77 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> LOOP </k> <mem> n |-> 7288 x |-> 77 </mem> </imp> </kat-imp>

real	0m13.196s
user	0m37.080s
sys	0m1.261s

Timing Collatz bimc with bound '7288' ...
Using concrete execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 870 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> x ~> #freezer_+_1 ( 1 ) ~> #freezer_=_;0 ( x ) ~> while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k> <mem> x |-> 86 n |-> 9232 </mem> </imp> </kat-imp>

real	0m57.226s
user	1m22.112s
sys	0m1.243s
Using compiled execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #false in 87 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> LOOP </k> <mem> n |-> 9232 x |-> 87 </mem> </imp> </kat-imp>

real	0m13.633s
user	0m37.092s
sys	0m1.277s

Timing Collatz bimc with bound '9323' ...
Using concrete execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #true in 1215 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> . </k> <mem> x |-> 121 n |-> 1 </mem> </imp> </kat-imp>

real	1m26.480s
user	1m55.728s
sys	0m1.700s
Using compiled execution ...
<kat-imp> <s> #STUCK ~> #bimc-result #true in 122 steps </s> <kat> <analysis> .Analysis </analysis> <states> .States </states> </kat> <imp> <k> FINISHED </k> <mem> n |-> 1 x |-> 121 </mem> </imp> </kat-imp>

real	0m15.696s
user	0m39.400s
sys	0m1.289s
```
