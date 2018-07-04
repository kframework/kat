Program:  tuple-3.fun
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
          let ( f = fun ( Pair ( a , b , .Exps ) -> fun ( Pair ( x , y , .Exps ) -> a Pair ( x , y , .Exps ) + b Pair ( x , y , .Exps ) ) | .Cases ) | .Cases ) and .Bindings in f Pair ( fun ( Pair ( x , y , .Exps ) -> x * y - 3 + x + y ) | .Cases , fun ( Pair ( x , y , .Exps ) -> x + y * 7 - 2 - 4 + x ) | .Cases , .Exps ) Pair ( 10 , 20 , .Exps )
        </k>
        <env>
          .Map
        </env>
        <store>
          .Map
        </store>
      </FUN> --> <FUN>
        <k>
          381
        </k>
        <env>
          .Map
        </env>
        <store>
          176 |-> closure ( .Map , Pair ( a , b , .Exps ) -> ( fun ( Pair ( x , y , .Exps ) -> a Pair ( x , y , .Exps ) + b Pair ( x , y , .Exps ) ) | .Cases ) | .Cases )
          177 |-> closure ( f |-> 176 , Pair ( x , y , .Exps ) -> x + y * 7 - 2 - 4 + x | .Cases )
          178 |-> closure ( f |-> 176 , Pair ( x , y , .Exps ) -> x * y - 3 + x + y | .Cases )
          179 |-> 10
          180 |-> 20
          181 |-> 10
          182 |-> 20
          183 |-> 10
          184 |-> 20
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
        381
      </k>
      <env>
        .Map
      </env>
      <store>
        176 |-> closure ( .Map , Pair ( a , b , .Exps ) -> ( fun ( Pair ( x , y , .Exps ) -> a Pair ( x , y , .Exps ) + b Pair ( x , y , .Exps ) ) | .Cases ) | .Cases )
        177 |-> closure ( f |-> 176 , Pair ( x , y , .Exps ) -> x + y * 7 - 2 - 4 + x | .Cases )
        178 |-> closure ( f |-> 176 , Pair ( x , y , .Exps ) -> x * y - 3 + x + y | .Cases )
        179 |-> 10
        180 |-> 20
        181 |-> 10
        182 |-> 20
        183 |-> 10
        184 |-> 20
      </store>
    </FUN>
  </harness>
</kat-FUN>
