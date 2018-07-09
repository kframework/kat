Program:  sum-symbolic.fun
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
          letrec ( sum = fun ( 0 -> 0 ) | n -> n + sum ( n - 1 ) | .Cases ) and .Bindings in sum V0
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
          muclosure ( sum |-> 0 , 0 -> 0 | n -> n + sum ( n - 1 ) | .Cases ) ~> #arg ( V0 )
        </k>
        <extraComp>
          setEnv ( .Map )
        </extraComp>
        <env>
          sum |-> 0
        </env>
        <store>
          0 |-> muclosure ( sum |-> 0 , 0 -> 0 | n -> n + sum ( n - 1 ) | .Cases )
        </store>
        <nextLoc>
          1
        </nextLoc>
      </FUN> requires #True > , < <FUN>
        <k>
          muclosure ( sum |-> 0 , 0 -> 0 | n -> n + sum ( n - 1 ) | .Cases ) ~> #arg ( V1 )
        </k>
        <extraComp>
          setEnv ( .Map )
        </extraComp>
        <env>
          sum |-> 0
        </env>
        <store>
          0 |-> muclosure ( sum |-> 0 , 0 -> 0 | n -> n + sum ( n - 1 ) | .Cases )
        </store>
        <nextLoc>
          1
        </nextLoc>
      </FUN> --> <FUN>
        <k>
          muclosure ( sum |-> 0 , 0 -> 0 | n -> n + sum ( n - 1 ) | .Cases ) ~> #arg ( V1 -Int 1 )
        </k>
        <extraComp>
          #freezer_+__FUN-UNTYPED-COMMON0_ ( V1 ) ~> setEnv ( sum |-> 0 ) ~> setEnv ( .Map )
        </extraComp>
        <env>
          n |-> 1
          sum |-> 0
        </env>
        <store>
          0 |-> muclosure ( sum |-> 0 , 0 -> 0 | n -> n + sum ( n - 1 ) | .Cases )
          1 |-> V1
        </store>
        <nextLoc>
          2
        </nextLoc>
      </FUN> requires 0 ==K V1 ==K false > , < <FUN>
        <k>
          muclosure ( sum |-> 0 , 0 -> 0 | n -> n + sum ( n - 1 ) | .Cases ) ~> #arg ( 0 )
        </k>
        <extraComp>
          setEnv ( .Map )
        </extraComp>
        <env>
          sum |-> 0
        </env>
        <store>
          0 |-> muclosure ( sum |-> 0 , 0 -> 0 | n -> n + sum ( n - 1 ) | .Cases )
        </store>
        <nextLoc>
          1
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
          0 |-> muclosure ( sum |-> 0 , 0 -> 0 | n -> n + sum ( n - 1 ) | .Cases )
        </store>
        <nextLoc>
          1
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
        0 |-> muclosure ( sum |-> 0 , 0 -> 0 | n -> n + sum ( n - 1 ) | .Cases )
      </store>
      <nextLoc>
        1
      </nextLoc>
    </FUN>
  </harness>
</kat-FUN>
