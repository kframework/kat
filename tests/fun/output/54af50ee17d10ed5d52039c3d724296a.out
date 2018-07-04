Program:  references-2.fun
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
          let ( f = fun ( x -> fun ( y -> x := @ x + 2 ; y := @ y + 3 ) | .Cases ) | .Cases ) and x = ( fun ( $x -> & $x ) | .Cases ) 0 and .Bindings in ( f x x ; @ x )
        </k>
        <env>
          .Map
        </env>
        <store>
          .Map
        </store>
      </FUN> --> <FUN>
        <k>
          5
        </k>
        <env>
          .Map
        </env>
        <store>
          82 |-> 5
          83 |-> 82
          84 |-> closure ( .Map , x -> ( fun ( y -> x := @ x + 2 ; y := @ y + 3 ) | .Cases ) | .Cases )
          85 |-> 82
          86 |-> 82
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
        5
      </k>
      <env>
        .Map
      </env>
      <store>
        82 |-> 5
        83 |-> 82
        84 |-> closure ( .Map , x -> ( fun ( y -> x := @ x + 2 ; y := @ y + 3 ) | .Cases ) | .Cases )
        85 |-> 82
        86 |-> 82
      </store>
    </FUN>
  </harness>
</kat-FUN>
