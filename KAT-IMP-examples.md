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

### `collatz-all.imp`

Like `collatz`, though in this case calculates how many steps it takes for all numbers up to a given number (in this case 10) to go to 1 using Collatz update.

```{.imp .collatz-all .k}
int b , n , x ;

b = 1 ;
n = 1 ;
x = 0 ;

while (b <= 10) {
  n = b ;
  while (2 <= n) {
    if (n <= ((n / 2) * 2)) {
      n = n / 2 ;
    } else {
      n = (3 * n) + 1 ;
    }
    x = x + 1 ;
  }
  b = b + 1 ;
}
```

### `krazy-loop.imp`

```{.imp .krazy-loop-correct .k}
int i , j , k , l , m , s ;

i = 11 ;
j = 11 ;
k = 0 ;
l = 0 ;
m = 0 ;
s = 0 ;

while (0 < i) {
  k = 0 ;
  j = 11 ;
  while (0 <= j) {
    l = (3 * j) - (j + i) ;
    m = (5 * i) + 1 ;
    if (i <= ((i / 2) * 2)) {
      k = k + (l / i) ;
    } else {
      k = k + (j / m) ;
    }
    j = j - 1 ;
  }
  s = s + ((i * k) / 3) ;
  i = i - 1 ;
}
```

```{.imp .krazy-loop-incorrect .k}
int i , j , k , l , m , s ;

i = 11 ;
j = 11 ;
k = 0 ;
l = 0 ;
m = 0 ;
s = 0 ;

while (0 <= i) {
  k = 0 ;
  j = 11 ;
  while (0 <= j) {
    l = (3 * j) - (j + i) ;
    m = (5 * i) + 1 ;
    if (i <= ((i / 2) * 2)) {
      k = k + (l / i) ;
    } else {
      k = k + (j / m) ;
    }
    j = j - 1 ;
  }
  s = s + ((i * k) / 3) ;
  i = i - 1 ;
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
    grep -v -e '^$' -e '^\s*//' | tr '\n' ' ' | tr -s ' '
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

### Collatz All

```{.sh .test}
test 'step-with skip ; bimc 5000 (bexp? n <= 1000)' collatz-all.imp collatz-all-bimc.out
```

```{.k .collatz-all-bimc}
Solution 1
<kat-imp>
 <s> #STUCK ~> #bimc-result #true in 776 steps </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> . </k>
  <mem> x |-> 67 b |-> 11 n |-> 1 </mem>
 </imp>
</kat-imp>
```

### Krazy Loop

```{.sh .test}
test 'bimc 5000 (not div-zero-error?)' krazy-loop-correct krazy-loop-correct-bimc.out
```

```{.k .krazy-loop-correct-bimc}
Solution 1
<kat-imp>
 <s> #STUCK ~> #bimc-result #true in 1367 steps </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> . </k>
  <mem> l |-> -1 k |-> 4 s |-> 46 j |-> -1 i |-> 0 m |-> 6 </mem>
 </imp>
</kat-imp>
```

```{.sh .test}
test 'bimc 5000 (not div-zero-error?)' krazy-loop-incorrect krazy-loop-incorrect-bimc1.out
```

```{.k .krazy-loop-incorrect-bimc1}
Solution 1
<kat-imp>
 <s> #STUCK ~> #bimc-result #false in 1385 steps </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> div-zero-error </k>
  <mem> l |-> 18 k |-> 0 s |-> 46 j |-> 9 i |-> 0 m |-> 1 </mem>
 </imp>
</kat-imp>
```

```{.sh .test}
test 'bimc 1384 (not div-zero-error?)' krazy-loop-incorrect krazy-loop-incorrect-bimc2.out
```

```{.k .krazy-loop-incorrect-bimc2}
Solution 1
<kat-imp>
 <s> #STUCK ~> #bimc-result #true in 1384 steps </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> ( 18 / 0 ) ~> #freezer_+_0 ( 0 ) ~> #freezer_=_;0 ( k ) ~> ( j = j - 1 ; ) ~> ( while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( 0 <= i ) { k = 0 ; j = 9 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } </k>
  <mem> l |-> 18 k |-> 0 s |-> 46 j |-> 9 i |-> 0 m |-> 1 </mem>
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

### Collatz All

```{.sh .test}
test 'compile' collatz-all.imp collatz-all-sbc.out
```

```{.k .collatz-all-sbc}
Solution 1
<kat-imp>
 <s> #STUCK ~> #compile-result ( ( ( ( ( .Rules
                                       , < { int b , ( n , ( x , .Ids ) ) ; b = 1 ; n = 1 ; x = 0 ; while ( b <= 10 ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | .Map }                                                                                                       --> { while ( b <= 10 ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> 0 b |-> 1 n |-> 1 } > )
                                       , < { while ( b <= 10 ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> V0 b |-> V1 n |-> V2 | false }                                                                                                                                --> { . | x |-> V0 b |-> V1 n |-> V2 } > )
                                       , < { while ( b <= 10 ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> V0 b |-> V1 n |-> V2 | true }                                                                                                                                 --> { ( while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } ) ~> ( b = b + 1 ; ) ~> while ( true ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> V0 b |-> V1 n |-> V1 } > )
                                       , < { ( while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } ) ~> ( b = b + 1 ; ) ~> while ( true ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> V3 b |-> V4 n |-> V5 | false } --> { while ( true ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> V3 b |-> ( V4 +Int 1 ) n |-> V5 } > )
                                       , < { ( while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } ) ~> ( b = b + 1 ; ) ~> while ( true ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> V3 b |-> V4 n |-> V5 | true }  --> { ( while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } ) ~> ( b = b + 1 ; ) ~> while ( true ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> ( V3 +Int 1 ) b |-> V4 n |-> ( 3 *Int V5 +Int 1 ) } >
                                       ) </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> ( while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } ) ~> ( b = b + 1 ; ) ~> while ( true ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } </k>
  <mem> x |-> V6 b |-> V7 n |-> V8 </mem>
 </imp>
</kat-imp>

Solution 2
<kat-imp>
 <s> #STUCK ~> #compile-result ( ( ( ( ( .Rules
                                       , < { int b , ( n , ( x , .Ids ) ) ; b = 1 ; n = 1 ; x = 0 ; while ( b <= 10 ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | .Map }                                                                                                       --> { while ( b <= 10 ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> 0 b |-> 1 n |-> 1 } > )
                                       , < { while ( b <= 10 ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> V0 b |-> V1 n |-> V2 | false }                                                                                                                                --> { . | x |-> V0 b |-> V1 n |-> V2 } > )
                                       , < { while ( b <= 10 ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> V0 b |-> V1 n |-> V2 | true }                                                                                                                                 --> { ( while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } ) ~> ( b = b + 1 ; ) ~> while ( true ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> V0 b |-> V1 n |-> V1 } > )
                                       , < { ( while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } ) ~> ( b = b + 1 ; ) ~> while ( true ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> V3 b |-> V4 n |-> V5 | false } --> { while ( true ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> V3 b |-> ( V4 +Int 1 ) n |-> V5 } > )
                                       , < { ( while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } ) ~> ( b = b + 1 ; ) ~> while ( true ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> V3 b |-> V4 n |-> V5 | true }  --> { ( while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } ) ~> ( b = b + 1 ; ) ~> while ( true ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } | x |-> ( V3 +Int 1 ) b |-> V4 n |-> ( V5 /Int 2 ) } >
                                       ) </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> ( while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } ) ~> ( b = b + 1 ; ) ~> while ( true ) { n = b ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } b = b + 1 ; } </k>
  <mem> x |-> V6 b |-> V7 n |-> V8 </mem>
 </imp>
</kat-imp>
```

### Krazy Loop

```{.sh .test}
test 'compile' krazy-loop-incorrect.imp krazy-loop-incorrect-sbc.out

exit $return_code
```

```{.k .krazy-loop-incorrect-sbc}
Solution 1
<kat-imp>
 <s> #STUCK ~> #compile-result ( ( ( ( ( .Rules
                                       , < { int i , ( j , ( k , ( l , ( m , ( s , .Ids ) ) ) ) ) ; i = 11 ; j = 11 ; k = 0 ; l = 0 ; m = 0 ; s = 0 ; while ( 0 <= i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | .Map }                                                                                                                                                                            --> { while ( 0 <= i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> 0 s |-> 0 k |-> 0 j |-> 9 i |-> 7 m |-> 0 } > )
                                       , < { while ( 0 <= i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V0 k |-> V1 j |-> V2 i |-> V3 s |-> V4 m |-> V5 | false }                                                                                                                                                                                                                          --> { . | l |-> V0 k |-> V1 j |-> V2 i |-> V3 s |-> V4 m |-> V5 } > )
                                       , < { while ( 0 <= i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V0 k |-> V1 j |-> V2 i |-> V3 s |-> V4 m |-> V5 | true }                                                                                                                                                                                                                           --> { ( while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V0 k |-> 0 j |-> 9 i |-> V3 s |-> V4 m |-> V5 } > )
                                       , < { ( while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V6 k |-> V7 j |-> V8 i |-> V9 s |-> V10 m |-> V11 | false } --> { while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V6 k |-> V7 j |-> V8 i |-> ( V9 -Int 1 ) s |-> ( V10 +Int V9 *Int V7 /Int 3 ) m |-> V11 } > )
                                       , < { ( while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V6 k |-> V7 j |-> V8 i |-> V9 s |-> V10 m |-> V11 | true }  --> { ( while ( true ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> ( 3 *Int V8 -Int ( V8 +Int V9 ) ) k |-> ( V7 +Int V8 /Int ( 5 *Int V9 +Int 1 ) ) j |-> ( V8 -Int 1 ) i |-> V9 s |-> V10 m |-> ( 5 *Int V9 +Int 1 ) } >
                                       ) </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> ( while ( true ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } </k>
  <mem> l |-> V12 k |-> V13 j |-> V14 i |-> V15 s |-> V16 m |-> V17 </mem>
 </imp>
</kat-imp>

Solution 2
<kat-imp>
 <s> #STUCK ~> #compile-result ( ( ( ( ( .Rules
                                       , < { int i , ( j , ( k , ( l , ( m , ( s , .Ids ) ) ) ) ) ; i = 11 ; j = 11 ; k = 0 ; l = 0 ; m = 0 ; s = 0 ; while ( 0 <= i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | .Map }                                                                                                                                                                            --> { while ( 0 <= i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> 0 s |-> 0 k |-> 0 j |-> 9 i |-> 7 m |-> 0 } > )
                                       , < { while ( 0 <= i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V0 k |-> V1 j |-> V2 i |-> V3 s |-> V4 m |-> V5 | false }                                                                                                                                                                                                                          --> { . | l |-> V0 k |-> V1 j |-> V2 i |-> V3 s |-> V4 m |-> V5 } > )
                                       , < { while ( 0 <= i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V0 k |-> V1 j |-> V2 i |-> V3 s |-> V4 m |-> V5 | true }                                                                                                                                                                                                                           --> { ( while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V0 k |-> 0 j |-> 9 i |-> V3 s |-> V4 m |-> V5 } > )
                                       , < { ( while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V6 k |-> V7 j |-> V8 i |-> V9 s |-> V10 m |-> V11 | false } --> { while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V6 k |-> V7 j |-> V8 i |-> ( V9 -Int 1 ) s |-> ( V10 +Int V9 *Int V7 /Int 3 ) m |-> V11 } > )
                                       , < { ( while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V6 k |-> V7 j |-> V8 i |-> V9 s |-> V10 m |-> V11 | true }  --> { ( while ( true ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> ( 3 *Int V8 -Int ( V8 +Int V9 ) ) k |-> ( V7 +Int ( 3 *Int V8 -Int ( V8 +Int V9 ) ) /Int V9 ) j |-> ( V8 -Int 1 ) i |-> V9 s |-> V10 m |-> ( 5 *Int V9 +Int 1 ) } >
                                       ) </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> ( while ( true ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } </k>
  <mem> l |-> V12 k |-> V13 j |-> V14 i |-> V15 s |-> V16 m |-> V17 </mem>
 </imp>
</kat-imp>
```

```{.sh .test}
test 'compile' krazy-loop-correct.imp krazy-loop-correct-sbc.out
```

```{.k .krazy-loop-correct-sbc}
Solution 1
<kat-imp>
 <s> #STUCK ~> #compile-result ( ( ( ( ( .Rules
                                       , < { int i , ( j , ( k , ( l , ( m , ( s , .Ids ) ) ) ) ) ; i = 11 ; j = 11 ; k = 0 ; l = 0 ; m = 0 ; s = 0 ; while ( 0 < i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | .Map }                                                                                                                                                                             --> { while ( 0 < i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> 0 s |-> 0 k |-> 0 j |-> 9 i |-> 7 m |-> 0 } > )
                                       , < { while ( 0 < i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V0 k |-> V1 j |-> V2 i |-> V3 s |-> V4 m |-> V5 | false }                                                                                                                                                                                                                           --> { . | l |-> V0 k |-> V1 j |-> V2 i |-> V3 s |-> V4 m |-> V5 } > )
                                       , < { while ( 0 < i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V0 k |-> V1 j |-> V2 i |-> V3 s |-> V4 m |-> V5 | true }                                                                                                                                                                                                                            --> { ( while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V0 k |-> 0 j |-> 9 i |-> V3 s |-> V4 m |-> V5 } > )
                                       , < { ( while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V6 k |-> V7 j |-> V8 i |-> V9 s |-> V10 m |-> V11 | false } --> { while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V6 k |-> V7 j |-> V8 i |-> ( V9 -Int 1 ) s |-> ( V10 +Int V9 *Int V7 /Int 3 ) m |-> V11 } > )
                                       , < { ( while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V6 k |-> V7 j |-> V8 i |-> V9 s |-> V10 m |-> V11 | true }  --> { ( while ( true ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> ( 3 *Int V8 -Int ( V8 +Int V9 ) ) k |-> ( V7 +Int V8 /Int ( 5 *Int V9 +Int 1 ) ) j |-> ( V8 -Int 1 ) i |-> V9 s |-> V10 m |-> ( 5 *Int V9 +Int 1 ) } >
                                       ) </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> ( while ( true ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } </k>
  <mem> l |-> V12 k |-> V13 j |-> V14 i |-> V15 s |-> V16 m |-> V17 </mem>
 </imp>
</kat-imp>

Solution 2
<kat-imp>
 <s> #STUCK ~> #compile-result ( ( ( ( ( .Rules
                                       , < { int i , ( j , ( k , ( l , ( m , ( s , .Ids ) ) ) ) ) ; i = 11 ; j = 11 ; k = 0 ; l = 0 ; m = 0 ; s = 0 ; while ( 0 < i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | .Map }                                                                                                                                                                             --> { while ( 0 < i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> 0 s |-> 0 k |-> 0 j |-> 9 i |-> 7 m |-> 0 } > )
                                       , < { while ( 0 < i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V0 k |-> V1 j |-> V2 i |-> V3 s |-> V4 m |-> V5 | false }                                                                                                                                                                                                                           --> { . | l |-> V0 k |-> V1 j |-> V2 i |-> V3 s |-> V4 m |-> V5 } > )
                                       , < { while ( 0 < i ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V0 k |-> V1 j |-> V2 i |-> V3 s |-> V4 m |-> V5 | true }                                                                                                                                                                                                                            --> { ( while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V0 k |-> 0 j |-> 9 i |-> V3 s |-> V4 m |-> V5 } > )
                                       , < { ( while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V6 k |-> V7 j |-> V8 i |-> V9 s |-> V10 m |-> V11 | false } --> { while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V6 k |-> V7 j |-> V8 i |-> ( V9 -Int 1 ) s |-> ( V10 +Int V9 *Int V7 /Int 3 ) m |-> V11 } > )
                                       , < { ( while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> V6 k |-> V7 j |-> V8 i |-> V9 s |-> V10 m |-> V11 | true }  --> { ( while ( true ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } | l |-> ( 3 *Int V8 -Int ( V8 +Int V9 ) ) k |-> ( V7 +Int ( 3 *Int V8 -Int ( V8 +Int V9 ) ) /Int V9 ) j |-> ( V8 -Int 1 ) i |-> V9 s |-> V10 m |-> ( 5 *Int V9 +Int 1 ) } >
                                       ) </s>
 <kat>
  <analysis> .Analysis </analysis>
  <states> .States </states>
 </kat>
 <imp>
  <k> ( while ( true ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } ) ~> ( s = s + ( ( i * k ) / 3 ) ; ) ~> ( i = i - 1 ; ) ~> while ( true ) { k = 0 ; j = 11 ; while ( 0 <= j ) { l = 3 * j - ( j + i ) ; m = 5 * i + 1 ; if ( i <= ( ( i / 2 ) * 2 ) ) { k = k + ( l / i ) ; } else { k = k + ( j / m ) ; } j = j - 1 ; } s = s + ( ( i * k ) / 3 ) ; i = i - 1 ; } </k>
  <mem> l |-> V12 k |-> V13 j |-> V14 i |-> V15 s |-> V16 m |-> V17 </mem>
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

  syntax Stmt ::= "INIT" | "LOOP" | "FINISH"
  syntax Id ::= "x" | "n"

  rule <imp> <k> INIT => LOOP   </k> <mem> .Map => x |-> 0                 n |-> 782                        </mem> </imp>
  rule <imp> <k> LOOP => FINISH </k> <mem>         x |-> V0                n |-> V1                         </mem> </imp> requires notBool (2 <=Int V1)                                         [tag(while)]
  rule <imp> <k> LOOP           </k> <mem>         x |-> (V0 => V0 +Int 1) n |-> (V1 => V1 /Int 2)          </mem> </imp> requires (2 <=Int V1) andBool (V1 <=Int ((V1 /Int 2) *Int 2))         [tag(while)]
  rule <imp> <k> LOOP           </k> <mem>         x |-> (V0 => V0 +Int 1) n |-> (V1 => (3 *Int V1) +Int 1) </mem> </imp> requires (2 <=Int V1) andBool notBool (V1 <=Int ((V1 /Int 2) *Int 2)) [tag(while)]
endmodule
```

Here is the compiled version of Collatz all, which checks every Collatz number up to 10.

-   `INIT` corresponds to the entire program.
-   `OUTER` corresponds to the program starting at the outer `while` loop.
-   `INNER` corresponds to the program starting at the inner `while` loop.
-   `FINISHED` corresponds to the completed program.

```{.k .collatz-all-compiled}
requires "../../imp-kat.k"

module COLLATZ-ALL-COMPILED
  imports IMP-ANALYSIS
  imports MAP

  syntax Stmt ::= "INIT" | "OUTER" | "INNER" | "FINISH"
  syntax Id ::= "x" | "b" | "n"

  rule <imp> <k> INIT  => OUTER  </k> <mem> .Map => x |-> 0                 b |-> 1                 n |-> 1                          </mem> </imp>
  rule <imp> <k> OUTER => FINISH </k> <mem>         x |-> V0                b |-> V1                n |-> V2                         </mem> </imp> requires notBool (V1 <=Int 10)
  rule <imp> <k> OUTER => INNER  </k> <mem>         x |-> V0                b |-> V1                n |-> (V2 => V1)                 </mem> </imp> requires (V1 <=Int 10)
  rule <imp> <k> INNER => OUTER  </k> <mem>         x |-> V0                b |-> (V1 => V1 +Int 1) n |-> V2                         </mem> </imp> requires notBool (2 <=Int V2)
  rule <imp> <k> INNER           </k> <mem>         x |-> (V0 => V0 +Int 1) b |-> V1                n |-> (V2 => (3 *Int V2) +Int 1) </mem> </imp> requires (2 <=Int V2) andBool notBool (V2 <=Int ((V2 /Int 2) *Int 2))
  rule <imp> <k> INNER           </k> <mem>         x |-> (V0 => V0 +Int 1) b |-> V1                n |-> (V2 => V2 /Int 2)          </mem> </imp> requires (2 <=Int V2) andBool (V2 <=Int ((V2 /Int 2) *Int 2))
endmodule
```

```{.k .krazy-loop-incorrect-compiled}
requires "../../imp-kat.k"

module KRAZY-LOOP-INCORRECT-COMPILED
  imports IMP-ANALYSIS
  imports MAP

  syntax Stmt ::= "INIT" | "OUTER" | "INNER" | "FINISH"
  syntax Id ::= "i" | "j" | "k" | "l" | "m" | "s"

  rule <imp> <k> INIT  => OUTER  </k> <mem> .Map => i |-> 11                j |-> 11                k |-> 0                                                     l |-> 0                                   m |-> 0                        s |-> 0                           </mem> </imp>
  rule <imp> <k> OUTER => FINISH </k> <mem>         i |-> V0                j |-> V1                k |-> V2                                                    l |-> V3                                  m |-> V4                       s |-> V5                          </mem> </imp> requires notBool (0 <=Int V0)
  rule <imp> <k> OUTER => INNER  </k> <mem>         i |-> V0                j |-> (V1 => 11)        k |-> (V2 => 0)                                             l |-> V3                                  m |-> V4                       s |-> V5                          </mem> </imp> requires (0 <=Int V0)
  rule <imp> <k> INNER => OUTER  </k> <mem>         i |-> (V0 => V0 -Int 1) j |-> V1                k |-> V2                                                    l |-> V3                                  m |-> V4                       s |-> (V5 +Int V0 *Int V2 /Int 3) </mem> </imp> requires notBool (0 <=Int V1)
  rule <imp> <k> INNER           </k> <mem>         i |-> V0                j |-> (V1 => V1 -Int 1) k |-> (V2 => V2 +Int V1 /Int (5 *Int V0 +Int 1))            l |-> (V3 => 3 *Int V1 -Int (V1 +Int V0)) m |-> (V4 => 5 *Int V0 +Int 1) s |-> V5                          </mem> </imp> requires (0 <=Int V1) andBool notBool (V0 <=Int (V0 /Int 2) *Int 2)
  rule <imp> <k> INNER           </k> <mem>         i |-> V0                j |-> (V1 => V1 -Int 1) k |-> (V2 => V2 +Int (3 *Int V1 -Int (V1 +Int V0)) /Int V0) l |-> (V3 => 3 *Int V1 -Int (V1 +Int V0)) m |-> (V4 => 5 *Int V0 +Int 1) s |-> V5                          </mem> </imp> requires (0 <=Int V1) andBool (V0 <=Int (V0 /Int 2) *Int 2)
endmodule
```

### Concrete Execution Time

First we'll demonstrate that execution time decreases drastically by running `collatz.imp` with the original semantics, and running `INIT` with the new semantics.
Note that in both cases this is not as fast as an actual compiled definition could be because we're still using the strategy harness to control execution (which introduces overhead).

```{.sh .benchmark-collatz}
echo "Timing IMP Collatz concrete ..."
krun --directory '../' -cSTRATEGY='step until stuck?' collatz.imp
echo "Timing Compiled Collatz concrete ..."
krun --directory 'collatz-compiled/' -cSTRATEGY='step until stuck?' -cPGM='INIT'
```

And we also are timing the `collatz-all` program concretely:

```{.sh .benchmark-collatz-all}
echo "Timing IMP Collatz All concrete ..."
krun --directory '../' -cSTRATEGY='step until stuck?' collatz-all.imp
echo "Timing Compiled Collatz All concrete ..."
krun --directory 'collatz-all-compiled/' -cSTRATEGY='step until stuck?' -cPGM='INIT'
```

| program     | concrete (ms) | compiled (ms) |
|-------------|---------------|---------------|
| collatz     | 31952         | 2782          |
| collatz-all |               |               |

### BIMC Execution Time

In addition to concrete execution speedup, we get a speedup in the other analysis tools that can be run after SBC.
Here we'll check the runtime of BIMC for the Collatz program, then compare to the time of BIMC of the system generated by SBC.

To do this, we'll find the highest number that is reached on Collatz of 782 by incrementally increasing the maximum bound we check for as an invariant.

```{.sh .benchmark-collatz}
for bound in 1000 1174 1762 2644 3238 4858 7288 9323; do
    echo
    echo "Timing Collatz bimc with bound '$bound' ..."
    echo "Using concrete execution ..."
    krun --directory '../' -cSTRATEGY='step-with skip ; bimc 5000 (bexp? n <= '"$bound"')' collatz.imp

    echo "Using compiled execution ..."
    krun --directory 'collatz-compiled/' -cSTRATEGY='step-with skip ; bimc 5000 (bexp? n <= '"$bound"')' -cPGM='INIT'
done
```

The first number is the `bound` on how high we'll let Collatz go.
The second number is the number of steps it took to get there.
The third number is how long it took to run on my laptop on a Sunday.

| bound | concrete (ms) | compiled (ms) | speedup |
|-------|---------------|---------------|---------|
| 1000  | 2154          | 596           | 3.61    |
| 1174  | 3378          | 818           | 4.13    |
| 1762  | 4497          | 966           | 4.66    |
| 2644  | 43825         | 4673          | 9.78    |
| 3238  | 45397         | 4521          | 10.04   |
| 4858  | 44939         | 4707          | 9.55    |
| 7288  | 53164         | 5209          | 10.21   |
| 9323  | 71187         | 6851          | 10.39   |

```{.sh .benchmark-collatz-all}
for bound in 20 40 60 80 100 150 200; do
    echo
    echo "Timing Collatz all bimc with bound '$bound' ..."
    echo "Using concrete execution ..."
    krun --directory '../' -cSTRATEGY='step-with skip ; bimc 5000 (bexp? n <= '"$bound"')' collatz-all.imp

    echo "Using compiled execution ..."
    krun --directory 'collatz-all-compiled/' -cSTRATEGY='step-with skip ; bimc 5000 (bexp? n <= '"$bound"')' -cPGM='INIT'
done
```

```{.sh .benchmark-krazy-loop-incorrect}
echo
echo "Timing krazy-loop-incorrect ..."
echo "Using concrete execution ..."
krun --directory '../' -cSTRATEGY='bimc 5000 (not div-zero-error?)' krazy-loop-incorrect.imp
echo "Using compiled execution ..."
krun --directory 'krazy-loop-incorrect-compiled/' -cSTRATEGY='bimc 5000 (not div-zero-error?)' -cPGM='INIT'
```
