# Fixture 22: `Depends on:` and `[Risk:]` are consumed and verified (P5, P6)

**Rule source:** `skills/keel-execute/SKILL.md` per-task loop step 0
(dependency graph) and `agents/keel-plan-lens-eng.md` (rollback on every
High-risk task, risk-grade sanity).

Both were producer-and-consumer-without-a-verifier, or worse. `Depends on:`
was written by `keel-plan`, **confirmed by the user at G2**, and then read by
nothing — a user interaction spent verifying data that was discarded.
`[Risk: High]` was required by `keel-plan` to carry a named rollback step,
and nothing checked that it did.

## A — dependency order is a hard bar

**Scenario:** Task 5 reads `Depends on: Task 2`. The ledger shows Tasks 1, 3,
4 DONE; Task 2 is not started.

**Expected:** Task 5 is not dispatched. Task number order is not dependency
order, and "Task 5 comes after Task 4" is not the question being asked.

**Boundary:** all of Task 5's dependencies are DONE → dispatch normally.

## B — parallelism reads the graph, not intuition

**Scenario:** Tasks 6 and 7 touch entirely disjoint files. Task 7 reads
`Depends on: Task 6`.

**Expected:** they do **not** run concurrently. A dependency edge is a hard
bar even when files are disjoint — Task 7 consumes something Task 6 produces,
which is exactly what the edge records.

**Converse scenario:** Tasks 6 and 7 have no dependency between them but both
list `src/router.ts` in `Files:`.

**Expected:** also not concurrent — file overlap serializes them too. The two
tests are independent and both must pass before running tasks in parallel.

**Why it is stated this way:** the mode decision at the top of `keel-execute`
asks whether tasks are "mostly independent." Before step 0 existed, nothing
told it where to read that off, so it was answered by impression.

## C — the brief includes exactly the dependencies' Interfaces

**Scenario:** Task 8 reads `Depends on: Task 3, Task 5`.

**Expected:** its brief carries the `Interfaces:` blocks of Tasks 3 and 5 —
not of every completed task, and not of none. "Which completed tasks does
this one consume" is precisely what the edge answers.

## D — an edge pointing nowhere is a plan bug

**Scenario:** Task 4 reads `Depends on: Task 9`, but the plan has 7 tasks.

**Expected:** `BLOCKED: Depends on 指向不存在的 task → 退回 keel-plan`. Not
silently ignored, not "probably means Task 6."

**Boundary:** `Depends on: none` on every task in the plan is a **legitimate
graph**, not a missing one — a plan of genuinely independent tasks is normal
and must not be flagged.

## E — High risk without a named rollback

**Scenario:** `## Task 6: migrate orders table to the new schema [Risk: High]`.
No rollback step anywhere in the task.

**Expected:** `keel-plan-lens-eng` finding. `keel-plan` requires high-risk
tasks to carry a named rollback and nothing else checks it.

## F — "rollback" that is not a rollback

**Scenario:** same task, rollback step reads "revert if needed."

**Expected:** still a finding. The rollback must be **named** — an actual
command or procedure. "Revert if needed" states an intention, not a method.

**Sharper case:** rollback reads "restore from backup," and no earlier task
in the plan takes a backup.

**Expected:** finding. A rollback that depends on an artifact the plan never
creates is fiction; either the backup step joins the plan or the rollback
does not exist.

## G — understated risk grade

**Scenario:** a task that drops a column is graded `[Risk: Low]`.

**Expected:** finding on the grade itself. The grade is not cosmetic — it
drives `keel-execute`'s R4 condition 3 (whether the security axis is
dispatched at all) and this lens's own error-registry requirement. An
understated grade **silently disables both**, and neither of them reports
that it was skipped for this reason.

**Boundary:** a genuinely low-risk task graded Low → no finding. The check is
against what the task does, not a presumption that everything is risky.

## Not expected (any scenario)

- Dispatching by task number and calling it dependency order
- Using file overlap as the only serialization test
- Treating `Depends on: none` as a missing field
- A `[Risk: High]` task passing review with an unnamed or unachievable
  rollback
