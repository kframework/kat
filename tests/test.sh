# IMP-KAT Tests
# =============

# We'll use a simple testing harness in `bash` which just checks the output of
# `krun --search` against a supplied file. Run this with `bash runtests.sh`.


gecho() {
    echo -e '\e[32m'$@'\e[39m'
}
recho() {
    echo -e '\e[31m'$@'\e[39m'
}
strip_output() {
    grep -v -e '^$' -e '^\s*//' | tr '\n' ' ' | tr --squeeze-repeats ' '
}

return_code="0"

test() {
    strategy="$1"
    imp_file="$2"
    out_file="output/$3"
    for file in "$imp_file" "$out_file"; do
        [[ ! -f "$file" ]] && recho "File '$out_file' does not exist ..." && exit 1
    done

    echo -e "Running '$imp_file' with '$strategy' and comparing to '$out_file' ..."
    diff <(cat "$out_file" | strip_output) <(krun --search --directory '../' -cSTRATEGY="$strategy" "$imp_file" | strip_output)
    if [[ "$?" == '0' ]]; then
        gecho "SUCCESS"
    else
        recho "FAILURE"
        return_code="1"
    fi
}


# BIMC
# ----

# Here, we allow each program to initialize (get through variable declarations) by
# running `step-with skip`. Then we issue some `bimc` query to check if the
# program obeys the given invariant up to the depth-bound.

# ### Straight Line 1

# Assertion not violated at step 2:


test 'step-with skip ; bimc 2 (bexp? x <= 7)' straight-line-1.imp straight-line-1-bimc1.out


# Assertion violation at step 3:


test 'step-with skip ; bimc 3 (bexp? x <= 7)' straight-line-1.imp straight-line-1-bimc2.out


# ### Straight Line 2

# Assertion not violated up to step 2:


test 'step-with skip ; bimc 2 (bexp? x <= 7)' straight-line-2.imp straight-line-2-bimc1.out


# Assertion violated at step 3:


test 'step-with skip ; bimc 3 (bexp? x <= 7)' straight-line-2.imp straight-line-2-bimc2.out


# Assertion still violated at step 3 (with extended bound):


test 'step-with skip ; bimc 500 (bexp? x <= 7)' straight-line-2.imp straight-line-2-bimc3.out


# ### Sum

# Query with large bound to find which step pushed the sum above `32`:


test 'step-with skip ; bimc 500 (bexp? s <= 32)' sum.imp sum-bimc1.out


# Show that the returned number is the correct step that an assertion violation
# happens at:


test 'step-with skip ; bimc 41 (bexp? s <= 32)' sum.imp sum-bimc2.out


# And that one step prior the assertion was not violated:


test 'step-with skip ; bimc 40 (bexp? s <= 32)' sum.imp sum-bimc3.out


# ### Collatz

# Here we test if the Collatz sequence for `782` contains any numbers greater than
# `1000`.


test 'step-with skip ; bimc 5000 (bexp? n <= 1000)' collatz.imp collatz-bimc.out


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


test 'compile' straight-line-1.imp straight-line-1-sbc.out


# `straight-line-2` just has the effect of setting `x` to 5, skipping all
# intermediate steps. Note that before setting it to `5`, the original program
# sets it to 0 and then 15, but the generated program does not have these steps.
# Because we are using the operational semantics of the language directly, we get
# this dead-code elimination practically for free.


test 'compile' straight-line-2.imp straight-line-2-sbc.out


# ### Dead `if`

# Because we are compiling using symbolic execution, we will often know if a
# branch is dead (only ever evaluates to `true`/`false`). In the `dead-if`
# program, the condition on the `if` is always true, so our rule summary only
# generates a single rule corresponding to the true branch of the `if`. Once
# again, because we are using symbolic execution of the operational semantics
# directly, we get this branch elimination for free.


test 'compile' dead-if.imp dead-if-sbc.out


# ### Sum and Sum Plus

# Sum should generate three rules:

# 1.  One rule to get us to the beginning of the `while` loop (initialization).
# 2.  One rule corresponding to jumping over the `while` loop (if the condition on
#     the loop is false).
# 3.  One rule corresponding to an iteration of the `while` loop (if the condition
#     on the loop is true).


test 'compile' sum.imp sum-sbc.out


# Sum Plus should generate the same rules, but the rule for the false branch of
# the `while` loop should also include the effect of the code after the `while`
# loop (rule 2').


test 'compile' sum-plus.imp sum-plus-sbc.out


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


test 'compile' collatz.imp collatz-sbc.out

exit $return_code


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

# ### Concrete Execution Time

# First we'll demonstrate that execution time decreases drastically by running
# `collatz.imp` with the original semantics, and running `INIT` with the new
# semantics. Note that in both cases this is not as fast as an actual compiled
# definition could be because we're still using the strategy harness to control
# execution (which introduces overhead).

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

# 1.  1000 at 20 steps in 19s
# 2.  1174 at 40 steps in 22s
# 3.  1762 at 60 steps in ??s
# 4.  2644 at 730 steps in 2m34s
# 5.  3238 at 750 steps in 3m07s
# 6.  4858 at 770 steps in 3m44s
# 7.  7288 at 870 steps in 9m01s
# 8.  9232 at ??? steps in ?m??s
