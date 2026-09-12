# Fixture 38: the author is given the bar it will be graded against (D23)

**Rule source:** `agents/keel-exec-implementer.md` Standards you write to.
**Rule source:** `skills/keel-execute/SKILL.md` ORCHESTRATED per-task loop step 2.

Found 2026-09-13 while auditing the coding side after the review side was
tightened: `smells.md` and `keel-discover/design.md` were named only in the
**reviewer's** brief. The implementer — the agent actually writing the code —
had never been given either, and was then graded against both. Every smell
that a two-minute read would have prevented instead cost a review round, a fix
round, and a re-review.

## A — the implementer brief carries both paths

**Scenario:** ORCHESTRATED execution, task 3 about to be dispatched.

**Expected:** the brief names the same two standards documents the quality
reviewer will be given:

> **The brief carries the same two standards paths the
> quality reviewer gets** — [smells.md](smells.md) and
> `keel-discover/design.md` — because an author graded against a bar it was
> never shown turns every avoidable smell into a review round.

**Not expected:** a brief carrying only `Delivers` / `Files` / `Interfaces` /
`Skills` on the theory that quality is the reviewer's department. Grading is
the reviewer's department; meeting the bar is the author's, and it cannot meet
a bar it has not read.

## B — the order is the same order, and the repo wins

**Scenario:** `smells.md` names a pattern the repo uses everywhere anyway.
The implementer is deciding which to follow.

**Expected:** the repo, by the priority the implementer is given — the same
priority the reviewer grades by:

> 1. **The repo's own conventions** — existing patterns, linter config,
>    `CONTEXT.md` vocabulary. Matching the surrounding code beats matching your
>    taste, and beats matching the other two below.

**Not expected:** the implementer "improving" surrounding code to match
`smells.md` — that is scope creep, which its own Scope section already
forbids, and it would be graded as such.

## C — reading is not optional because grading is not conditional

**Scenario:** a small task. The implementer skips reading `smells.md` to save
context, planning to fix anything the reviewer raises.

**Expected:** the trade is stated and it does not favour skipping:

> You are graded on these whether or not you read them, so reading them is
> strictly cheaper: a smell you avoid costs one minute, and the same smell found
> in review costs a review round, a fix round, and a re-review.

**Not expected:** treating the review loop as the place quality gets added.
The loop exists to catch what the author could not foresee, not to substitute
for what it declined to read.

## D — this does not turn the implementer into a reviewer

**Scenario:** the implementer, now holding the smell baseline, files a report
listing three smells it noticed in neighbouring untouched files.

**Expected:** out of scope on two counts. Its Scope section:

> Implement what the task's `Delivers:` line says. Nothing adjacent, nothing
> "while I'm here." Scope creep is a review failure, not a bonus.

and pre-existing untested code specifically:

> Pre-existing untested code in the repo
> is not yours to delete — if the task requires changing it, note the missing
> coverage as a concern and work within it.

The standards were given so the author writes to them, not so it audits the
repo against them.

**Not expected:** a task diff that also cleans up three neighbouring smells; a
report that reads as a review of someone else's code.

## Not expected (any scenario)

- An implementer brief without both standards paths
- The implementer resolving a conflict between the repo and `smells.md` in
  favour of `smells.md`
- Skipping the read on the grounds that review will catch it
- The implementer acting on the standards outside its own task's diff
