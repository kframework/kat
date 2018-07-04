Program:  references-4.fun
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
          let ( f = let ( c = ( fun ( $x -> & $x ) | .Cases ) 0 ) and .Bindings in ( c := @ c + 100 ; ( fun ( x -> c := @ c + 1000 ; x + x + @ c ) | .Cases ) ) ) and .Bindings in let ( y = ( fun ( $x -> & $x ) | .Cases ) 0 ) and .Bindings in f ( y := @ y + 1 ; @ y ) + f 0
        </k>
        <env>
          .Map
        </env>
        <store>
          .Map
        </store>
      </FUN> --> <FUN>
        <k>
          3202
        </k>
        <env>
          .Map
        </env>
        <store>
          152 |-> 2100
          153 |-> 152
          154 |-> closure ( c |-> 153 , x -> c := @ c + 1000 ; x + x + @ c | .Cases )
          155 |-> 1
          156 |-> 155
          157 |-> 1
          158 |-> 0
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
        3202
      </k>
      <env>
        .Map
      </env>
      <store>
        152 |-> 2100
        153 |-> 152
        154 |-> closure ( c |-> 153 , x -> c := @ c + 1000 ; x + x + @ c | .Cases )
        155 |-> 1
        156 |-> 155
        157 |-> 1
        158 |-> 0
      </store>
    </FUN>
  </harness>
</kat-FUN>
