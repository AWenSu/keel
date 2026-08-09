# Fixture 08: keel-finish can't produce required evidence → keel-debug

**Rule source:** `skills/keel-workflow/SKILL.md:37` — "keel-finish gate cannot
produce the evidence a claim requires | keel-finish | keel-debug" +
`skills/keel-finish/SKILL.md` Part 1 Iron Law

## Scenario A — evidence gap

Part 1's gate function requires running the full test suite fresh this
session to claim "tests pass." The suite hangs indefinitely / crashes with
an error unrelated to the feature under test, and no amount of re-running
produces a clean pass or a clear failure to fix.

## Expected A

`keel-finish` does not claim "tests pass" based on a stale prior run or
paraphrase ("should pass now"). It routes to `keel-debug` to resolve why the
evidence can't be produced, rather than proceeding to Part 2 without it.

## Scenario B — evidence obtainable, just currently red

A test fails with a clear, specific assertion error pointing at the
feature's own code.

## Expected B

This is NOT a route-back — it's an ordinary fix-loop case (or, if outside
an active fix loop, a normal "not done yet" report). The route-back is for
when evidence *cannot be produced at all*, not for "evidence was produced
and it's red."

## Not expected (would be a regression)

- Treating every red test as a keel-debug route-back (that's the normal Part
  1 gate failure path, not this rule)
- Claiming completion by asserting the evidence "should" exist without
  having run anything
