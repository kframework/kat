Program:  exceptions.fun
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
          callcc ( fun ( $k -> ( fun ( throw -> callcc ( fun ( $k -> ( fun ( throw -> 3 + throw 10 * 2 ) | .Cases ) ( fun ( x -> $k ( throw ( 2 * x ) + 7 ) ) | .Cases ) ) | .Cases ) ) | .Cases ) ( fun ( x -> $k ( x + 1 ) ) | .Cases ) ) | .Cases )
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
          21
        </k>
        <callStack>
          setEnv ( $k |-> 2
          throw |-> 1
          x |-> 4 ) ~> #freezer_+__FUN-UNTYPED-COMMON1_ ( 7 ) ~> #apply ( $k ) ~> setEnv ( $k |-> 2
          throw |-> 3 ) ~> #freezer_*__FUN-UNTYPED-COMMON1_ ( 2 ) ~> #freezer_+__FUN-UNTYPED-COMMON0_ ( 3 ) ~> setEnv ( $k |-> 2
          throw |-> 1 ) ~> setEnv ( $k |-> 0
          throw |-> 1 ) ~> setEnv ( $k |-> 0 ) ~> setEnv ( .Map )
        </callStack>
        <env>
          .Map
        </env>
        <store>
          0 |-> cc ( .Map , . )
          1 |-> closure ( $k |-> 0 , x -> $k ( x + 1 ) | .Cases )
          2 |-> cc ( $k |-> 0
          throw |-> 1 , . )
          3 |-> closure ( $k |-> 2
          throw |-> 1 , x -> $k ( throw ( 2 * x ) + 7 ) | .Cases )
          4 |-> 10
          5 |-> 20
        </store>
        <nextLoc>
          6
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
        21
      </k>
      <callStack>
        setEnv ( $k |-> 2
        throw |-> 1
        x |-> 4 ) ~> #freezer_+__FUN-UNTYPED-COMMON1_ ( 7 ) ~> #apply ( $k ) ~> setEnv ( $k |-> 2
        throw |-> 3 ) ~> #freezer_*__FUN-UNTYPED-COMMON1_ ( 2 ) ~> #freezer_+__FUN-UNTYPED-COMMON0_ ( 3 ) ~> setEnv ( $k |-> 2
        throw |-> 1 ) ~> setEnv ( $k |-> 0
        throw |-> 1 ) ~> setEnv ( $k |-> 0 ) ~> setEnv ( .Map )
      </callStack>
      <env>
        .Map
      </env>
      <store>
        0 |-> cc ( .Map , . )
        1 |-> closure ( $k |-> 0 , x -> $k ( x + 1 ) | .Cases )
        2 |-> cc ( $k |-> 0
        throw |-> 1 , . )
        3 |-> closure ( $k |-> 2
        throw |-> 1 , x -> $k ( throw ( 2 * x ) + 7 ) | .Cases )
        4 |-> 10
        5 |-> 20
      </store>
      <nextLoc>
        6
      </nextLoc>
    </FUN>
  </harness>
</kat-FUN>
