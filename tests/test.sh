# IMP-KAT Tests
# =============

# We'll use a simple testing harness in `bash` which just checks the output of
# `krun --search` against a supplied file. Run this with `bash runtests.sh`.


strip_output() {
    grep -v -e '^$' -e '^\s*//' | tr '\n' ' ' | tr -s ' '
}

test() {
    strategy="$1"
    imp_file="$2"
    out_file="output/$3"
    for file in "$imp_file" "$out_file"; do
        [[ ! -f "$file" ]] && recho "File '$file' does not exist ..." && exit 1
    done
    echo "krun --search --directory '../' -cSTRATEGY='$strategy' '$imp_file'"
    diff <(cat "$out_file" | strip_output) <(krun --search --directory '../' -cSTRATEGY="$strategy" "$imp_file" | strip_output)
    exit "$?"
}

test="$1"
case "$test" in


# BIMC
# ----

# Here, we allow each program to initialize (get through variable declarations) by
# running `step-with skip`. Then we issue some `bimc` query to check if the
# program obeys the given invariant up to the depth-bound.

# ### Straight Line 1

# Assertion not violated at step 2:


"straight-line-1-bimc1") test 'step-with skip ; bimc 2 (bexp? x <= 7)' straight-line-1.imp straight-line-1-bimc1.out ;;


# Assertion violation at step 3:


"straight-line-1-bimc2") test 'step-with skip ; bimc 3 (bexp? x <= 7)' straight-line-1.imp straight-line-1-bimc2.out ;;


# ### Straight Line 2

# Assertion not violated up to step 2:


"straight-line-2-bimc1") test 'step-with skip ; bimc 2 (bexp? x <= 7)' straight-line-2.imp straight-line-2-bimc1.out ;;


# Assertion violated at step 3:


"straight-line-2-bimc2") test 'step-with skip ; bimc 3 (bexp? x <= 7)' straight-line-2.imp straight-line-2-bimc2.out ;;


# Assertion still violated at step 3 (with extended bound):


"straight-line-2-bimc3") test 'step-with skip ; bimc 500 (bexp? x <= 7)' straight-line-2.imp straight-line-2-bimc3.out ;;


# ### Sum

# Query with large bound to find which step pushed the sum above `32`:


"sum-bimc1") test 'step-with skip ; bimc 500 (bexp? s <= 32)' sum.imp sum-bimc1.out ;;


# Show that the returned number is the correct step that an assertion violation
# happens at:


"sum-bimc2") test 'step-with skip ; bimc 41 (bexp? s <= 32)' sum.imp sum-bimc2.out ;;


# And that one step prior the assertion was not violated:


"sum-bimc3") test 'step-with skip ; bimc 40 (bexp? s <= 32)' sum.imp sum-bimc3.out ;;


# ### Collatz

# Here we test if the Collatz sequence for `782` contains any numbers greater than
# `1000`.


"collatz-bimc") test 'step-with skip ; bimc 5000 (bexp? n <= 1000)' collatz.imp collatz-bimc.out ;;


# ### Collatz All


"collatz-all-bimc") test 'step-with skip ; bimc 5000 (bexp? n <= 1000)' collatz-all.imp collatz-all-bimc.out ;;


# ### Krazy Loop


"krazy-loop-correct-bimc") test 'bimc 5000 (not div-zero-error?)' krazy-loop-correct.imp krazy-loop-correct-bimc.out ;;



"krazy-loop-incorrect-bimc1") test 'bimc 5000 (not div-zero-error?)' krazy-loop-incorrect krazy-loop-incorrect-bimc1.out ;;



"krazy-loop-incorrect-bimc2") test 'bimc 1384 (not div-zero-error?)' krazy-loop-incorrect krazy-loop-incorrect-bimc2.out ;;


# SBC
# ---

# Here, we compile each program into a simpler set of rules specific to that
# program. Compilation must be run with `--search` so that when the state of
# symbolic execution splits at branch points (eg. `if(_)_else_` in IMP) we collect
# rules for both branches.

# ### Straight Line

# Straight line programs should yield one rule which summarizes the effect of the
# entire program on the IMP memory.

# `straight-line-1` just has the effect of setting `x` to 15, skipping all
# intermediate steps.


"straight-line-1-sbc") test 'compile' straight-line-1.imp straight-line-1-sbc.out ;;


# `straight-line-2` just has the effect of setting `x` to 5, skipping all
# intermediate steps. Note that before setting it to `5`, the original program
# sets it to 0 and then 15, but the generated program does not have these steps.
# Because we are using the operational semantics of the language directly, we get
# this dead-code elimination practically for free.


"straight-line-2-sbc") test 'compile' straight-line-2.imp straight-line-2-sbc.out ;;


# ### Dead `if`

# Because we are compiling using symbolic execution, we will often know if a
# branch is dead (only ever evaluates to `true`/`false`). In the `dead-if`
# program, the condition on the `if` is always true, so our rule summary only
# generates a single rule corresponding to the true branch of the `if`. Once
# again, because we are using symbolic execution of the operational semantics
# directly, we get this branch elimination for free.


"dead-if-sbc") test 'compile' dead-if.imp dead-if-sbc.out ;;


# ### Sum and Sum Plus

# Sum should generate three rules:

# 1.  One rule to get us to the beginning of the `while` loop (initialization).
# 2.  One rule corresponding to jumping over the `while` loop (if the condition on
#     the loop is false).
# 3.  One rule corresponding to an iteration of the `while` loop (if the condition
#     on the loop is true).


"sum-sbc") test 'compile' sum.imp sum-sbc.out ;;


# Sum Plus should generate the same rules, but the rule for the false branch of
# the `while` loop should also include the effect of the code after the `while`
# loop (rule 2').


"sum-plus-sbc") test 'compile' sum-plus.imp sum-plus-sbc.out ;;


# ### Collatz {#collatz-1}

# Finally, we pick a program that has a conditional inside the `while` loop.
# Indeed, we get a summary of the Collatz program with four rules:

# 1.  A rule that gets us to the beginning of the `while` loop (initialization).
# 2.  A rule that gets us past the `while` loop once we reach 1.
# 3.  A rule that has the effect of the `while` loop if the branch inside is false
#     (roughly, "if the number is not 1 and odd, multiply by 3 and add 1").
# 4.  A rule that has the effect of the `while` loop if the branch inside is true
#     (roughly, "if the number is not 1 and even, divide it by 2").

# Rules 1 and 2 above will be generated in both solutions for `--search`, but
# rules 3 and 4 are each only generated in one of the solutions. Note that we
# effectively get a "summary" of the Collatz algorithm which is independent of how
# it's written down in IMP.


"collatz-sbc") test 'compile' collatz.imp collatz-sbc.out ;;


# ### Collatz All {#collatz-all-1}


"collatz-all-sbc") test 'compile' collatz-all.imp collatz-all-sbc.out ;;


# ### Krazy Loop {#krazy-loop-1}


"krazy-loop-incorrect-sbc") test 'compile' krazy-loop-incorrect.imp krazy-loop-incorrect-sbc.out ;;



"krazy-loop-correct-sbc") test 'compile' krazy-loop-correct.imp krazy-loop-correct-sbc.out ;;
esac
done


# SBC Benchmarking
# ----------------

# The above `compile` result for Collatz corresponds to the following K
# definition. We've replaced the `k` cells with constants, which can be done
# automatically using hashing but here is done manually.

# -   `INIT` corresponds to the entire program:
#     `int n , ( x , .Ids ) ; n = 782 ; x = 0 ; while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; }`
# -   `LOOP` corresponds to just the loop:
#     `while ( 2 <= n ) { if ( n <= ( ( n / 2 ) * 2 ) ) { n = n / 2 ; } else { n = 3 * n + 1 ; } x = x + 1 ; }`
# -   `FINISH` corresponds to the final state: `.`

# Here is the compiled version of Collatz all, which checks every Collatz number
# up to 10.

# -   `INIT` corresponds to the entire program.
# -   `OUTER` corresponds to the program starting at the outer `while` loop.
# -   `INNER` corresponds to the program starting at the inner `while` loop.
# -   `FINISHED` corresponds to the completed program.

# ### Concrete Execution Time

# First we'll demonstrate that execution time decreases drastically by running
# `collatz.imp` with the original semantics, and running `INIT` with the new
# semantics. Note that in both cases this is not as fast as an actual compiled
# definition could be because we're still using the strategy harness to control
# execution (which introduces overhead).

# And we also are timing the `collatz-all` program concretely:

#   program       concrete (ms)   compiled (ms)
#   ------------- --------------- ---------------
#   collatz       31952           2782
#   collatz-all                   
# 

# ### BIMC Execution Time

# In addition to concrete execution speedup, we get a speedup in the other
# analysis tools that can be run after SBC. Here we'll check the runtime of BIMC
# for the Collatz program, then compare to the time of BIMC of the system
# generated by SBC.

# To do this, we'll find the highest number that is reached on Collatz of 782 by
# incrementally increasing the maximum bound we check for as an invariant.

# The first number is the `bound` on how high we'll let Collatz go. The second
# number is the number of steps it took to get there. The third number is how long
# it took to run on my laptop on a Sunday.

#   bound   concrete (ms)   compiled (ms)   speedup
#   ------- --------------- --------------- ---------
#   1000    2154            596             3.61
#   1174    3378            818             4.13
#   1762    4497            966             4.66
#   2644    43825           4673            9.78
#   3238    45397           4521            10.04
#   4858    44939           4707            9.55
#   7288    53164           5209            10.21
#   9323    71187           6851            10.39
# 
