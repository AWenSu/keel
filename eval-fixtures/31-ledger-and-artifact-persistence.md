# Fixture 31: ledger and artifact persistence (H1, H2, H3, H4, H5, H6, H7)

**Rule source:** `skills/keel-execute/SKILL.md` Progress ledger — crash safety.
**Rule source:** `skills/keel-execute/SKILL.md` Universal rules (both modes).
**Rule source:** `skills/keel-execute/SKILL.md` ORCHESTRATED per task loop, step 5.
**Rule source:** `skills/keel-execute/SKILL.md` INLINE mode.
**Rule source:** `skills/keel-execute/SKILL.md` Finish.
**Rule source:** `skills/keel-workflow/SKILL.md` Pipeline state file.
**Rule source:** `skills/keel-plan-review/SKILL.md` Step 5: Ask the user, then apply edits + final gate.
**Rule source:** `skills/keel-finish/SKILL.md` Part 2: Success criteria check.
**Rule source:** `skills/keel-finish/SKILL.md` Part 2c: Security exit gate — Risk-acceptance decisions.
**Rule source:** `skills/keel-finish/SKILL.md` Part 3: Integrate the branch.
**Rule source:** `agents/keel-exec-implementer.md` Report.

Seven persistence rules, all with the same shape: a stage writes an artifact
so a *later* stage or a *crashed and resumed* session doesn't have to trust
memory. Every one of them has a silent-omission branch that looks identical
to the honest version unless something specifically checks for it.

## H1 — ledger line appended per completed task

**Scenario A:** ORCHESTRATED mode, Task 3 finishes DONE after one review
round with two findings fixed.

**Expected:**

> Append one line per completed task to `.keel/progress.md`:

with the completed-task fields the rest of that section defines (status,
commit, branch, relocated, security, findings). The task line carries the
implementer's status verbatim:

> The task line **carries the implementer's returned status verbatim** —
> `DONE`, `DONE_WITH_CONCERNS`, and so on.

**Not expected:** a paraphrased status ("looks fine", "mostly done") in
place of the verbatim value — `keel-finish` Part 2b reconciles
`DONE_WITH_CONCERNS` entries out of this file and cannot see a status that
was smoothed over.

**Scenario B — a task never completes; round 5 trips the circuit breaker.**
Task 5's fix loop reaches round 5 with one finding still open, and it breaks
a `Delivers:` line.

**Expected:** the finding is load-bearing, so:

> load-bearing (breaks a Delivers: line, security, data
> integrity) → `BLOCKED`, report to the user, do not mark the task done;

Since the ledger line is defined as "one line per **completed** task" and
this task is explicitly not marked done, no completed-task ledger line gets
written for Task 5 — the BLOCKED report to the user is what carries the
outcome instead, not a ledger row claiming completion.

**Not expected:** writing a ledger line for Task 5 anyway with status
`BLOCKED` dressed up as if it were a normal completed-task entry; treating
the round-5 report to the user as optional because "the ledger will show it
next round."

## H2 — `.keel/state.md` updated per transition

**Scenario A:** ORCHESTRATED mode, end of Task 3's per-task loop.

**Expected:**

> then **ledger append** (see
> below), update `.keel/state.md`, next task.

(Step 5 gained a first clause on 2026-09-11 — driving any critical flow that
can now run, graded in fixture `34` — but the state.md half is unchanged and
still shares the beat.) It implements the router's own declaration of the
file's purpose:

> Maintain `.keel/state.md`, overwritten on every stage transition and
> every task completion.

**Not expected:** updating `.keel/progress.md` without also overwriting
`.keel/state.md` — the two files answer different questions ("what
finished" vs. "where you are") and a controller resuming after compaction
needs both.

**Scenario B — the same task, but the branch is running INLINE (no
subagents available).** Task 3 finishes in the single INLINE session.

**Expected:** both files, on the same beat. Until 2026-09-11 the INLINE step
named only the ledger, which left `.keel/state.md` with no carrier anywhere
in the mode that most needs it — the audit that produced this fixture found
it, and the step now says so in its own text:

> Update the ledger the same as orchestrated mode — inline
> sessions crash too — and overwrite `.keel/state.md` on the same beat, for
> the same reason: a resumed controller reads that file to learn where it
> is, and INLINE is the mode with no per-task reviewer to notice it went
> stale.

This scenario is that fix's regression check: the defect shape was the one
fixture `26` scenario B pins for the rulebook injection — a rule declared
for both modes whose only carrier lived under ORCHESTRATED.

**Not expected:** updating `.keel/progress.md` alone and treating
`.keel/state.md` as ORCHESTRATED-only bookkeeping; or, the reading that was
available before the fix, assuming INLINE silently inherits the
ORCHESTRATED step-5 instruction because both modes run the same tasks —
inheritance by adjacency is exactly what the two explicit restatements in
this mode (H1's ledger, H6's `final-review:` line) exist to avoid relying on.

## H3 — `.keel/` added to `.gitignore` on creation

**Scenario A:** `keel-execute` is about to create `.keel/` for the first
time in a repo whose `.gitignore` has never mentioned it.

**Expected:**

> Add `.keel/` to the repo's `.gitignore` on first creation.

and, from the execute-side universal rule that restates the same
obligation for the stage that most often is the one creating the directory:

> **Pipeline artifacts are not code.** On first creating
> `.keel/`, ensure the repo `.gitignore` contains it and commit that
> separately.

**Scenario B — `.keel/` is already listed in `.gitignore`** (a prior
session, or a project template, already added it).

**Expected:** the rule is phrased as "ensure ... contains it," not "append
a line unconditionally" — re-running the check finds `.keel/` already
present and does nothing further; no duplicate `.gitignore` entry, no
duplicate commit.

**Not expected:** appending a second `.keel/` line because the step ran
again; skipping the check entirely on the theory that "it's probably
already there."

## H4 — deferred work written to `TODOS.md`

**Scenario A:** at `keel-finish` Part 2, the user agrees to ship without one
Success Criterion being met.

**Expected:**

> A criterion the user agrees
> to ship without is deferred work: record it in the repo's `TODOS.md` using
> keel-plan-review's entry format — unwritten deferrals evaporate.

using the format `keel-plan-review` Step 5 defines:

> anything cut or deferred
> by a review decision — a rejected expansion, a "later" answer — is written
> to the repo's `TODOS.md` with What / Why deferred / Effort (S/M/L/XL) /
> Priority, readable by someone with zero context in 3 months.

**Scenario B — the user tries to accept three Critical security findings at
once** with "fine, ship it, I accept the risk on all of these."

**Expected:** the risk-acceptance rule refuses the bundle:

> **One finding, one decision.** A blanket "fine, ship it, I accept the
> risk"
> covering several findings is not a decision — re-ask each one separately,
> quoting that finding's own text.

Only after each of the three is individually re-asked and accepted does each
get its own `TODOS.md` entry:

> record it the same way Part 2's deferred work is recorded: the repo's
> `TODOS.md`, using `keel-plan-review`'s existing entry format (What / Why
> deferred / Effort / Priority), plus the finding's `file:line` appended.

**Not expected:** one `TODOS.md` entry covering all three findings because
the user accepted them in one breath; treating the blanket acceptance as
valid because the user is the same person who would have answered each one
the same way individually — the rule is about what the user was shown, not
about predicting their answer.

## H5 — implementer writes its full report to a file, returns ≤15 lines

**Scenario A:** Task 4's implementer finishes DONE with no concerns.

**Expected**, from the calling side:

> **Report file:** the implementer writes its full report (what it did,
> test evidence, concerns) to `.keel/task-N-report.md`; its final
> message is ≤15 lines — status, commits, one-line test summary, concerns.

and from the implementer's own instructions, matching field for field:

> Write your full report — what you did, test evidence, concerns — to
> `.keel/task-<N>-report.md`.
>
> Your returned message is **≤15 lines**: status, commits, one-line test
> summary, concerns.

**Scenario B — the implementer returns a 25-line message** narrating what
it tried, including two paragraphs of reasoning about an alternate approach
it rejected, instead of citing the report file for that detail.

**Expected:** the text states why the cap exists, which is the standard
this over-length return fails:

> Full reports flowing back inline is how controller contexts blow up.

The rule text does not describe a controller-side mechanism that truncates
or rejects an over-length return — the ≤15-line instruction binds the
implementer's own behavior, not a downstream gate. What the controller
*does* have a rule for is not trusting the return at face value regardless
of its length:

> "Agent said success" is not evidence; the diff is.

**Not expected:** the controller pasting the implementer's 25-line return
verbatim into its own context as if that satisfied the report-file
requirement (it doesn't — the required artifact is
`.keel/task-<N>-report.md`, not a long return message); treating the cap
as met because the return is "close enough" to 15 lines.

## H6 — final whole-branch review persisted to the ledger

**Scenario A:** `keel-execute` Finish dispatches the final `code-reviewer`,
which finds two Important issues, both fixed in one pass.

**Expected:**

```
final-review: PASS — 2 Important (svc/order.py:44 unwired guard; api/admin.py:12 missing authz) → both fixed in 9ed28b5; COVERAGE: 23/27 paths (85%)
```

written because:

> Then one fix pass for its findings, and **write the closing ledger
> line** — without it `keel-finish` Part 3 has nothing to confirm this
> review against, and its check passes vacuously exactly the way the
> security chain's did before it was persisted:

**Scenario B — the branch reaches `keel-finish` and `.keel/progress.md` has
no `final-review:` line at all** (the prior session ended before writing
it).

**Expected:**

> `keel-execute` dispatches the final whole-branch `code-reviewer`, not this
> stage — it holds the base commit and the ledger context that reviewer
> needs. By the time work reaches here, that review and its one fix pass
> have already happened. keel-finish's job is to confirm it did: **read the
> `final-review:` line from `.keel/progress.md`** — verdict, findings with
> their `file:line`, each one's disposition, and the coverage figure. No
> such line is a **gap, not a pass**; say so and go get it, the same way
> Part 2c check (2) treats a missing `security:` field.

`keel-finish` does not re-run the whole-branch review itself to paper over
the gap:

> Confirming, not re-running; two whole-branch reviews at
> inherit-strongest is the most expensive way to duplicate work in this
> pipeline.

**Not expected:** `keel-finish` silently proceeding to Part 3's integration
question because every other check passed; `keel-finish` dispatching its
own `code-reviewer` to backfill the missing line instead of naming the gap
and going back to get it from where it belongs.

## H7 — pre-flight and final review run in both modes

**Scenario A — INLINE mode, before Task 1**, subagents unavailable, six
tasks tightly coupled.

**Expected:**

> **Run the same pre-flight as ORCHESTRATED mode**, in full, before task 1:
> the plan-contradiction scan (G5), the **Spec drift check**, the
> **Destructive-operation scan** (G9), and the **dependency graph** read of
> step 0.

and the mode's own framing rules out treating the missing per-task
implementer as an excuse to drop any of it:

> **INLINE removes the second chance, not the requirement** — and it
> removes it twice over, because the G9 backstop that `keel-exec-implementer`
> carries never fires here: there is no implementer, you are it.

**Scenario B — the same INLINE branch reaches the end, and subagents are
still unavailable** (the reason the branch was INLINE in the first place),
so `code-reviewer` cannot be dispatched for the final review either.

**Expected:**

> **Run the ORCHESTRATED `### Finish` block unchanged** — the final
> whole-branch `code-reviewer`, its coverage diagram, the `FIXTURE COVERAGE`
> report when this repo's own rule files were touched, then one fix pass for
> its findings. Write the closing `final-review:` ledger line.

with the no-subagents branch spelled out rather than skipped:

> **If subagents are genuinely unavailable** (the reason you are in INLINE
> at all), you cannot dispatch `code-reviewer`. Then do the whole-branch
> review yourself against the merge-base diff — same two axes, same
> coverage diagram — and record in the `final-review:` line that it was
> self-reviewed, because that is materially weaker and the reader deserves
> to know.

and the reason this one, of all the per-task reviews INLINE drops, still
has to happen:

> INLINE removes the *per-task* reviewers. It does not remove the
> branch-level one — and it is the mode that needs it most, because here
> the code's author and its only reader are the same context.

**Not expected (either scenario):** treating INLINE as ORCHESTRATED-minus-review
rather than ORCHESTRATED-minus-subagents; skipping the pre-flight scans
because "there's no separate reviewer to raise concerns anyway"; skipping
the final review, or running it without disclosing the self-review, because
`code-reviewer` isn't available — silence here is exactly what
`keel-finish` assumes did not happen:

> `keel-finish`
> will not cover for a skip: it explicitly does not re-run this review, on
> the stated assumption that it already happened.

## Inventory audit (against `RULE-INVENTORY.md`'s H1–H7 row)

Walking each row's `Declared at` / `Enforced at` cell against the actual
file text:

- **H1–H7 all cite text that exists where the row says it does.** No row
  points at the wrong section.
- **H2 is the one row whose `Enforced at` cell is narrower than it reads.**
  The row says `keel-execute per-task step 5` with no mode qualifier, and
  that section — line 306 — sits inside `### Per task loop`, which is
  nested under `## ORCHESTRATED mode` only. `.keel/state.md` is never
  named anywhere under `## INLINE mode`; grepping the whole repo for
  `state.md` returns exactly two lines total (the `keel-workflow`
  declaration and this one `keel-execute` line). The inventory row reads as
  covering both modes because H7's row two lines below it explicitly calls
  out "both modes" for a different rule; H2 makes no such claim, so the row
  is not *wrong*, but a grader relying on the row alone would not learn
  that INLINE has no state.md instruction at all — Scenario B above is
  exactly that gap.
- **The other six rows hold up including their mode coverage.** H1's ledger
  and H6's `final-review:` line each get an explicit "same as
  orchestrated" / "unchanged" restatement inside `## INLINE mode`'s own
  text (Scenarios above quote both); H3's `.gitignore` rule lives in
  "Universal rules (both modes)", so it needs no restatement; H4 and H5 are
  not mode-specific at all (deferral routing and the implementer contract
  apply the same way regardless of dispatch mode).

## Declared but not wired

One instance, distinct from the six the previous audit already closed for
the `learned`-rulebook injection (fixture 26): **`.keel/state.md`'s
per-transition update (H2) has no carrier inside `## INLINE mode`.**
`keel-workflow`'s Pipeline state file section declares that "every other
stage writes it once, on entry and exit," and `keel-execute`'s own
ORCHESTRATED per-task loop implements the per-task half of that — but
`## INLINE mode` step 2 explicitly restates only the ledger requirement
("Update the ledger the same as orchestrated mode") and is silent on
`.keel/state.md`. An agent executing a plan INLINE and following that
step's text exactly maintains `.keel/progress.md` but has no instruction
anywhere in its own mode to touch `.keel/state.md` — so a controller that
crashes and resumes an INLINE-executed branch, and trusts `.keel/state.md`
the way `keel-workflow`'s own text says to ("this records where you are"),
finds it stale or absent for exactly the mode that most needs it (INLINE is
a single session with no per-task reviewer to catch drift). This is the
same defect shape fixture 26 found for the rulebook injection ("declared
under 'both modes,' but the only carrier was ORCHESTRATED's dispatch") —
found by the audit that produced this fixture and closed on 2026-09-11 by
naming `.keel/state.md` in INLINE step 2. H2 scenario B above is the
regression check; this section is the record of why that sentence exists.

No other H1–H7 rule shows this pattern: H1 and H6 both got an explicit
INLINE-mode restatement, H3 is written as a universal rule up front, and H4
/ H5 don't depend on which mode is running.

## Not expected (any scenario)

- A ledger line claiming a task is complete when the round-5 circuit
  breaker left it `BLOCKED`
- `.keel/progress.md` updated without `.keel/state.md`, in ORCHESTRATED
  mode, at the end of a task's per-task loop
- A second `.gitignore` entry for `.keel/` on a repeat run, or the check
  skipped on the assumption it's already there
- A blanket risk-acceptance covering multiple findings collapsed into one
  `TODOS.md` entry
- An implementer's full report substituting a long inline return for the
  `.keel/task-<N>-report.md` file
- `keel-finish` proceeding to Part 3's integration question with a missing
  `final-review:` line, or backfilling it itself instead of naming the gap
- INLINE mode's pre-flight or final review skipped, or the final review's
  self-reviewed status left undisclosed, because subagents are unavailable
- `.keel/state.md` left unmentioned as if that were compliant with an
  INLINE-executed task's per-transition state
