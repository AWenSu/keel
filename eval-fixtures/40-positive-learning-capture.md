# Fixture 40: the branch that taught you a better way, and nothing broke (D25)

**Rule source:** `skills/keel-finish/SKILL.md` Part 2e: Promote findings to the project rulebook.

Part 2e's steps 1–4 admit four shapes, and all four are failures: more than
one attempt, a tool contradicting its docs, a reviewer finding with no
matching rule, a premise the code refuted. A branch where you learned a
*better way to do something that was never broken* produces none of them, so
before 2026-09-14 it left no trace anywhere in the pipeline. Step 5 asks that
question once, with two gates stricter than the ones above it — because a
pattern is easier to record than a failure and far more likely to be wrong
somewhere else.

## A — the question is asked even when nothing went wrong

**Scenario:** a clean branch. Every task passed first review, no fix rounds,
`.keel/findings.md` has one entry that steps 1–3 correctly drop as a one-off.
The controller is about to report "no new rules".

**Expected:** step 5 still runs, because steps 1–4 structurally cannot see
what it is looking for:

> Steps
> 1-4 admit only failure shapes — needed more than one attempt, behaved
> counter to its docs, refuted a premise — so a branch where you learned a
> *better way to do something that was never broken* leaves no trace.

and the question is specific, not "any thoughts?":

> **did this branch teach an approach you would now reach for instead of what
> you would otherwise have written?**

**Not expected:** skipping step 5 because steps 1–4 produced nothing — that is
exactly the branch it exists for.

## B — cannot name what it replaces → do not record it

**Scenario:** while working, the implementer read a library's source and found
its error-handling shape elegant. Asked what it replaces, the answer is "it's
just cleaner".

**Expected:** not recorded:

> **Name what it replaces.** State the inferior thing you would otherwise
> have written, concretely, and why it is worse. Cannot name it → do not
> record it: you admired something you do not yet understand well enough to
> reuse, and recording that is how a cargo cult starts.

**Not expected:** recording it with a vaguer title and filling the gap later.
The gate is about the author's understanding, not the wording — and "later"
is when nobody remembers the context that would have made the comparison
possible.

## C — the boundary is part of the rule, not a caveat on it

**Scenario:** a genuinely good pattern, and the author can name what it
replaces. The "where it does not apply" answer offered is "use judgment".

**Expected:** insufficient, and the reason is a claim about this class of
knowledge specifically:

> **Name where it does not apply.** Cross-project patterns are the most
> context-dependent knowledge there is — a shape that is right for a
> high-throughput service is wrong for a CLI — so the boundary is part of
> the rule, not a caveat on it.

**Not expected:** treating the boundary as optional polish. A rulebook that
mounts into other projects hands this pattern to a context the author never
saw; the boundary is the only thing travelling with it that says "not here".

## D — reach decides which rulebook, not importance

**Scenario:** two survivors. One is about this repo's own build script. The
other would change how the author designs a queue consumer anywhere.

**Expected:** split by reach:

> something true only of this repo is a local
> rule like any other; something that would change how you *design* in a
> different project belongs in the cross-project rulebook this repo mounts
> (its path is in `.learned/config.local.json`), written there rather than
> here.

**Not expected:** promoting the build-script rule globally because it felt
important, or keeping the design pattern local because it was learned here.
Importance is not reach.

**Boundary — no cross-project rulebook is mounted:** the local rulebook takes
it, and the mount's absence is not a reason to discard the finding.

## E — "nothing this round" is the common answer

**Scenario:** an ordinary branch. Nothing was learned that meets both gates.

**Expected:** said, not skipped, and the honest answer is expected to be the
usual one:

> "Nothing this round" is the common answer and is said, not skipped —
> a pattern invented to fill this step is worse than an empty one.

**Not expected:** a pattern manufactured to make the step productive; the step
omitted from the summary because the answer was empty.

## Not expected (any scenario)

- Step 5 skipped on a branch where steps 1–4 found nothing
- A pattern recorded without a concrete statement of what it replaces
- A boundary given as "use judgment" or omitted
- Reach confused with importance when choosing the rulebook
- An empty answer left unsaid, or filled with an invented pattern
