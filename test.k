// Copyright (c) 2014-2016 K Team. All Rights Reserved.
requires "domains.k"

module EXP
    syntax Exp
endmodule

module A
    import EXP
    syntax Exp ::= "x" | "y" | "load"
    configuration <imp>
                        <k> $PGM:Exp </k>
                        <d> $CAR:Exp </d>
                  </imp>

    rule x => y
endmodule

module B
    import EXP
    syntax Exp ::= "foo" | "bar"
    configuration <blah> <car> $FOO:Exp </car> </blah>

    rule <car> foo => bar </car>
endmodule

module C
    imports A
    imports B
    imports KCELLS

    configuration <t>
                   initBlahCell(Init)
                   <state> initImpCell(Init) </state>
                   <analysis> .Analysis </analysis>
                  </t>

    syntax Analysis ::= "set" Exp | ".Analysis" | State "," Analysis
    syntax State ::= "#current" | Cell

    rule <analysis> set E => .Analysis </analysis> <state> _ => <imp> <k> E </k> <d> y </d> </imp> </state>
    rule <k> y => foo ...</k> <car> bar => x </car>

    rule <k> load => . ... </k> <analysis> A => BLAH , A </analysis> <blah> BLAH </blah>
endmodule
