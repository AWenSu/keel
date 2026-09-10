# Fixture 26: project-rulebook integration boundaries (D14, D15, D16, D17)

**Rule source:** `skills/keel-execute/SKILL.md` Universal rules (both modes) — Project rulebook.
**Rule source:** `skills/keel-plan-review/SKILL.md` Step 2 (Project rulebook injection, before dispatching any lens).
**Rule source:** `skills/keel-execute/SKILL.md` ORCHESTRATED per-task loop, the Fix loop step; INLINE step 2.
**Rule source:** `skills/keel-finish/SKILL.md` Part 1: The Gate Function.
**Rule source:** `skills/keel-finish/SKILL.md` Part 2e: Promote findings to the project rulebook.

Four rules arrived together in the `learned`-skill integration, and they form
one loop: the rulebook is **read** at plan review and at execution (D14),
**shaped** by the fix loop's round-4 escalation (D15), **evidenced** through
the default verification command (D16), and **written back** before the branch
integrates (D17). Each has a trigger boundary, and each has a
nothing-to-do branch that must be *said* rather than skipped — that silent
branch is where all four decay.

## A — `.learned/` present: hits ride into every brief, per task

**Scenario:** ORCHESTRATED execution. The repo root has a `.learned/`. The
plan has six tasks; task 3's `Files` line names the payment webhook handler.

**Expected:** the root check happens once, the search happens per task, and
the hits land in two different briefs:

> if the repo has a `.learned/` (check once with
> `python3 ~/.claude/skills/learned/scripts/learned.py root`), then for every
> task run `learned.py search "<kw>"` on the task's Files / Interfaces
> keywords and append the hits as a **Known pitfalls** block (`<ID>: <title>`)
> to both the implementer brief and every reviewer brief.

and the two roles consume the same block differently:

> Implementers treat
> hits as Global Constraints; reviewers treat each hit as one more checklist
> line in the form "看到 X → 問 Y". Reviewer findings that match a rule cite
> its ID.

**Not expected:** one search for the whole plan reused across six briefs
(the keywords are per-task, from that task's Files / Interfaces); hits pasted
into the implementer brief only; a reviewer finding that restates a rule
without citing its ID. The stated cost of skipping:

> The rulebook is the project's memory of what already went wrong;
> a brief without it re-discovers the same failures.

## B — INLINE mode with a `.learned/`: no brief, requirement unchanged

**Scenario:** INLINE mode (subagents unavailable). The repo has a `.learned/`.
There is no implementer brief and no per-task reviewer brief to append to.

**Expected:** the search still runs and the hits still bind. The mode's own
framing refuses the "no carrier, no obligation" reading:

> **INLINE removes the second chance, not the requirement**

and since 2026-09-11 the INLINE step list carries the rule explicitly (an
audit of this fixture's rules found the injection was re-lifted for every
other ORCHESTRATED gate but not this one — the gap is closed, and this
scenario is its regression check):

> **The rulebook injection applies here too:** with a
> `.learned/`, run the per-task `learned.py search` and hold the hits as
> your own Global Constraints and self-review checklist — there is no brief
> to append them to, but the brief was only ever the carrier, not the rule.

**Not expected:** skipping the rulebook because there is no brief object to
append to.

## C — plan-review: injection happens before dispatch, as verification targets

**Scenario:** a plan touching Postgres and a payment SDK; four lenses selected
in Step 1, roster about to be announced.

**Expected:** keywords out of the plan, one search per keyword, hits appended
to **each** lens's brief before any dispatch:

> extract 3–5 keywords from the plan (touched modules, frameworks, data stores,
> protocols) and run `learned.py search "<kw>"` for each. Put every hit as
> `<ID>: <one-line title>` into a **Known pitfalls** block appended to each
> lens's brief, and tell the lens to treat those as findings to verify against
> the plan, not background reading.

and, when the plan deletes functions, changes fields, or touches DB operators,
the same hits feed the Eng lens's deep check:

> Hits are also the
> input to the Eng lens's ten-point deep check (`learned` method.md §一.11)
> when the plan deletes functions, changes fields, or touches DB operators.

**Not expected:** injecting after the lenses return; giving the block to the
security lens only; wording it as context to read. The failure the rule names:

> A lens without rule IDs reviews against
> generic OWASP/SOLID and misses exactly the project-specific failure modes
> the rulebook exists to carry (the `learned` skill's method.md §一.1).

## D — no `.learned/`: two different disclosure sites, neither optional

**Scenario:** the same two stages against a consumer repo with no `.learned/`.

**Expected (execute):**

> No `.learned/` → note
> it once in the ledger header and proceed.

**Expected (plan-review):**

> `.learned/` → say so in the roster line and proceed.

Once in the ledger header, not once per task; in the roster line, not in the
Step 5 summary.

**Not expected:** silence in either place; blocking; `learned.py init` run
without being asked at this stage (that offer belongs to Part 2e, scenario K).
A stage that simply produces briefs with no Known pitfalls block and no note
is indistinguishable from a stage that forgot — which is the whole reason the
disclosure exists.

## E — round 3 vs round 4: the switch point

**Scenario:** two Important findings survive the round-3 scoped re-review. The
controller is composing the round-4 reviewer brief.

**Expected:** two things change at exactly round 4, not one. The agent:

> **Round cap: 5.** Rounds 1–3 resume the same `keel-exec-fixer` dispatch.
> Rounds 4–5 switch to `keel-exec-fixer-critical` (opus, fresh context, no
> memory of the failed attempts)

and the brief form:

> **From round 4, the reviewer brief switches to the verdict-matrix form**

> one
> named area per outstanding finding plus the three fixed areas — NEW
> defect introduced by the fix itself, previous-RESOLVED regression, and
> test adequacy (does the test enter the failure window or only the happy
> path) — each answered RESOLVED / PARTIAL / NOT_RESOLVED with a line
> anchor.

So a round-4 matrix on two outstanding findings has **five** named areas: two
findings plus the three fixed ones, each with a verdict and a line anchor.

**Not expected (round 3):** the matrix at round 3 — rounds 1–3 are the plain
scoped re-review, and demanding the matrix early is not a safe over-compliance,
it burns the escalation signal. **Not expected (round 4):** escalating by
passing a `model` override to the standard fixer instead of switching agent
identity; a matrix area answered without a line anchor; a matrix reporting only
the areas that improved —

> Selective reporting is what lets a fix loop spin; round 4 on a
> race/lifecycle fix is itself the signal the design is wrong, not the
> patch (`learned` method.md §一.3).

## F — round 5: the matrix does not replace adjudication

**Scenario:** round 5 completes; one finding remains, and it breaks a
`Delivers:` line.

**Expected:** the verdict-matrix form stays, and on top of it:

> At round 5, if findings remain: **circuit breaker trips.**

The remaining finding is load-bearing, so the task is `BLOCKED` and reported;
it is not marked done, and there is no round 6.

**Not expected:** treating a fully-filled round-5 matrix as the deliverable and
looping again because "the matrix shows progress". The matrix is the reporting
form; the circuit breaker is the stop.

## G — dod.sh is the default, and an unclassifiable repo is a disclosure

**Scenario:** Part 1, about to claim "tests pass" on a repo whose stack
`dod.sh` cannot classify.

**Expected:** the default is named, run, and its inability to classify is
reported as an absence — not converted into a pass:

> Default for build/test/lint claims:
> ~/.claude/skills/learned/scripts/dod.sh <repo>
> (stack-detected; a repo it cannot classify says so — that is
> a "not executed — <why>" disclosure, not a pass)

**Not expected:** substituting a narrower command (a single test file, a
typecheck) and claiming the build; carrying a previous session's output;
inferring a pass from "nothing obviously broken".

> Skipping any step is lying, not verifying.

## H — the three outcomes of the gate are not interchangeable

**Scenario:** three variants of the same Part 1 run.

**H1 — the command ran and failed with a specific, fixable error.**

> The command produced a clear, specific failure you can fix in place — an
> ordinary red test. Fix it; that's a normal fix pass, not a stage handoff.

**H2 — the command ran, exit 0, but the output does not support the claim.**

> When step 4 comes back NO — the command ran but its output doesn't support
> the claim — that is an undiagnosed bug, and it routes.

Route to `keel-debug`, taking the command and its output; re-run the whole gate
from the top on return.

**H3 — the command cannot exist or cannot run at all.**

> The command cannot exist or cannot run at all — no test harness, no
> non-production environment. That IS the summary-disclosure path: state
> `not executed — <why>` plainly. A stated absence is honest; a claim resting
> on nothing is not.

**Not expected:** collapsing H2 into H1 by re-running until green; collapsing
H2 into H3 by writing "not executed" over a command that did execute;
collapsing H3 into a pass.

## I — Part 2e: near-duplicate is a 補充, not a new ID

**Scenario:** `.keel/findings.md` has four entries. One says the ORM silently
drops a `NULL` filter — `learned.py search` returns an existing rule covering
the same operator with a different symptom.

**Expected:** the survivor filter runs first:

> Keep only what is **non-obvious AND reusable**: needed more than one
> attempt, a framework/tool behaved counter to its docs, a reviewer finding
> that matched no existing rule, a plan premise the code refuted.

then, for this survivor:

> For each survivor: `learned.py search "<kw>"` first — a near-duplicate
> gets a `**補充（date）**` paragraph on the existing rule, not a new ID.

and anything inferred rather than observed is marked, not asserted:

> Unverified inferences are written as `**待驗證**`, never as the fix.

**Not expected:** a new ID beside the existing rule (the rulebook's value is
that one search returns one rule); skipping the search and calling
`learned.py add` directly; promoting entries the filter drops —

> Drop
> one-off fixes, obvious usage, and anything about how the *user* likes to
> work (that is auto-memory feedback, not a rule).

## J — an unfixed problem is work, not a rule

**Scenario:** a findings entry reads "the retry path double-charges on a 502;
not fixed this branch."

**Expected:** it leaves Part 2e through Part 2b's lane:

> A finding that is an
> **unfixed problem** rather than a lesson is not a rule either — it is
> work, and it goes through Part 2b's deferral lane (backlog), not here.

**Not expected:** writing it as a rulebook entry so that "it is recorded
somewhere" — a rule the next plan injects as a Known pitfall would tell the
next implementer to avoid a bug that is still live in this repo.

## K — the empty answer must be spoken, in all three shapes

**Scenario:** three variants at Part 2e.

**K1 — survivors exist but all are near-duplicates or dropped.**

> Report the IDs added or amended in one line; "no new rules" is a valid
> answer and must be said, not skipped.

**K2 — the repo has no `.learned/`.**

> No `.learned/` → one line offering `learned.py init`; do not block on it.

**K3 — the ledger's `findings:` line is missing, or its count contradicts the
file.**

> a missing line, or a
> missing/empty `findings.md` the line's count contradicts, is an execute-side
> gap — record it in the final summary rather than silently skipping.

**Not expected:** omitting Part 2e from the final summary in any of the three;
treating K3 as "nothing to promote" (the count contradiction is itself the
finding); blocking integration on K2.

## Why this closes a loop and not a step

> Rules are the only artifact from this stage that the *next* plan reads —
> `keel-plan-review` and `keel-execute` inject them into every brief

A grader walking this fixture should be able to name, for any scenario above,
the other end of the loop: the D17 write in scenario I is what scenarios A and
C read, and the D14 disclosure in scenario D is what tells the next reader the
loop is open at that end rather than merely quiet.

## Not expected (any scenario)

- A `.learned/` branch taken silently — every no-rulebook path has a named
  place to say so (ledger header, roster line, final summary), and the place
  differs per stage
- The verdict-matrix form before round 4, or a round-4 escalation by model
  override instead of agent identity
- A build/test/lint claim resting on anything other than a full fresh run, or
  an unclassifiable repo reported as a pass
- A new rule ID where a `補充` was owed, or an unfixed problem promoted as a
  rule
