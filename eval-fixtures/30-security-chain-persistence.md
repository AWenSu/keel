# Fixture 30: the security chain's producer end — written down, or vacuously passed (E7, E8, E9)

**Rule source:** `skills/keel-execute/SKILL.md` step 3c ("Findings go in the ledger, not just the conversation") and Progress ledger — the security line.
**Rule source:** `skills/keel-plan-review/SKILL.md` Append to the plan file — the `## SECURITY FINDINGS` table.
**Rule source:** `skills/keel-finish/SKILL.md` Part 2c check 1 — full-branch secrets scan.

Fixtures `12`, `13` and `17` all grade the **consuming** end of the security
chain: which R4 condition fires (`13`), what Part 2c does with what it reads
(`12`), and what happens when the branch has no coverage at all (`17`). This
fixture grades the **producing** end — the three writes those gates read back
from a context that cannot see the conversation in which the finding was
raised. E7 and E8 are the two persistence writes; E9 is the one Part 2c check
whose evidence is produced from the branch itself rather than from an upstream
artifact, so its scope is the third way this chain silently narrows.

The failure mode is the same in all three and it is not a false pass — it is a
**vacuous** one:

> `keel-finish` Part 2c check (2) reads these lines — with no producer here,
> that gate has nothing to check and passes vacuously, which is not the same
> as passing.

A grader must therefore never accept "the gate reported no findings" as the
result of any scenario below without first asking whether anything was ever
written for it to find. That is the same shape as E14 / fixture `17`, one
stage earlier.

## A — the axis ran, findings were raised, nothing reached the ledger (E7)

**Scenario:** ORCHESTRATED execution, Task 5. R4 condition 1 matched,
`keel-exec-reviewer-security` was dispatched and returned two Important
findings (SQL string-building at `svc/order.py:44`; a missing authz check at
`api/admin.py:12`). Both were fixed in the same fix pass, the controller
broadcast both verdicts inline, and the ledger line for Task 5 reads
`Task 5: order query scoping — DONE, reviewed (2 findings fixed), commit a1b2c3d, branch feat/orders`
with no `security:` field.

**Expected:** the task is not complete. The findings and their disposition are
written to the ledger line, because the fix does not discharge the write:

> **Findings go in the ledger, not just the conversation.** When the axis
> runs, its Critical/Important findings and their disposition are written to
> the task's ledger line (`security:` field, see Progress ledger below).
> `keel-finish` Part 2c check (2) reads that field from a later, fresh
> context; a finding that exists only here is one that gate will never see.

**Not expected:** treating "both were fixed, so there is nothing outstanding
to record" as a discharge. Part 2c check (2) reconciles dispositions, so a
fixed finding is exactly as load-bearing a ledger row as an open one — and a
branch whose ledger lines carry no `security:` field is, at Part 2c, a
**gap, not a pass**. Also not expected: recording the findings only in the
final summary or in `.keel/findings.md`; check (2) names one file and one
field.

## B — the axis ran and found nothing (E7)

**Scenario:** Task 2 tripped R4 condition 3 (`[Risk: High]`). The security
reviewer returned a clean pass, zero findings.

**Expected:** a `security:` field is still written, with the value the rule
names for this case:

> The **security line** is written whenever the security axis ran: every
> Critical/Important finding with its `file:line` and disposition, or
> `security: none` if it passed clean. When the axis was skipped, that line is
> the skip justification instead (see step 3c).

**Not expected:** omitting the line because there is nothing to report. A
missing line and `security: none` are different facts downstream — one says
the axis ran and was clean, the other is indistinguishable from an axis that
never ran, which is precisely what check 0 in fixture `17` is built to catch
at branch scope after this stage has already lost the information.

## C — a skipped axis writes the same field with different content (E7)

**Scenario:** Task 7 bumps two dependency versions. All five R4 conditions
were checked; none matched. There is no plan `## SECURITY FINDINGS` section,
because this plan never went through `keel-plan-review`.

**Expected:** the line is written as the skip justification, and it discloses
condition 4's status honestly rather than counting it as a miss:

> No such section — the plan skipped `keel-plan-review`, which most plans do
> — means this condition is **unevaluable, not false**: it cannot contribute a
> trigger, and the other four conditions carry the decision alone. Say so in
> the ledger line rather than counting it as a clean miss.

Which condition text belongs in that line, and the dependency-only deferral it
must cite, are graded in fixture `13` ("Zero conditions matched"); what this
scenario adds is that the skip and the clean pass land in the **same field**,
so the field's presence proves nothing on its own — only its content does.

**Not expected:** an empty `security:` field; a skip recorded as
`security: none` (that value is reserved for an axis that ran); silence on
condition 4 because the section's absence "obviously means no".

## D — a plan-stage finding fixed during review still gets a row (E8)

**Scenario:** `keel-plan-lens-security` returns one Critical tagged
`## Task 5`. The controller applies the fix as a plan edit inside Step 5, the
user approves, and the plan text no longer contains the flaw. The controller
is about to append the REVIEW REPORT.

**Expected:** the `## SECURITY FINDINGS` table carries the row anyway, with
`applied as edit` in the disposition column:

> **The `## SECURITY FINDINGS` table is written even when a finding was
> already handled here, and even when the lens found nothing** (write
> `lens not run` or `no findings`). It is the only durable copy: two
> downstream consumers read it from a fresh context that cannot see this
> conversation

and deleting the row is not neutral housekeeping — it disables a trigger two
stages away:

> `keel-execute`'s R4 condition 4 matches its `## Task N` tags to decide
> whether a task needs the security review axis, and that condition is
> "previously raised," not "still unresolved," so deleting handled rows
> disables it;

**Not expected:** pruning handled rows so the table shows only what is still
open; keeping the finding in the REVIEW REPORT's `Decisions:` prose instead of
the table (R4 condition 4 matches `## Task N` tags in a table, not prose);
writing the finding in paraphrase where the template asks for the lens's own
words (`<verbatim from the lens's FINDINGS: entry>`).

## E — `lens not run` and `no findings` are different answers (E8)

**Scenario:** two variants of the same Step 5 close-out.

**E1 — the Security lens was never selected** (Step 1's trigger did not fire:
fewer than two security keywords, no high-risk marker).

**E2 — the Security lens ran and returned an empty `FINDINGS:` block.**

**Expected:** both write the section; each writes its own string, and they are
not interchangeable. E1 is a statement about *coverage* (nobody looked); E2 is
a statement about *result* (someone looked and found nothing). The rule names
both strings for that reason, and the cost of collapsing them is spelled out:

> A lens's returned findings live only in this stage's context.
> `keel-execute` requires a fresh controller past ~100k tokens and
> `keel-finish` runs later still — so a finding not written into the plan file
> is a finding neither of them will ever see, and both of their checks
> silently pass on an empty set.

**Not expected:** omitting the section in E1 on the grounds that there was no
lens to report; writing `no findings` for E1. Note the boundary against Part
2c check 4's own missing-section handling, which is a *third* state and is
graded in fixture `12`:

> **Section missing entirely** (no plan file, or a plan that never went
> through keel-plan-review — the common case) → this check cannot fire; say so
> as `plan-stage lens findings: no section — plan did not go through
> keel-plan-review`, and rely on check 0, which is what covers that branch. Do
> **not** report it as passed

A plan that *did* go through `keel-plan-review` and wrote nothing is
downstream-indistinguishable from one that never went through it at all —
except that the second is disclosed and routed to check 0, and the first is
not. That is why the write is unconditional here.

## F — the session boundary is the whole point (E7, E8)

**Scenario:** `keel-plan-review` finished on Monday. `keel-execute` starts
Wednesday in a fresh controller that never saw the review; it compacts twice
during the branch, and `keel-finish` runs in a third context. Task 5's
controller wants to know whether the plan lens flagged Task 5.

**Expected:** the answer is read from the plan file, and only from there:

> Read the table from the plan file, never from conversation history: this
> controller may be a fresh one that never saw the review stage.

Across the whole chain the two artifacts written by E7 and E8 —
`.keel/progress.md`'s `security:` lines and the plan's `## SECURITY FINDINGS`
table — are the only memory that survives. Everything else in this scenario is
gone by design, not by accident.

**Not expected:** reconstructing condition 4 from a summary the previous
controller pasted into the handoff; treating "I would remember a Critical" as
coverage; a `plan-global` finding attached to an arbitrary task instead of
being noted once —

> Findings tagged `plan-global` in `keel-plan-lens-security`'s output don't
> belong to any single task — note them once at the start of this step, not as
> a per-task trigger:

## G — the secrets scan's unit is the branch, not the commit (E9)

**Scenario:** Part 2c on a six-commit branch. An API key was committed in
commit 2 and removed in commit 4; the working tree and the tip commit are
clean. The controller runs a scan over the last commit's diff, sees nothing,
and writes "secrets scan: no leaks found".

**Expected:** that is the wrong unit. The check is a

> Full-branch secrets scan

and its evidence is the named command over the repo plus its summary line,
pasted:

> Run `gitleaks detect --source . -v` (or `semgrep` if that's what's
> installed) this session and paste the summary line (leak count, or "no leaks
> found")

A key that ever entered the branch's history is still in the history a merge
would carry forward; a tip-commit scan cannot see it, so a "no leaks found"
derived from one is a claim the evidence does not support.

**Not expected:** narrowing the scan to the diff, to the staged changes, or to
the last commit and reporting the check as run; paraphrasing the summary line
instead of pasting it; reporting a leak count without the tool's own output
behind it.

## H — the scan's evidence is produced this session, and its absence is a sentence (E9)

**Scenario:** two variants of the same Part 2c.

**H1 — a `gitleaks` report from last week's run of this branch exists in the
repo, and the branch has three commits since.**

**H2 — no scanner is installed at all.**

**Expected (H1):** the stale report is not evidence. Part 2c inherits Part 1's
rule without softening it:

> Same Iron Law as Part 1: every line below needs evidence produced **this
> session**, not a stale scan.

**Expected (H2):** the exact disclosure, and no block:

> No such tool installed → state "secrets scan: not executed — no
> gitleaks/semgrep available" explicitly; never blocks (see BLOCKED condition
> below).

Why (1) never blocks — the alarm-fatigue carve-out — is graded in fixture `12`
scenario C; what this fixture pins is that the sentence is mandatory in H2 and
forbidden in H1, where a command could have run and did not.

**Not expected:** H1 reported as a pass because a file with the right name
exists; H2 reported as a pass ("no leaks found") rather than as a stated
absence; H2 escalated into `BLOCKED`. And in neither variant is the whole
section skippable:

> Runs every time, regardless of project type — even a plan that never
> triggered `keel-plan-lens-security` or `keel-exec-reviewer-security` still
> executes this section; "nothing to check" is a claim, and like every other
> claim in this file it needs to show its work.

## Not expected (any scenario)

- A security finding that exists only in the conversation that raised it —
  fixed or not, plan-stage or execution-stage
- A missing `security:` field or a missing `## SECURITY FINDINGS` section read
  downstream as "clean" rather than as "unknown"
- `security: none` used for a skipped axis, or `no findings` used for a lens
  that never ran — the two pairs are coverage-vs-result distinctions, and
  collapsing either one converts a gap into a pass
- A secrets scan whose unit is smaller than the branch, or whose output was
  produced in an earlier session
- Any Part 2c check reported as passed on an empty input set without saying
  the set was empty and why
- A skip recorded in a spelling other than the one Part 2c check 0 matches on
  (`security axis skipped`) — check 0 pattern-matches that phrase across every
  ledger line, so a hand-reworded skip is invisible to it and the branch-level
  fallback never fires
