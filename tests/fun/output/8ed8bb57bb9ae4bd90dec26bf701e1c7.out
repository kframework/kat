Program:  references-3.fun
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
          let ( f = fun ( x -> x + x ) | .Cases ) and .Bindings in let ( y = ( fun ( $x -> & $x ) | .Cases ) 5 ) and .Bindings in f ( y := @ y + 3 ; @ y )
        </k>
        <env>
          .Map
        </env>
        <store>
          .Map
        </store>
      </FUN> --> <FUN>
        <k>
          16
        </k>
        <env>
          .Map
        </env>
        <store>
          51 |-> closure ( .Map , x -> x + x | .Cases )
          52 |-> 8
          53 |-> 52
          54 |-> 8
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
        16
      </k>
      <env>
        .Map
      </env>
      <store>
        51 |-> closure ( .Map , x -> x + x | .Cases )
        52 |-> 8
        53 |-> 52
        54 |-> 8
      </store>
    </FUN>
  </harness>
</kat-FUN>
