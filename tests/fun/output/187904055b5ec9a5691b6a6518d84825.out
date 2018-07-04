Program:  polymorphism-2.fun
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
          let ( f = fun ( x -> let ( y = x ) and .Bindings in y ) | .Cases ) and .Bindings in ( fun ( x -> f ) | .Cases ) 7
        </k>
        <env>
          .Map
        </env>
        <store>
          .Map
        </store>
      </FUN> --> <FUN>
        <k>
          closure ( .Map , x -> let ( y = x ) and .Bindings in y | .Cases )
        </k>
        <env>
          .Map
        </env>
        <store>
          17 |-> closure ( .Map , x -> let ( y = x ) and .Bindings in y | .Cases )
          18 |-> 7
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
        closure ( .Map , x -> let ( y = x ) and .Bindings in y | .Cases )
      </k>
      <env>
        .Map
      </env>
      <store>
        17 |-> closure ( .Map , x -> let ( y = x ) and .Bindings in y | .Cases )
        18 |-> 7
      </store>
    </FUN>
  </harness>
</kat-FUN>
