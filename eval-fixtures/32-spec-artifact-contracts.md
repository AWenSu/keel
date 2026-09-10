# Fixture 32: spec-artifact contracts — seams, glossary, and their carriers (S2, S3, S4, S5, S6)

**Rule source:** `skills/keel-plan/SKILL.md` "Tests only at confirmed seams" (task-writing rules, §3a).
**Rule source:** `skills/keel-debug/SKILL.md` Phase 1 (loop construction #1) and Phase 5 (Fix + regression test).
**Rule source:** `skills/keel-discover/SKILL.md` Domain-language discipline (Clarify step) and step 1 (Ground yourself in evidence).
**Rule source:** `skills/keel-plan/SKILL.md` Workflow step 1 (Scope check, then map files).
**Rule source:** `skills/keel-execute/SKILL.md` Universal rules (both modes) — Glossary.
**Rule source:** `agents/keel-exec-implementer.md` Code intelligence.
**Rule source:** `agents/keel-exec-reviewer-quality.md` Standards, in priority order.
**Rule source:** `agents/keel-exec-fixer.md` Code intelligence.
**Rule source:** `agents/keel-exec-fixer-critical.md` Glossary.
**Rule source:** `skills/keel-finish/SKILL.md` Part 2: Success criteria check.

These five rules bind spec-authored artifacts (confirmed seams,
`CONTEXT.md`'s glossary) onto every downstream stage that reads them. All
five belong to the family the S-section's own header names: mechanisms that
were wired into skills without ever getting an inventory row, so a run that
silently violates one leaves no red check anywhere — the exact laundering
this directory exists to catch. Section S also states, in
`RULE-INVENTORY.md`'s ceiling note, that S2–S6 are "read-and-obey rules with
no trigger boundary." That framing undersells them: each one below does have
an enumerable boundary (confirmed vs. unconfirmed seam; seam vs. no-seam;
`CONTEXT.md` present vs. absent) — it just isn't a dispatch-trigger boundary
the way a lens or a gate has. This fixture walks those boundaries.

## S2-A — plan wants a seam the spec never confirmed

**Scenario:** the spec's `## Test seams` section lists two seams: the public
`refund()` API and the webhook receiver. `keel-plan` is writing task 4, which
needs to assert on an internal `RefundLedger.pendingEntries` field no seam in
the spec exposes — the reviewer flagged the public API as too coarse to catch
the bug this task fixes.

**Expected:** stop and treat this as a spec gap, not a planning judgment call:

> A task that needs an unconfirmed seam is a
> design change: stop and take it back to the spec.

**Not expected:** the planner inventing a new seam on the spot because it
"obviously" should exist, or writing the test against
`RefundLedger.pendingEntries` directly and noting it as an implementation
detail. The rule's own framing of what that produces:

> a seam list under any other name is a spec
> with no seams, and every task then invents its own

## S2-B — the spec predates seam negotiation entirely

**Scenario:** an older spec, written before `keel-discover` step 5b existed,
has no `## Test seams` section at all. `keel-plan` is about to write its
first task.

**Expected:** propose the seam list before any task is written, not per-task
as the need arises:

> If the spec predates
> seam negotiation and has no Test seams section, propose the seam list to
> the user before writing any task.

**Not expected:** each task author picking its own seam ad hoc because "the
spec doesn't say"; treating the missing section as permission rather than as
the same design-change trigger as S2-A.

## S3-A — the correct seam exists; debug must reproduce through it, not the internal call

**Scenario:** the spec's confirmed seam for this subsystem is the public
`refund()` API. The bug is in `RefundLedger`'s internal reconciliation logic,
several calls deep. `keel-debug` is about to build the Phase 1 loop and
notices it would be faster to call the private reconciliation method directly
from a test harness, skipping `refund()` entirely.

**Expected:** the loop is built at the seam the pipeline already confirmed,
not the shortest path to the suspected line:

> 1. **Failing test** at whatever seam reaches the bug (prefer the spec's
>    confirmed seams if this code went through the pipeline)

and the regression test in Phase 5 exercises the bug the way it actually
occurs for a caller, not the way it's easiest to trigger from inside:

> Write the regression test **before the fix**, at a correct seam — one that
> exercises the real bug pattern as it occurs at the call site.

**Not expected:** a throwaway harness that calls the private method directly
and calls that the loop, with the fact that `refund()` was available and
unused going unmentioned.

## S3-B — no seam reaches the bug at all

**Scenario:** the bug is in a helper with no public entry point anywhere in
the call chain that a test could exercise without reaching into internals —
no confirmed seam, no reasonable substitute.

**Expected:** this is itself a reportable gap, not silent license to test the
internal directly and move on:

> A too-shallow
> seam gives false confidence; **if no correct seam exists, that itself is a
> finding** — record it and flag the architecture gap to the user (a
> keel-discover candidate).

**Not expected:** writing a test against the internal method with no note in
the report; treating "I found a way to trigger it" as equivalent to "I found
a correct seam."

*(Note for the grader: unlike S2's keel-plan text, which explicitly bars
"no internals, no private methods, no side channels," `keel-debug`'s own
wording never uses the word "internals" — it says *prefer* the confirmed
seam and *record as a finding* when none exists. The inventory row's gloss —
"not through internals" — is this fixture's paraphrase of that spirit, not a
literal phrase in the file. A grader should walk the two quotes above, not
search `keel-debug/SKILL.md` for the word "internals.")*

## S4-A — a new task's name collides with an existing glossary term

**Scenario:** the repo's `CONTEXT.md` defines **Cancellation** as "the user
withdraws before fulfillment starts." `keel-plan` is naming a task about a
different, later-stage flow and is about to call it "Cancel Order" because
that's the button label in the mockup.

**Expected:** the existing term binds; task names and new symbols must use
it, and re-using the word for something else is flagged rather than shipped:

> Read `CONTEXT.md` at the repo root if it exists — the project's domain
> glossary. Task names, new symbols, and Interfaces blocks must use its
> vocabulary; a plan that renames a glossary concept is planting an
> inconsistency.

**Not expected:** naming the task "Cancel Order" because that matches the UI
copy, silently creating a second meaning for "cancel" that the glossary
doesn't carry.

## S4-B — the same collision one stage earlier, at discovery

**Scenario:** during `keel-discover`'s clarifying questions, the user
describes the new flow using the word "cancel" — the same word `CONTEXT.md`
already defines for the withdraw-before-fulfillment case.

**Expected:** the conflict is surfaced immediately, not carried forward
silently into the spec for `keel-plan` to inherit:

> **Challenge conflicts.** The user uses a term that contradicts `CONTEXT.md`
> → call it out immediately: "Glossary defines 'cancellation' as X, you seem
> to mean Y — which is it?"

**Not expected:** writing the spec with the user's overloaded sense of
"cancel" and letting S4-A's task-naming check discover the collision later,
which is strictly more expensive than resolving it at the source.

## S5-A — `CONTEXT.md` exists: both implementer and reviewer briefs carry it

**Scenario:** ORCHESTRATED execution, repo has a `CONTEXT.md`. The controller
is composing task 3's implementer brief and its quality-reviewer brief.

**Expected:** the controller's own universal rule requires the path in both:

> **Glossary:** if `CONTEXT.md` exists at the repo root, include its path in
> every implementer/reviewer brief — code and test names follow its
> vocabulary.

and each of the two named consumers is independently checked to actually act
on it. `keel-exec-implementer.md`:

> If `CONTEXT.md` exists at the repo root, your code and test names follow its
> vocabulary.

`keel-exec-reviewer-quality.md`:

> 1. **The repo's own standards** — existing conventions, linter config,
>    `CONTEXT.md` vocabulary if present. Matching surrounding code beats
>    matching your taste.

**Not expected:** a brief that omits the path when `CONTEXT.md` exists; an
implementer naming a new symbol without checking the glossary because "the
brief didn't mention it."

## S5-B — the same task, dispatched to the fixer instead of the implementer

**Scenario:** task 3's implementer brief carried the `CONTEXT.md` path as in
S5-A. Two review rounds later, the fixer (`keel-exec-fixer`) is dispatched to
resolve a finding on the same diff — new code, same file, same glossary in
scope.

**Expected — per the universal rule's own wording, which does not name a
role exception:**

> include its path in
> every implementer/reviewer brief

**Not expected:** treating "implementer/reviewer" as excluding the fixer
because it wasn't named in this row's `Enforced at` column, and letting the
fixer name a new symbol however it likes.

and, since 2026-09-11, at the fixer's own end too. `keel-exec-fixer.md`:

> If `CONTEXT.md` exists at the repo root, your code and test names follow its
> vocabulary. You write code in the fix loop, so the glossary binds you exactly
> as it binds the implementer — a fix that renames a glossary concept plants
> the same inconsistency, later and in a smaller diff where it is harder to see.

`keel-exec-fixer-critical.md`, where a fresh context makes it easier to miss:

> If `CONTEXT.md` exists at the repo root, your code and test names follow its
> vocabulary. Arriving with a fresh context is what makes this easy to miss:
> the vocabulary the earlier attempts were using is not in your memory, it is
> in that file.

*(Note for the grader: until 2026-09-11 both fixer agents contained zero
references to `CONTEXT.md` — the universal rule's "every
implementer/reviewer brief" read as though it covered the fixer, but the
fixer was the one code-writing agent in the fix loop the chain never
reached. The audit that produced this fixture found it; this sub-scenario
is now that fix's regression check rather than a live gap.)*

## S6-A — a new domain term surfaces at Finish, `CONTEXT.md` exists

**Scenario:** during execution, the implementer introduced the term "cooldown
window" for a new rate-limit concept. It's used consistently in code and
tests but was never added to `CONTEXT.md`. `keel-finish` Part 2 is running
its success-criteria check.

**Expected:** the check happens, and any mismatch is reported — but Part 2
does not become a rename pass:

> If `CONTEXT.md` exists: any new domain term this work introduced belongs in
> it, and public names in the diff should match its vocabulary. One-line check,
> report mismatches — don't rename code at this stage.

**Not expected:** `keel-finish` silently editing code to match the glossary,
or silently skipping the check because "nothing broke."

*(Note for the grader: the sentence stops at "report mismatches" — it never
says who edits `CONTEXT.md` or when. The inventory row's phrasing, "New
domain terms ... are added to `CONTEXT.md` before integration," reads as an
action; the actual text reads as a check-and-report. Whether "cooldown
window" ever gets written into `CONTEXT.md` is not settled by this
paragraph — that is a real gap, not a strict quote mismatch, and belongs in
this fixture's findings rather than in a PASS/FAIL on the quote itself.)*

## S6-B — the same scenario, no `CONTEXT.md` in the repo

**Scenario:** identical to S6-A, except the repo has never had a
`CONTEXT.md`.

**Expected:** the check is conditional and simply doesn't fire:

> If `CONTEXT.md` exists: any new domain term this work introduced belongs in
> it

**Not expected:** blocking integration over a missing glossary the project
never opted into; inventing a `CONTEXT.md` at Finish time to satisfy a check
that was never triggered.

*(Note for the grader: unlike D14 in fixture `26` — where the no-`.learned/`
branch has a named place to say so, once, in the ledger header — Part 2 has
no equivalent instruction to disclose "no `CONTEXT.md`, skipped." The
paragraph is silent on the negative branch. Under fixture `26`'s own
standard — "every no-rulebook path has a named place to say so" — this is a
smaller instance of the same class, not a new one: nothing here blocks or
requires action, but nothing requires the absence to be stated either.)*

## Not expected (any scenario)

- A task naming or testing an unconfirmed seam without first taking it back
  to the spec as a design change (S2)
- A debug loop or regression test built against an internal call when a
  confirmed seam exists, or a missing-seam workaround left unreported (S3)
- A glossary conflict — at discovery or at planning — resolved by quietly
  picking one meaning instead of surfacing the collision (S4)
- An implementer, reviewer, or fixer brief silently missing the `CONTEXT.md`
  path when the file exists, on the theory that only two agent names appear
  in the inventory's `Enforced at` column (S5)
- `keel-finish` Part 2 renaming code to match the glossary, or treating a
  reported new-term mismatch as resolved without anyone actually updating
  `CONTEXT.md` (S6)
