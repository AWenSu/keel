# Fixture 34: critical flows — named at discovery, driven early, not chosen at the end (D19, D20, H10)

**Rule source:** `skills/keel-discover/SKILL.md` step 5c (Name the critical flows).
**Rule source:** `skills/keel-plan/SKILL.md` step 2a-0 (Carry the critical flows across, as commands).
**Rule source:** `skills/keel-execute/SKILL.md` ORCHESTRATED per-task loop step 5; INLINE step 2.
**Rule source:** `skills/keel-finish/SKILL.md` Drive the real flow.

`keel-finish` has always required driving the real surface — the claim
"feature works" has never been satisfiable by a green test suite. What it did
not have was a *named* surface: the agent at Stage 5 chose what to drive, and
an agent trying to finish chooses the path it can get green. Added 2026-09-11:
the flow is named at discovery (where nobody is under finishing pressure),
turned into a command at planning, and driven during execution at the first
moment it can run.

The failure this closes is specific and is not "no tests". It is: every unit
green, every seam covered, and the thing broken at the join —

> Seams answer "where is this observable to a caller". They do not answer
> "does the whole thing still work", and the gap between those two questions
> is where the expensive failures live: every unit green, every seam covered,
> and the feature broken at the join.

## A — a flow that crosses nothing is not a flow

**Scenario:** discovery for a change to an in-memory pricing calculator. The
proposed critical flow is "call `calculatePrice()` with a cart and check the
total".

**Expected:** rejected for this table. It belongs in 5b, not 5c:

> A flow that stays inside one process is a unit test with
> extra steps; it is already covered by 5b and adds nothing here.

and the column that decides it cannot be filled honestly:

> `Crosses` is the load-bearing column. "None" is not a valid entry — a flow
> that crosses nothing does not belong in this table.

**Not expected:** listing it with `Crosses: none` to have a row; listing it
because the calculator is important. Importance is not the criterion — a
boundary is, because that is where the failures this section exists to catch
occur.

## B — "no errors" is not an observable result

**Scenario:** a flow crossing a real boundary (upload a file, the worker
picks it up from object storage, the row appears in the database). The
proposed `Observable result` is "no errors in the log".

**Expected:** insufficient, by the rule's own reasoning:

> `Observable result` must
> be something a person can look at and judge, not "no errors": the failures
> this section exists to catch are the ones where nothing throws and the
> output is wrong.

The honest entry names the row, the field, and the value expected to be in
it — something that would be *wrong* if the join silently mangled the data.

**Not expected:** an exit code as the whole result; "the request returned
200"; anything that a broken-but-not-throwing pipeline would also produce.

## C — the plan owes a command, not a gesture

**Scenario:** the plan copies the flow across and writes
`Drive: run the app and try uploading something`.

**Expected:** that fails the plan's own standard for this column:

> `Drive` must be executable by someone with zero context: a command line, or
> numbered UI steps naming the actual screen and control. "Run the app and try
> it" is a placeholder and fails the No Placeholders rule like any other.

**Boundary — a flow that genuinely cannot run until later tasks land:** the
answer is not to leave it vague but to say when:

> Where a flow cannot be driven until several tasks land, say which task
> unblocks it — `Drive` may read `after T4: <command>`; that is what lets
> `keel-execute` know when to run it rather than waiting for the end.

**Not expected:** deferring the command to "whoever runs it will figure it
out" — the whole mechanism turns on a later agent being able to run this
without re-deriving it.

## D — driven at the first task after which it can run, not at the end

**Scenario:** ORCHESTRATED execution, six tasks. Task 2 completes the
producer side of a queue handoff; the flow's `Drive` reads
`after T2: <command>`. Tasks 3–6 are still unwritten.

**Expected:** the flow is driven at the end of task 2's loop, not at Finish:

> Read the plan's `## Critical flows`. After this task, ask of each flow not
> yet driven since its last touching change: can its `Drive` column run now?
> If yes, run it and compare against `Observable result`

and the reason the timing is the rule rather than a preference:

> a flow that cannot work at all is a design
> error, and finding it after the last task means every task was written
> against a shape that does not hold.

**Not expected:** batching all flow-driving into Finish because it is
"cleaner"; driving a flow whose `Drive` reads `after T4` while task 4 is
still open —

> A flow whose `Drive` reads
> `after T<n>` is not askable until task n is DONE; say nothing about it
> until then.

## E — a failing flow stops the loop; it is not a note

**Scenario:** the flow driven after task 2 comes back wrong — the message
arrives but its payload is truncated. Tasks 3 and 4 are ready to dispatch and
do not touch the queue.

**Expected:** dispatching stops:

> **A failing flow stops the loop the way a failing task does.** It is not
> a note for the summary: the join it crosses is broken now, and every
> later task builds on it. Diagnose before dispatching anything else.

and the ledger records the verdict, not a plan to look at it later:

> record the
> verdict on the ledger line as `flow: <name> — ok` or
> `flow: <name> — FAILED: <what you saw>`

**Not expected:** proceeding with tasks 3–4 on the grounds that they are
unrelated; recording `flow: <name> — FAILED` and continuing; carrying the
failure to Finish as a known issue.

## F — INLINE drives them too

**Scenario:** INLINE mode, subagents unavailable, same six-task plan.

**Expected:** identical, restated in INLINE's own step list rather than left
to inheritance:

> **Driving critical flows applies here too**, on the same beat as the
> ledger: after each task, run any `## Critical flows` row whose `Drive`
> can now run, and record `flow: <name> — ok` / `FAILED: <what you saw>`.

and the mode's reason for needing it *more*:

> A failed flow stops this loop exactly as it stops the orchestrated one —
> more so, because here there is no per-task reviewer who might have
> noticed the join was broken.

**Not expected:** treating flow-driving as an ORCHESTRATED-only step because
that is where it is written at greatest length. This is the defect shape
fixtures `26` (scenario B) and `31` (H2) both pin; the restatement exists so
this rule never joins them.

## G — at Finish the surface is read, not chosen

**Scenario:** Part 1. The plan names two critical flows. The agent is
composing evidence for "feature works" and would rather drive the CLI
subcommand it just changed, which it knows passes.

**Expected:** not its choice:

> **Which surface is not yours to choose here.** Read the plan's
> `## Critical flows` and drive every row, against its own `Observable result`
> column — an agent picking the surface at this stage picks the one it can get
> green, which is the shallowest, and the flows were named at discovery
> precisely so the choice would already be made by someone not under pressure
> to finish.

and the ledger does not excuse a re-drive when the code has moved:

> The ledger's `flow:` lines say which were already driven during
> execution; drive each one again if anything has changed since, and drive
> every row the ledger never recorded at all.

**Not expected:** counting an execution-stage `flow: … — ok` from four tasks
ago as this session's evidence — that collides with the Iron Law's
this-session requirement exactly as any other stale output does (fixture
`29` scenario B).

## H — the three endings are different facts

**Scenario:** three variants at Part 1.

**H1 — every row driven and matching.** The claim carries its evidence.

**H2 — a row needs an environment this session cannot reach.**

> **A row you cannot drive here** (needs an environment this session has no
> access to) → `not executed — <why>`, the same honest-absence line the
> paragraph below grants.

**H3 — the plan has no `## Critical flows` section at all.**

> that is a
> **gap, not an exemption**. Say so as `critical flows: no section — plan
> predates keel-discover 5c`, fall back to the ad-hoc drive above, and know
> that you are now doing the thing this section exists to stop: choosing the
> surface yourself, at the stage least able to judge it.

and the entry that is *not* H3, because someone answered the question:

> An explicit
> `none — <why>` row is different and is a legitimate answer.

**Not expected:** H3 reported as a pass; H3 and an explicit `none` row
recorded the same way; H2 escalated into a block.

## Not expected (any scenario)

- A critical-flows row whose `Crosses` is empty, or whose `Observable
  result` would also be produced by a silently broken join
- A `Drive` column that cannot be run by someone with zero context
- Flow-driving deferred to Finish when the flow could already run
- A failed flow recorded and stepped over rather than diagnosed
- Any of it treated as ORCHESTRATED-only
- A missing `## Critical flows` section read as an exemption rather than a
  stated gap
