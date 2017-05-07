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

Here we check the property `x <= 7` for 5 steps of execution after the code has initialized (the `step` in front of the command).
Run this with `krun --search bimc.imp`.

```
$> krun -cSTRATEGY='step-with skip ; bimc 3 (bexp? x <= 7)' straight-line-1.imp
<kat> <s> #STUCK ~> #bimc-result #false </s> <imp> <k> . </k> <mem> x |-> 15 </mem> </imp> <analysis> ( ( ( .Trace ; { x = 0 ; ~> ( x = x + 15 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( 15 ) ~> #freezer_=_;0 ( x ) | x |-> 0 } ) ; { x = 15 ; | x |-> 0 } ) ; { . | x |-> 15 } </analysis> <states> .States </states> </kat>

$> krun -cSTRATEGY='step-with skip ; bimc 2 (bexp? x <= 7)' straight-line-1.imp
<kat> <s> #STUCK ~> #bimc-result #true </s> <imp> <k> x = 15 ; </k> <mem> x |-> 0 </mem> </imp> <analysis> ( ( .Trace ; { x = 0 ; ~> ( x = x + 15 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( 15 ) ~> #freezer_=_;0 ( x ) | x |-> 0 } ) ; { x = 15 ; | x |-> 0 } </analysis> <states> .States </states> </kat>

$> krun -cSTRATEGY='step-with skip ; bimc 2 (bexp? x <= 7)' straight-line-2.imp
<kat> <s> #STUCK ~> #bimc-result #true </s> <imp> <k> x = 15 ; ~> ( x = x + -10 ; ) </k> <mem> x |-> 0 </mem> </imp> <analysis> ( ( .Trace ; { x = 0 ; ~> ( x = x + 15 ; ) ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( 15 ) ~> #freezer_=_;0 ( x ) ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x = 15 ; ~> ( x = x + -10 ; ) | x |-> 0 } </analysis> <states> .States </states> </kat>

$> krun -cSTRATEGY='step-with skip ; bimc 3 (bexp? x <= 7)' straight-line-2.imp
<kat> <s> #STUCK ~> #bimc-result #false </s> <imp> <k> x ~> #freezer_+_1 ( -10 ) ~> #freezer_=_;0 ( x ) </k> <mem> x |-> 15 </mem> </imp> <analysis> ( ( ( .Trace ; { x = 0 ; ~> ( x = x + 15 ; ) ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( 15 ) ~> #freezer_=_;0 ( x ) ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x = 15 ; ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( -10 ) ~> #freezer_=_;0 ( x ) | x |-> 15 } </analysis> <states> .States </states> </kat>

$> krun -cSTRATEGY='step-with skip ; bimc 500 (bexp? x <= 7)' straight-line-2.imp
<kat> <s> #STUCK ~> #bimc-result #false </s> <imp> <k> x ~> #freezer_+_1 ( -10 ) ~> #freezer_=_;0 ( x ) </k> <mem> x |-> 15 </mem> </imp> <analysis> ( ( ( .Trace ; { x = 0 ; ~> ( x = x + 15 ; ) ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( 15 ) ~> #freezer_=_;0 ( x ) ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x = 15 ; ~> ( x = x + -10 ; ) | x |-> 0 } ) ; { x ~> #freezer_+_1 ( -10 ) ~> #freezer_=_;0 ( x ) | x |-> 15 } </analysis> <states> .States </states> </kat>

$> krun -cSTRATEGY='step ; bimc 500 (bexp? s <= 32)' sum.imp
<kat> <s> #STUCK ~> #bimc-result #false in 40 steps : { while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | s |-> 35 n |-> 5 } </s> <imp> <k> while ( 0 <= n ) { n = n + -1 ; s = s + n ; } </k> <mem> s |-> 35 n |-> 5 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>

$> krun -cSTRATEGY='step ; bimc 40 (bexp? s <= 32)' sum.imp
<kat> <s> #STUCK ~> #bimc-result #false in 40 steps : { while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | s |-> 35 n |-> 5 } </s> <imp> <k> while ( 0 <= n ) { n = n + -1 ; s = s + n ; } </k> <mem> s |-> 35 n |-> 5 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>

$> krun -cSTRATEGY='step ; bimc 39 (bexp? s <= 32)' sum.imp
<kat> <s> #STUCK ~> #bimc-result #true in 39 steps : { s = 35 ; ~> while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | s |-> 30 n |-> 5 } </s> <imp> <k> s = 35 ; ~> while ( 0 <= n ) { n = n + -1 ; s = s + n ; } </k> <mem> s |-> 30 n |-> 5 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>
```

SBC
---

Execute this test file with `krun --search sbc.imp`.
Every solution will have it's own trace of generated rules.

```
$> krun -cSTRATEGY='compile' straight-line-1.imp
<kat> <s> #STUCK ~> #compile-result ( .Rules , < { int x , .Ids ; x = 0 ; x = x + 15 ; | .Map } --> { . | x |-> 15 } > ) </s> <imp> <k> . </k> <mem> x |-> V0 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>

$> krun -cSTRATEGY='compile' straight-line-2.imp
<kat> <s> #STUCK ~> #compile-result ( .Rules , < { int x , .Ids ; x = 0 ; x = x + 15 ; x = x + -10 ; | .Map } --> { . | x |-> 5 } > ) </s> <imp> <k> . </k> <mem> x |-> V0 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>

$> krun -cSTRATEGY='compile' dead-if.imp
<kat> <s> #STUCK ~> #compile-result ( .Rules , < { int x , .Ids ; x = 7 ; if ( x <= 7 ) { x = 1 ; } else { x = -1 ; } | .Map } --> { . | x |-> 1 } > ) </s> <imp> <k> . </k> <mem> x |-> V0 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>

$> krun -cSTRATEGY='compile' sum.imp
<kat> <s> #STUCK ~> #compile-result ( ( ( .Rules , < { int n , ( s , .Ids ) ; n = 10 ; while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | .Map } --> { while ( 0 <= n ) { n = n + -1 ; s = s + n ; } | s |-> 0 n |-> 10 } > ) , < { while ( false ) { n = n + -1 ; s = s + n ; } | s |-> V0 n |-> V1 } --> { . | s |-> V0 n |-> V1 } > ) , < { while ( true ) { n = n + -1 ; s = s + n ; } | s |-> V0 n |-> V1 } --> { while ( true ) { n = n + -1 ; s = s + n ; } | s |-> ( V0 +Int ( V1 +Int -1 ) ) n |-> ( V1 +Int -1 ) } > ) </s> <imp> <k> while ( true ) { n = n + -1 ; s = s + n ; } </k> <mem> s |-> V2 n |-> V3 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>

$> krun -cSTRATEGY='compile' sum-plus.imp
<kat> <s> #STUCK ~> #compile-result ( ( ( .Rules , < { int n , ( s , .Ids ) ; n = 10 ; while ( 0 <= n ) { n = n + -1 ; s = s + n ; } s = s + 300 ; | .Map } --> { ( while ( 0 <= n ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) | s |-> 0 n |-> 10 } > ) , < { ( while ( false ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) | s |-> V0 n |-> V1 } --> { . | s |-> ( V0 +Int 300 ) n |-> V1 } > ) , < { ( while ( true ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) | s |-> V0 n |-> V1 } --> { ( while ( true ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) | s |-> ( V0 +Int ( V1 +Int -1 ) ) n |-> ( V1 +Int -1 ) } > ) </s> <imp> <k> ( while ( true ) { n = n + -1 ; s = s + n ; } ) ~> ( s = s + 300 ; ) </k> <mem> s |-> V2 n |-> V3 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>

$> krun --search -cSTRATEGY='compile' collatz.imp
Solution 1
<kat> <s> #STUCK ~> #compile-result ( ( ( .Rules , < { int n , ( x , .Ids ) ; n = 782 ; x = 0 ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | .Map } --> { while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> 0 n |-> 782 } > ) , < { while ( false ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> V0 n |-> V1 } --> { . | x |-> V0 n |-> V1 } > ) , < { while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> V0 n |-> V1 } --> { while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> ( V0 +Int 1 ) n |-> ( 3 *Int V1 +Int 1 ) } > ) </s> <imp> <k> while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k> <mem> x |-> V2 n |-> V3 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>
Solution 2
<kat> <s> #STUCK ~> #compile-result ( ( ( .Rules , < { int n , ( x , .Ids ) ; n = 782 ; x = 0 ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | .Map } --> { while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> 0 n |-> 782 } > ) , < { while ( false ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> V0 n |-> V1 } --> { . | x |-> V0 n |-> V1 } > ) , < { while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> V0 n |-> V1 } --> { while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } | x |-> ( V0 +Int 1 ) n |-> ( V1 /Int 2 ) } > ) </s> <imp> <k> while ( true ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; } </k> <mem> x |-> V2 n |-> V3 </mem> </imp> <analysis> .Analysis </analysis> <states> .States </states> </kat>
```
