# Running KAT
# ===========

# BIMC
# ----

# Here, we allow each program to initialize (get through variable declarations) by
# running `step-with skip`. Then we issue some `bimc` query to check if the
# program obeys the given invariant up to the depth-bound.

# ### Straight Line 1

# Assertion not violated at step 2:


krun --directory '../' -cSTRATEGY='step-with skip ; bimc 2 (bexp? x <= 7)' straight-line-1.imp


# Assertion violation at step 3:


krun --directory '../' -cSTRATEGY='step-with skip ; bimc 3 (bexp? x <= 7)' straight-line-1.imp


# ### Straight Line 2

# Assertion not violated up to step 2:


krun --directory '../' -cSTRATEGY='step-with skip ; bimc 2 (bexp? x <= 7)' straight-line-2.imp


# Assertion violated at step 3:


krun --directory '../' -cSTRATEGY='step-with skip ; bimc 3 (bexp? x <= 7)' straight-line-2.imp


# Assertion still violated at step 3 (with extended bound):


krun --directory '../' -cSTRATEGY='step-with skip ; bimc 500 (bexp? x <= 7)' straight-line-2.imp


# ### Sum

# Query with large bound to find which step pushed the sum above `32`:


krun --directory '../' -cSTRATEGY='step-with skip ; bimc 500 (bexp? s <= 32)' sum.imp


# Show that the returned number is the correct step that an assertion violation
# happens at:


krun --directory '../' -cSTRATEGY='step-with skip ; bimc 40 (bexp? s <= 32)' sum.imp


# And that one step prior the assertion was not violated:


krun --directory '../' -cSTRATEGY='step-with skip ; bimc 39 (bexp? s <= 32)' sum.imp


# ### Collatz

# Check if calculating Collatz of 782 ever goes above 10000:


krun --directory '../' -cSTRATEG='step-with skip ; bimc 5000 (bexp? n <= 10000)' collatz.imp


# SBC
# ---

# Here, we compile each program into a simpler set of rules specific to that
# program.

# ### Straight Line

# Straight line programs should yield one rule which summarizes the effect of the
# entire program on the IMP memory.

# `straight-line-1` just has the effect of setting `x` to 15, skipping all
# intermediate steps.


krun --directory '../' -cSTRATEGY='compile' straight-line-1.imp


# `straight-line-2` just has the effect of setting `x` to 5, skipping all
# intermediate steps. Note that before setting it to `5`, the original program
# sets it to 0 and then 15, but the generated program does not have these steps.
# Because we are using the operational semantics of the language directly, we get
# this dead-code elimination practically for free.


krun --directory '../' -cSTRATEGY='compile' straight-line-2.imp


# ### Dead `if`

# Because we are compiling using symbolic execution, we will often know if a
# branch is dead (only ever evaluates to `true`/`false`). In the `dead-if`
# program, the condition on the `if` is always true, so our rule summary only
# generates a single rule corresponding to the true branch of the `if`. Once
# again, because we are using symbolic execution of the operational semantics
# directly, we get this branch elimination for free.


krun --directory '../' -cSTRATEGY='compile' dead-if.imp


# ### Sum and Sum Plus

# Sum should generate three rules:

# 1.  One rule to get us to the beginning of the `while` loop (initialization).
# 2.  One rule corresponding to an iteration of the `while` loop (if the condition
#     on the loop is true).
# 3.  One rule corresponding to jumping over the `while` loop (if the condition on
#     the loop is false).


krun --directory '../' -cSTRATEGY='compile' sum.imp


# Sum Plus should generate the same rules, but the rule for the false branch of
# the `while` loop should also include the effect of the code after the `while`
# loop.


krun --directory '../' -cSTRATEGY='compile' sum-plus.imp


# ### Collatz {#collatz-1}

# Finally, we pick a program that has a conditional inside the `while` loop.
# Because the conditional splits execution state, we must use `--search` instead
# to get all paths. Indeed, we get a summary of the Collatz program with four
# rules:

# 1.  A rule that gets us to the beginning of the `while` loop (initialization).
# 2.  A rule that has the effect of the `while` loop if the branch inside is true
#     (roughly, "if the number is not 1 and even, divide it by 2").
# 3.  A rule that has the effect of the `while` loop if the branch inside is false
#     (roughly, "if the number is not 1 and odd, multiply by 3 and add 1").
# 4.  A rule that gets us past the `while` loop once we reach 1.

# Rules 1 and 4 above will be generated in both solutions for `--search`, but
# rules 2 and 3 are each only generated in one of the solutions. Note that we
# effectively get a "summary" of the Collatz algorithm which is independent of how
# it's written down in IMP.


krun --directory '../' --search -cSTRATEGY='compile' collatz.imp

