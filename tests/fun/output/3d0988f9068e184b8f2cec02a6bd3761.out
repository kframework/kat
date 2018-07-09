Program:  simple-rec.fun
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
          letrec ( simple = fun ( 0 -> 0 ) | n -> simple ( n - 1 ) | .Cases ) and .Bindings in simple V0
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
          muclosure ( simple |-> 0 , 0 -> 0 | n -> simple ( n - 1 ) | .Cases ) ~> #arg ( V0 )
        </k>
        <extraComp>
          setEnv ( .Map )
        </extraComp>
        <env>
          simple |-> 0
        </env>
        <store>
          0 |-> muclosure ( simple |-> 0 , 0 -> 0 | n -> simple ( n - 1 ) | .Cases )
        </store>
        <nextLoc>
          1
        </nextLoc>
      </FUN> requires #True > , < <FUN>
        <k>
          muclosure ( simple |-> 0 , 0 -> 0 | n -> simple ( n - 1 ) | .Cases ) ~> #arg ( V1 )
        </k>
        <extraComp>
          setEnv ( .Map )
        </extraComp>
        <env>
          simple |-> 0
        </env>
        <store>
          0 |-> muclosure ( simple |-> 0 , 0 -> 0 | n -> simple ( n - 1 ) | .Cases )
        </store>
        <nextLoc>
          1
        </nextLoc>
      </FUN> --> <FUN>
        <k>
          muclosure ( simple |-> 0 , 0 -> 0 | n -> simple ( n - 1 ) | .Cases ) ~> #arg ( V1 -Int 1 )
        </k>
        <extraComp>
          setEnv ( simple |-> 0 ) ~> setEnv ( .Map )
        </extraComp>
        <env>
          n |-> 1
          simple |-> 0
        </env>
        <store>
          0 |-> muclosure ( simple |-> 0 , 0 -> 0 | n -> simple ( n - 1 ) | .Cases )
          1 |-> V1
        </store>
        <nextLoc>
          2
        </nextLoc>
      </FUN> requires 0 ==K V1 ==K false > , < <FUN>
        <k>
          muclosure ( simple |-> 0 , 0 -> 0 | n -> simple ( n - 1 ) | .Cases ) ~> #arg ( 0 )
        </k>
        <extraComp>
          setEnv ( .Map )
        </extraComp>
        <env>
          simple |-> 0
        </env>
        <store>
          0 |-> muclosure ( simple |-> 0 , 0 -> 0 | n -> simple ( n - 1 ) | .Cases )
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
          0 |-> muclosure ( simple |-> 0 , 0 -> 0 | n -> simple ( n - 1 ) | .Cases )
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
        0 |-> muclosure ( simple |-> 0 , 0 -> 0 | n -> simple ( n - 1 ) | .Cases )
      </store>
      <nextLoc>
        1
      </nextLoc>
    </FUN>
  </harness>
</kat-FUN>
