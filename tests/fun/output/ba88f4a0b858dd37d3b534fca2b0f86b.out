Program:  collatz-all-upto.fun
Strategy: compile
================================================================================
<kat-FUN>
  <s>
    #STUCK ( )
  </s>
  <kat>
    <analysis>
      .Rules , < <FUN>
        <k>
          letrec ( allCollatz = fun ( 0 -> 0 ) | n -> collatz n + allCollatz ( n - 1 ) | .Cases ) and collatz = fun ( 1 -> 1 ) | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases and .Bindings in allCollatz V0
        </k>
        <extraComp>
          .
        </extraComp>
        <env>
          .Map
        </env>
        <store>
          .Map
        </store>
        <nextLoc>
          0
        </nextLoc>
      </FUN> --> <FUN>
        <k>
          muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases ) ~> #arg ( V0 )
        </k>
        <extraComp>
          setEnv ( .Map )
        </extraComp>
        <env>
          allCollatz |-> 0
          collatz |-> 1
        </env>
        <store>
          0 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases )
          1 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases )
        </store>
        <nextLoc>
          2
        </nextLoc>
      </FUN> requires #True > , < <FUN>
        <k>
          muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases ) ~> #arg ( V1 )
        </k>
        <extraComp>
          setEnv ( .Map )
        </extraComp>
        <env>
          allCollatz |-> 0
          collatz |-> 1
        </env>
        <store>
          0 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases )
          1 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases )
        </store>
        <nextLoc>
          2
        </nextLoc>
      </FUN> --> <FUN>
        <k>
          muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases ) ~> #arg ( V1 )
        </k>
        <extraComp>
          #freezer_+__FUN-UNTYPED-COMMON1_ ( allCollatz ( n - 1 ) ) ~> setEnv ( allCollatz |-> 0
          collatz |-> 1 ) ~> setEnv ( .Map )
        </extraComp>
        <env>
          allCollatz |-> 0
          collatz |-> 1
          n |-> 2
        </env>
        <store>
          0 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases )
          1 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases )
          2 |-> V1
        </store>
        <nextLoc>
          3
        </nextLoc>
      </FUN> requires 0 ==K V1 ==K false > , < <FUN>
        <k>
          muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases ) ~> #arg ( V2 )
        </k>
        <extraComp>
          #freezer_+__FUN-UNTYPED-COMMON1_ ( allCollatz ( n - 1 ) ) ~> setEnv ( allCollatz |-> 0
          collatz |-> 1 ) ~> setEnv ( .Map )
        </extraComp>
        <env>
          allCollatz |-> 0
          collatz |-> 1
          n |-> 2
        </env>
        <store>
          0 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases )
          1 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases )
          2 |-> V3
        </store>
        <nextLoc>
          3
        </nextLoc>
      </FUN> --> <FUN>
        <k>
          muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases ) ~> #arg ( 3 *Int V2 +Int 1 )
        </k>
        <extraComp>
          #freezer_+__FUN-UNTYPED-COMMON0_ ( 1 ) ~> setEnv ( allCollatz |-> 0
          collatz |-> 1
          n |-> 2 ) ~> #freezer_+__FUN-UNTYPED-COMMON1_ ( allCollatz ( n - 1 ) ) ~> setEnv ( allCollatz |-> 0
          collatz |-> 1 ) ~> setEnv ( .Map )
        </extraComp>
        <env>
          allCollatz |-> 0
          collatz |-> 1
          n |-> 3
        </env>
        <store>
          0 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases )
          1 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases )
          2 |-> V3
          3 |-> V2
        </store>
        <nextLoc>
          4
        </nextLoc>
      </FUN> requires 1 ==K V2 ==K false #And
      V2 %Int 2 ==K 0 ==K false > , < <FUN>
        <k>
          muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases ) ~> #arg ( V4 )
        </k>
        <extraComp>
          #freezer_+__FUN-UNTYPED-COMMON1_ ( allCollatz ( n - 1 ) ) ~> setEnv ( allCollatz |-> 0
          collatz |-> 1 ) ~> setEnv ( .Map )
        </extraComp>
        <env>
          allCollatz |-> 0
          collatz |-> 1
          n |-> 2
        </env>
        <store>
          0 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases )
          1 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases )
          2 |-> V5
        </store>
        <nextLoc>
          3
        </nextLoc>
      </FUN> --> <FUN>
        <k>
          muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases ) ~> #arg ( V4 /Int 2 )
        </k>
        <extraComp>
          #freezer_+__FUN-UNTYPED-COMMON0_ ( 1 ) ~> setEnv ( allCollatz |-> 0
          collatz |-> 1
          n |-> 2 ) ~> #freezer_+__FUN-UNTYPED-COMMON1_ ( allCollatz ( n - 1 ) ) ~> setEnv ( allCollatz |-> 0
          collatz |-> 1 ) ~> setEnv ( .Map )
        </extraComp>
        <env>
          allCollatz |-> 0
          collatz |-> 1
          n |-> 3
        </env>
        <store>
          0 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases )
          1 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases )
          2 |-> V5
          3 |-> V4
        </store>
        <nextLoc>
          4
        </nextLoc>
      </FUN> requires 1 ==K V4 ==K false #And
      V4 %Int 2 ==K 0 > , < <FUN>
        <k>
          muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases ) ~> #arg ( 1 )
        </k>
        <extraComp>
          #freezer_+__FUN-UNTYPED-COMMON1_ ( allCollatz ( n - 1 ) ) ~> setEnv ( allCollatz |-> 0
          collatz |-> 1 ) ~> setEnv ( .Map )
        </extraComp>
        <env>
          allCollatz |-> 0
          collatz |-> 1
          n |-> 2
        </env>
        <store>
          0 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases )
          1 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases )
          2 |-> V6
        </store>
        <nextLoc>
          3
        </nextLoc>
      </FUN> --> <FUN>
        <k>
          muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases ) ~> #arg ( V6 -Int 1 )
        </k>
        <extraComp>
          #freezer_+__FUN-UNTYPED-COMMON0_ ( 1 ) ~> setEnv ( allCollatz |-> 0
          collatz |-> 1 ) ~> setEnv ( .Map )
        </extraComp>
        <env>
          allCollatz |-> 0
          collatz |-> 1
          n |-> 2
        </env>
        <store>
          0 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases )
          1 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases )
          2 |-> V6
        </store>
        <nextLoc>
          3
        </nextLoc>
      </FUN> requires #True > , < <FUN>
        <k>
          muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases ) ~> #arg ( 0 )
        </k>
        <extraComp>
          setEnv ( .Map )
        </extraComp>
        <env>
          allCollatz |-> 0
          collatz |-> 1
        </env>
        <store>
          0 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases )
          1 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases )
        </store>
        <nextLoc>
          2
        </nextLoc>
      </FUN> --> <FUN>
        <k>
          0
        </k>
        <extraComp>
          .
        </extraComp>
        <env>
          .Map
        </env>
        <store>
          0 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases )
          1 |-> muclosure ( allCollatz |-> 0
          collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases )
        </store>
        <nextLoc>
          2
        </nextLoc>
      </FUN> requires #True >
    </analysis>
    <states>
      .States
    </states>
  </kat>
  <harness>
    <FUN>
      <k>
        0
      </k>
      <extraComp>
        .
      </extraComp>
      <env>
        .Map
      </env>
      <store>
        0 |-> muclosure ( allCollatz |-> 0
        collatz |-> 1 , 0 -> 0 | n -> collatz n + allCollatz ( n - 1 ) | .Cases )
        1 |-> muclosure ( allCollatz |-> 0
        collatz |-> 1 , 1 -> 1 | n -> if n % 2 == 0 then 1 + collatz ( n / 2 ) else 1 + collatz ( 3 * n + 1 ) | .Cases )
      </store>
      <nextLoc>
        2
      </nextLoc>
    </FUN>
  </harness>
</kat-FUN>
