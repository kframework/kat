Program:  references-5.fun
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
          let ( f = fun ( x -> x := @ x + 1 ) | .Cases ) and x = 7 and .Bindings in [ x , f & x ; x , f & x ; x , .Exps ]
        </k>
        <env>
          .Map
        </env>
        <store>
          .Map
        </store>
      </FUN> --> <FUN>
        <k>
          [ 7 , 8 , 9 , .Exps ]
        </k>
        <env>
          .Map
        </env>
        <store>
          60 |-> 9
          61 |-> closure ( .Map , x -> x := @ x + 1 | .Cases )
          62 |-> 60
          63 |-> 60
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
        [ 7 , 8 , 9 , .Exps ]
      </k>
      <env>
        .Map
      </env>
      <store>
        60 |-> 9
        61 |-> closure ( .Map , x -> x := @ x + 1 | .Cases )
        62 |-> 60
        63 |-> 60
      </store>
    </FUN>
  </harness>
</kat-FUN>
