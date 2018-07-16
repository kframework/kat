Program:  list-1.fun
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
          letrec ( second = fun ( l -> fun ( x -> ( fun ( [ $h , .Names | $t ] -> $h ) | .Cases ) ( ( fun ( [ $h , .Names | $t ] -> $t ) | .Cases ) l ) ) | .Cases ) | .Cases ) and .Bindings in second [ 1 , 3 , 5 , 2 , 4 , 0 , -1 , -5 , .Names ] true
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
          muclosure ( second |-> 0 , l -> ( fun ( x -> ( fun ( [ $h , .Names | $t ] -> $h ) | .Cases ) ( ( fun ( [ $h , .Names | $t ] -> $t ) | .Cases ) l ) ) | .Cases ) | .Cases ) ~> #arg ( [ 1 , 3 , 5 , 2 , 4 , 0 , -1 , -5 , .Names ] )
        </k>
        <callStack>
          #arg ( true ) ~> setEnv ( .Map )
        </callStack>
        <env>
          second |-> 0
        </env>
        <store>
          0 |-> muclosure ( second |-> 0 , l -> ( fun ( x -> ( fun ( [ $h , .Names | $t ] -> $h ) | .Cases ) ( ( fun ( [ $h , .Names | $t ] -> $t ) | .Cases ) l ) ) | .Cases ) | .Cases )
        </store>
        <nextLoc>
          1
        </nextLoc>
      </FUN> requires #True > , < <FUN>
        <k>
          muclosure ( second |-> 0 , l -> ( fun ( x -> ( fun ( [ $h , .Names | $t ] -> $h ) | .Cases ) ( ( fun ( [ $h , .Names | $t ] -> $t ) | .Cases ) l ) ) | .Cases ) | .Cases ) ~> #arg ( [ V0 , V1 , V2 , V3 , V4 , V5 , V6 , V7 , .Names ] )
        </k>
        <callStack>
          #arg ( true ) ~> setEnv ( .Map )
        </callStack>
        <env>
          second |-> 0
        </env>
        <store>
          0 |-> muclosure ( second |-> 0 , l -> ( fun ( x -> ( fun ( [ $h , .Names | $t ] -> $h ) | .Cases ) ( ( fun ( [ $h , .Names | $t ] -> $t ) | .Cases ) l ) ) | .Cases ) | .Cases )
        </store>
        <nextLoc>
          1
        </nextLoc>
      </FUN> --> <FUN>
        <k>
          V1
        </k>
        <callStack>
          .
        </callStack>
        <env>
          .Map
        </env>
        <store>
          0 |-> muclosure ( second |-> 0 , l -> ( fun ( x -> ( fun ( [ $h , .Names | $t ] -> $h ) | .Cases ) ( ( fun ( [ $h , .Names | $t ] -> $t ) | .Cases ) l ) ) | .Cases ) | .Cases )
          1 |-> [ V0 , V1 , V2 , V3 , V4 , V5 , V6 , V7 , .Names ]
          2 |-> true
          3 |-> [ V1 , V2 , V3 , V4 , V5 , V6 , V7 , .Names ]
          4 |-> V0
          5 |-> [ V2 , V3 , V4 , V5 , V6 , V7 , .Names ]
          6 |-> V1
        </store>
        <nextLoc>
          7
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
        V1
      </k>
      <callStack>
        .
      </callStack>
      <env>
        .Map
      </env>
      <store>
        0 |-> muclosure ( second |-> 0 , l -> ( fun ( x -> ( fun ( [ $h , .Names | $t ] -> $h ) | .Cases ) ( ( fun ( [ $h , .Names | $t ] -> $t ) | .Cases ) l ) ) | .Cases ) | .Cases )
        1 |-> [ V0 , V1 , V2 , V3 , V4 , V5 , V6 , V7 , .Names ]
        2 |-> true
        3 |-> [ V1 , V2 , V3 , V4 , V5 , V6 , V7 , .Names ]
        4 |-> V0
        5 |-> [ V2 , V3 , V4 , V5 , V6 , V7 , .Names ]
        6 |-> V1
      </store>
      <nextLoc>
        7
      </nextLoc>
    </FUN>
  </harness>
</kat-FUN>
