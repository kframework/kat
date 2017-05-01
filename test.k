// Copyright (c) 2014-2016 K Team. All Rights Reserved.
requires "domains.k"

module EXP
    syntax Exp
endmodule

module A
    import EXP
    syntax Exp ::= "x" | "y"
    configuration <imp> <k> $PGM </k> </imp>

    rule x => y
endmodule

module B
    import EXP
    syntax Exp ::= "foo" | "bar"
    configuration <blah> foo </blah>

    rule <blah> foo => bar </blah>
endmodule

module C
    imports A
    imports B

    configuration <t>
                   initBlahCell
                   <state> initImpCell(.K) </state>
                   <analysis> .K </analysis>
                  </t>

    syntax Analysis ::= "set" Exp | ".Analysis"

    rule <analysis> set E => .Analysis </analysis> <state> _ => <imp> <k> E </k> </imp> </state>
    rule <k> y => foo ...</k> <blah> bar => x </blah>
endmodule
