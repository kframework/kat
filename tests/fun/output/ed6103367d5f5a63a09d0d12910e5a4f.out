Program:  polymorphism-1.fun
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
          let ( f = fun ( x -> x ) | .Cases ) and .Bindings in if f true then f 2 else f 3
        </k>
        <env>
          .Map
        </env>
        <store>
          .Map
        </store>
      </FUN> --> <FUN>
        <k>
          2
        </k>
        <env>
          .Map
        </env>
        <store>
          57 |-> closure ( .Map , x -> x | .Cases )
          58 |-> true
          59 |-> 2
        </store>
      </FUN> requires #True >
    </analysis>
    <states>
      .States
    </states>
  </kat>
  <harness>
    <FUN>
      <k>
        2
      </k>
      <env>
        .Map
      </env>
      <store>
        57 |-> closure ( .Map , x -> x | .Cases )
        58 |-> true
        59 |-> 2
      </store>
    </FUN>
  </harness>
</kat-FUN>
