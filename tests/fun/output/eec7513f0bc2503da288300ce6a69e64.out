Program:  prelude.fun
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
          let ( id = fun ( x -> x ) | .Cases ) and fst = fun ( l -> fun ( r -> l ) | .Cases ) | .Cases and snd = fun ( l -> fun ( r -> r ) | .Cases ) | .Cases and cons = fun ( h -> fun ( t -> [ h : t ] ) | .Cases ) | .Cases and head = fun ( [ h : t ] -> h ) | .Cases and tail = fun ( [ h : t ] -> t ) | .Cases and apply = fun ( f -> fun ( d -> f d ) | .Cases ) | .Cases and .Bindings in apply id ( head ( tail [ 3 : 5 : 7 : 9 : .Exps ] ) )
        </k>
        <callStack>
          .
        </callStack>
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
          5
        </k>
        <callStack>
          .
        </callStack>
        <env>
          .Map
        </env>
        <store>
          0 |-> closure ( .Map , x -> x | .Cases )
          1 |-> closure ( .Map , l -> ( fun ( r -> l ) | .Cases ) | .Cases )
          2 |-> closure ( .Map , l -> ( fun ( r -> r ) | .Cases ) | .Cases )
          3 |-> closure ( .Map , [ h : t ] -> t | .Cases )
          4 |-> closure ( .Map , [ h : t ] -> h | .Cases )
          5 |-> closure ( .Map , h -> ( fun ( t -> [ h : t ] ) | .Cases ) | .Cases )
          6 |-> closure ( .Map , f -> ( fun ( d -> f d ) | .Cases ) | .Cases )
          7 |-> 3
          8 |-> [ 5 : 7 : 9 : .Exps ]
          9 |-> 5
          10 |-> [ 7 : 9 : .Exps ]
          11 |-> closure ( .Map , x -> x | .Cases )
          12 |-> 5
          13 |-> 5
        </store>
        <nextLoc>
          14
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
        5
      </k>
      <callStack>
        .
      </callStack>
      <env>
        .Map
      </env>
      <store>
        0 |-> closure ( .Map , x -> x | .Cases )
        1 |-> closure ( .Map , l -> ( fun ( r -> l ) | .Cases ) | .Cases )
        2 |-> closure ( .Map , l -> ( fun ( r -> r ) | .Cases ) | .Cases )
        3 |-> closure ( .Map , [ h : t ] -> t | .Cases )
        4 |-> closure ( .Map , [ h : t ] -> h | .Cases )
        5 |-> closure ( .Map , h -> ( fun ( t -> [ h : t ] ) | .Cases ) | .Cases )
        6 |-> closure ( .Map , f -> ( fun ( d -> f d ) | .Cases ) | .Cases )
        7 |-> 3
        8 |-> [ 5 : 7 : 9 : .Exps ]
        9 |-> 5
        10 |-> [ 7 : 9 : .Exps ]
        11 |-> closure ( .Map , x -> x | .Cases )
        12 |-> 5
        13 |-> 5
      </store>
      <nextLoc>
        14
      </nextLoc>
    </FUN>
  </harness>
</kat-FUN>
