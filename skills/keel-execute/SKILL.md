---
name: keel-execute
description: Use when a reviewed plan is ready to implement — orchestrates subagent-driven execution with per-task review and a crash-safe progress ledger, or falls back to inline execution when subagents aren't available. Stage 4 of the unified dev pipeline; hands off to keel-finish.
provenance:
  synthesized: 2026-07-14
  sources:
    - superpowers:subagent-driven-development @6.1.1 (orchestration spine, ledger, status protocol, model matrix, two-verdict review, BASE rule; report files, pre-flight plan review, plan-mandated arbitration added 2026-07-23); capped fix-loop with round-4 tier escalation and circuit-breaker adjudication ported from @6.2.0 2026-08-01 (routed to a named `keel-exec-fixer-critical` agent instead of a model-override parameter, to match this pipeline's model-pinning discipline)
    - superpowers:executing-plans @6.1.1 (inline fallback, stop conditions, branch rule)
    - superpowers:test-driven-development @6.1.1 (delete-code-before-test, testing anti-patterns in smells.md; added 2026-07-23)
    - planning-with-files @3.5.0 (filesystem-as-memory: findings/progress files, 2-action rule)
    - mattpocock/skills code-review @1.2.0 (Fowler smell baseline in smells.md, two-axis no-merged-ranking rule, staleness/relocate-by-Delivers rule; added 2026-07-22)
    - gstack plan-eng-review sections @1.60.1.0 (evidence gate, coverage diagram; added 2026-07-23)
    - 20260807 keel-security-review-requirements 需求書 R3/R4/R5 (conditionally-triggered third review axis `keel-exec-reviewer-security`, opus-pinned, independent no-merge-ranking; added 2026-08-07)
  dropped: task-brief/review-package helper scripts (plugin-internal paths; inlined their intent as prompt rules)
---

# keel-execute — Plan Execution

```
INPUT   a plan file with a header carrying Spec Version + Success Criteria,
        and every task carrying Delivers / Files / Interfaces / Skills; if it
        came from keel-plan-review, a REVIEW REPORT ending in
        NO UNRESOLVED DECISIONS
OUTPUT  all tasks committed and reviewed on a non-main branch; ledger complete
        in .keel/progress.md; final whole-branch review passed
```

Missing INPUT → `BLOCKED: 缺 <field> → 退回 keel-plan`. A plan without those
fields silently disables brief extraction, the staleness check, and the
spec-compliance axis — three of this stage's four safety mechanisms.

Two modes, one decision at the top:

```
Subagents available AND tasks mostly independent?
├─ yes → ORCHESTRATED mode (default; better context isolation, reviewed per task)
└─ no  → INLINE mode (sequential, single context)
Tasks tightly coupled with shared evolving state? → INLINE, or go re-split the plan
```

**Universal rules (both modes):**
- Never start on main/master without explicit user consent — branch first
  (the rule itself lives in keel-workflow; this is a reference, not a redefinition).
- **Controller context check before ORCHESTRATED mode:** past ~100k tokens,
  write a handoff and fork to a fresh session first. The controller keeps
  accumulating across the whole stage and will hit mid-stage compaction —
  the exact failure the ledger exists to survive, not one to walk into.
- **Pipeline artifacts are not code.** On first creating `.keel/`,
  ensure the repo `.gitignore` contains it and commit that separately. Every
  reviewer diff excludes that path; mixing process artifacts into a task diff
  makes reviewers grade the wrong thing.
- **Continuous execution:** do not pause between tasks to ask "should I
  continue?" — checkpoint questions burn the user's time. Stop only at the
  plan's end or on a genuine blocker.
- **Glossary:** if `CONTEXT.md` exists at the repo root, include its path in
  every implementer/reviewer brief — code and test names follow its
  vocabulary.
- **Code intelligence:** if the repo is indexed by CodeGraph (a `.codegraph/`
  directory exists) or the codebase-memory-mcp server is connected, state
  that in every implementer/reviewer brief and require its use: implementers
  query it BEFORE grep/Read to locate symbols, find callers, and see the
  blast radius of an edit; reviewers use it to check a finding's impact
  beyond the diff (who else calls the changed code). One query typically
  replaces a dozen grep/read round-trips. CodeGraph caveat: query in
  English — Chinese queries silently return empty, not an error.
- **Filesystem is memory** (from planning-with-files): keep `progress.md`
  (what happened) and `findings.md` (what was learned) next to the plan.
  After every ~2 exploratory operations, write findings down. Context windows
  get compacted; files don't. If the planning-with-files plugin is installed,
  its hooks enforce this automatically — don't duplicate, just comply.

## ORCHESTRATED mode

### Pre-flight plan review (before Task 1, from superpowers)

One scan of the whole plan before any dispatch, checking for:
tasks that contradict each other, tasks that violate the plan's own Global
Constraints, and anything the plan mandates that the review rubric
(smells.md, repo standards) would flag as a defect. Findings → ONE batched
question to the user, each item quoting the plan's text and asking which
wins. Clean scan → proceed silently. Cheap once; discovering a plan
contradiction at Task 7 is not.

**Spec drift check:** if the plan header has a `Spec Version:` field and the
spec file it references still exists in the repo, compare the spec file's
current commit hash/timestamp against the one recorded in the plan header.
Mismatch → the spec body changed after the plan was written; follow
`keel-workflow`'s Backward routes entry for this case (route back to
`keel-plan` to re-align) instead of starting Task 1. No `Spec Version:` field,
or the referenced spec file can't be found → skip the check, don't block
(same skip-if-missing spirit as the staleness rule below).

**Destructive-operation scan.** In the same pass, read every task's
`Delivers:` and steps for operations that reach outside the repo and cannot
be undone by `git`: deploys, migrations against a non-ephemeral database,
data deletion, external publication, credential rotation, push or merge to a
protected branch. Each one found is its own G9 question to the user before
Task 1 — naming the exact command and the exact target — **even though the
plan already specifies it.**

That last clause is the entire point. Every other gate in this stage arbitrates
findings that *conflict* with the plan; nothing anywhere reviews what the plan
itself instructs. A task reading `Delivers: production DB migrated to the new
schema` passes G5 (no contradiction), never triggers G6 (no reviewer disagrees
with it), and reaches an implementer whose brief contains no reason to hesitate.
Plan approval is not operation authorization: the user last agreed that the
plan's *premises* were right, possibly dozens of turns and one context fork ago.

### Per task loop

0. **Read the dependency graph before dispatching anything.** Every task
   carries a `Depends on:` line — that is the plan's statement of what must
   finish first, and the user confirmed those edges at G2. It governs three
   decisions here, and nothing else in this stage can substitute for it:
   - **Order.** Never dispatch a task whose `Depends on:` names a task the
     ledger does not yet record as DONE. Task number is not dependency order.
   - **Parallelism.** The mode decision above asks whether tasks are "mostly
     independent" — read that off the graph, not off intuition. Two tasks may
     run concurrently only when neither depends on the other (directly or
     transitively) **and** their `Files:` do not overlap. File overlap alone
     is the weaker of the two tests; a dependency edge is a hard bar even
     when the files are disjoint.
   - **Which Interfaces to include** in step 1's brief — precisely the tasks
     named in `Depends on:`.

   `Depends on: none` on every task is a legitimate graph, not a missing one.
   A task naming a dependency that does not exist in the plan is a plan bug →
   `BLOCKED: Depends on 指向不存在的 task → 退回 keel-plan`.

1. **Extract the task brief** — the task's own text plus the plan header
   (Goal, Global Constraints) plus the Interfaces blocks of the tasks its
   `Depends on:` names. Pass briefs as *file paths*, never pasted into the
   prompt — pasted history bloats every downstream dispatch.
2. **Dispatch a fresh `keel-exec-implementer`** with the brief. If the task
   names domain skills (its `Skills:` field), the implementer invokes them
   before writing code. It implements, tests, commits, and reports status.
   **Staleness rule:** before editing, the implementer verifies the task's
   `Files:` paths/lines still match reality. Mismatch → relocate using the
   task's `Delivers:` behavior, note the drift in the status report; never
   blind-edit whatever now sits at the stated lines.
   **Drift threshold — when relocation stops being enough.** Record every
   relocate in the ledger. The plan as a whole has stopped matching the code
   when any of these holds:
   (a) a task's `Delivers:` describes behavior with no corresponding location
   left in the codebase at all — not moved, gone;
   (b) a third or more of the completed tasks reported a relocate;
   (c) a symbol named in some task's `Interfaces: Consumes:` doesn't exist and
   isn't produced by any earlier task.
   Any one → stop dispatching, emit
   `BLOCKED: 計畫與現況牴觸 → 退回 keel-plan` with the accumulated relocate
   list. This is `keel-workflow`'s "plan contradicts the code as it now is
   (beyond one task's fix)" route, and the threshold is what "beyond one
   task's fix" means operationally.
   Without a threshold the drift is absorbed silently: each implementer
   relocates its own task, notes it in its own report, and no one adds the
   notes up. A plan that stopped being true at Task 2 then runs to Task 9,
   each task individually reasonable and the whole built on ground that
   moved.
   **Test-first is enforced, not aspirational (from superpowers TDD):** the
   brief states that production code written before its failing test gets
   deleted and redone — not kept as "reference", not "adapted". Sunk cost is
   the wrong frame: untested code is a liability, not progress.
   **Report file:** the implementer writes its full report (what it did,
   test evidence, concerns) to `.keel/task-N-report.md`; its final
   message is ≤15 lines — status, commits, one-line test summary, concerns.
   Full reports flowing back inline is how controller contexts blow up.
3. **Review the diff — spec/quality always, security when triggered** — read-only by
   declaration (they describe fixes; only the fixer writes):
   (a) `keel-exec-reviewer-spec` — does it do what the task's `Delivers:` says:
   missing behavior, scope creep, implemented-but-wrong, interface drift;
   (b) `keel-exec-reviewer-quality` — repo standards first, plus the smell
   baseline in [smells.md](smells.md) and the design vocabulary/judgment tools
   in `keel-discover/design.md` (include both paths in the brief). Both must
   pass, on every task, no trigger condition.
   (c) `keel-exec-reviewer-security` — dispatched as a **third, independent
   axis** only when at least one of these R4 conditions is met (check all
   five before skipping). Findings tagged `plan-global` in
   `keel-plan-lens-security`'s output don't belong to any single task — note
   them once at the start of this step, not as a per-task trigger:
   - the task's `Files:` line touches an authentication/authorization/session,
     encryption, file-upload, outbound-call, or database-query-construction
     path. This is judged **semantically against the task's `Delivers:`
     content, not a literal filename/keyword match** — per keel-plan's
     existing "Delivers is truth, Files is a hint" rule. A diff that changes
     an existing data query's ownership filter still counts even if `Files:`
     only says `services/order.py` with no "auth" string in it.
   - the diff adds or modifies an externally-reachable endpoint
   - `keel-plan` marked the task high-risk
   - the plan-stage security lens (`keel-plan-lens-security`) previously
     raised a finding against this task: determined by matching the plan
     file's `## SECURITY FINDINGS` table rows by their `## Task N` tag
     against the current task's number — a tag match means condition 4 is
     met, regardless of whether that finding was later addressed.
     ("Previously raised," not "still unresolved.") Read the table from the
     plan file, never from conversation history: this controller may be a
     fresh one that never saw the review stage. No such section — the plan
     skipped `keel-plan-review`, which most plans do — means this condition
     is **unevaluable, not false**: it cannot contribute a trigger, and the
     other four conditions carry the decision alone. Say so in the ledger
     line rather than counting it as a clean miss.
   - the diff matches a sensitive-string pattern: `password`, `secret`,
     `token`, `api[_-]?key`, `BEGIN.*PRIVATE KEY`, or a connection-string
     shape
   New dependencies added to a package list (new package names, not version
   bumps) do **not** trigger this axis on their own — that's dependency
   existence verification and belongs to `keel-finish` Part 2c(3). A
   pure dependency-list change that matches none of the five conditions
   above skips this axis and cites that deferral in the ledger line below.
   Not triggered → do not dispatch it; instead write to the ledger
   `security axis skipped — <which of the five conditions was checked and
   why none matched — for a pure dependency-list change, cite "deferred to
   keel-finish Part 2c(3b)">`, so the skip is an auditable decision, not a
   silent omission.
   **When in doubt, dispatch.** Skipping this axis carries the same evidence
   burden as raising a finding: the ledger line quotes the task's `Delivers:`
   text and its diff file list, not a prose assurance. Spec and quality run
   unconditionally; this is the only axis whose omission is a judgment call,
   and the entity making that call is the same controller carrying the
   fan-out ceiling and the opus budget. Note the asymmetry the way this
   pipeline notes it everywhere else — a needless security pass costs one
   agent, a missed one costs whatever shipped.
   **Findings go in the ledger, not just the conversation.** When the axis
   runs, its Critical/Important findings and their disposition are written to
   the task's ledger line (`security:` field, see Progress ledger below).
   `keel-finish` Part 2c check (2) reads that field from a later, fresh
   context; a finding that exists only here is one that gate will never see.
   Give each reviewer the **base commit explicitly** — the commit before the
   task started, **never `HEAD~1`**, which silently drops all but the last
   commit of a multi-commit task. A reviewer with no stated base returns
   BLOCKED rather than guessing. All diffs exclude `.keel/`.
   Splitting the axes across separate agents is what makes the no-merge rule
   below structural rather than aspirational: no reviewer can see, and so
   cannot be swayed by, another's verdict.
   **Broadcast every verdict the moment it lands** — axis, PASS/FAIL, the
   single worst issue with its `file:line` anchor, and what you do next.
   **Never merge or rerank across axes** — each axis (spec, quality, and
   security when triggered) reports its own findings and its own worst
   issue, no single winner (from mattpocock code-review: a change can follow
   every standard and build the wrong thing, or vice versa; one axis must
   not mask another — a third axis does not change this rule, it just adds
   a third independent voice).
   Each reviewer reads the task brief and report as *file paths*. It returns
   findings **inline** — reviewers hold no `Write` tool and their own text
   forbids using the shell for one, so "return it as a file too" would read as
   licence to breach the read-only grant. Cap the return instead: verdict plus
   the worst findings inline, the remainder in the appendix.
   **Evidence gate:** every finding quotes the diff/code line that motivates
   it (file:line + verbatim text); no quotable line → confidence 4-5/10,
   appendix only, never the main verdict.
   **Plan-mandated findings (from superpowers):** a finding that conflicts
   with the plan's own text is the USER's decision. Present the finding and
   the plan line side by side and ask which wins. Never dismiss it because
   "the plan says so" — the plan's authorship does not grade its own work —
   and never dispatch a fix that contradicts the plan without asking.
4. **Fix loop (capped, from superpowers 6.2.0):** Critical/Important findings
   → `keel-exec-fixer` → scoped re-review of only the findings just fixed →
   repeat. The fixer touches only the listed findings; anything else it
   changes enters the next review as unreviewed risk. `PLAN-CONFLICT`
   findings are never handed to the fixer — they go to the user (gate G6).

   **Round cap: 5.** Rounds 1–3 resume the same `keel-exec-fixer` dispatch.
   Rounds 4–5 switch to `keel-exec-fixer-critical` (opus, fresh context, no
   memory of the failed attempts) — tier by agent identity, same as the
   skeptic split; **never** pass a `model` override to escalate the standard
   fixer, that's the exact anti-pattern this pipeline's model-pinning rule
   exists to prevent. A fixer that failed twice with the same context and
   model is not going to succeed a third time unchanged.
   At round 5, if findings remain: **circuit breaker trips.** Adjudicate each
   remaining finding — load-bearing (breaks a Delivers: line, security, data
   integrity) → `BLOCKED`, report to the user, do not mark the task done;
   cosmetic/non-load-bearing → park in the ledger with the ruling and proceed.
   Never loop past round 5 silently hoping the next attempt converges.
5. **Ledger append** (see below), update `.keel/state.md`, next task.

### Fan-out ceiling

≤8 concurrent and ≤16 total agents per task loop. If findings exceed what the
fix loop can carry, sort by severity, handle the top N, and emit
`SKIPPED: <n> — <id + reason>`. Silent truncation reads as full coverage when
it isn't.

### Dispatch discipline

Name the `subagent_type` on every dispatch — a `general-purpose` agent inside
this stage is a bug, and the type name is what tells the user which stage and
which role is currently running. Do **not** pass a `model` override: each agent
file pins its own model and tool set, and overriding re-introduces the silent
model-inheritance problem those pins exist to prevent.

### Implementer status protocol

| Status | Meaning | Controller action |
|--------|---------|-------------------|
| DONE | Complete, tests pass | Review, proceed |
| DONE_WITH_CONCERNS | Complete but flagged | Review with the concerns in the reviewer brief |
| NEEDS_CONTEXT | Missing information | Answer from plan/spec; if absent there, that's a plan bug — fix the plan |
| BLOCKED | Cannot proceed | Never re-dispatch the same prompt to the same model unchanged; diagnose first |

Anything a subagent reports that you cannot verify from artifacts (diff,
test output) — resolve personally before marking the task complete.
"Agent said success" is not evidence; the diff is.

### Model selection — pinned, not chosen per dispatch

Model choice lives in each agent's frontmatter, not in this prose. That is
deliberate: the previous rule ("always specify the model explicitly") was
prose, and prose rules drift — every dispatch silently inherited the session's
expensive model instead.

| Agent | model | Why |
|-------|-------|-----|
| `keel-exec-implementer` | sonnet | Ordinary implementation |
| `keel-exec-reviewer-spec` | sonnet | Checklist-shaped, high volume |
| `keel-exec-reviewer-quality` | sonnet | Checklist-shaped, high volume |
| `keel-exec-reviewer-security` | opus | R4-triggered third axis; higher-stakes judgment than the checklist-shaped axes |
| `keel-exec-fixer` | sonnet | Scope is a given findings list |
| `keel-exec-fixer-critical` | opus | Fix-loop rounds 4-5 only — standard tier stalled twice |
| `code-reviewer` (final branch) | inherit | Widest scope, last line of defence |

Do not override these at the call site. If a task is pure transcription — the
plan already contains the exact code — that is a signal the task is too small
to dispatch, not a reason to hand-tune a model.

Turn count beats token price: a cheap model that takes 4 retries costs more
than a capable one that takes 1.

### Progress ledger — crash safety

Append one line per completed task to `.keel/progress.md`:

```
Task 3: auth middleware — DONE, reviewed (2 findings fixed), commit a1b2c3d, branch feat/auth
relocated: 1 (Files: said src/auth.py:120-140; found at :200-220 by Delivers)
security: 2 Important (SQL string-building svc/order.py:44; missing authz check api/admin.py:12) → both fixed in a1b2c3d
```

The task line **carries the implementer's returned status verbatim** —
`DONE`, `DONE_WITH_CONCERNS`, and so on. `DONE_WITH_CONCERNS` additionally
carries a one-line digest of the concern, because `keel-finish` Part 2b
reconciles flagged concerns out of this file and cannot see a status that
was paraphrased away.

The **relocated** field is what makes the drift threshold above countable —
criterion (b) counts relocates across completed tasks, and a count needs a
field, not free-text concerns. Write `relocated: none` when there were none.

The **branch** field exists because a controller resuming after compaction
reads this file to recover state, and "which branch was this on" is exactly
the fact that gets lost — the failure that puts a fresh implementer on `main`.

The **security line** is written whenever the security axis ran: every
Critical/Important finding with its `file:line` and disposition, or
`security: none` if it passed clean. When the axis was skipped, that line is
the skip justification instead (see step 3c). `keel-finish` Part 2c check (2)
reads these lines — with no producer here, that gate has nothing to check and
passes vacuously, which is not the same as passing.

**On session start or after compaction: read the ledger FIRST.** Trust the
ledger and `git log` over your recollection — controllers that lost their
place have re-executed entire completed task sequences, the single most
expensive failure mode observed. The ledger is why this workflow survives
a crashed session.

### Finish

After all tasks: dispatch one final whole-branch `code-reviewer` (no model
override — it inherits the strongest available; diff from merge-base, same
two-axis rules: spec axis against the plan's
Goal + Success Criteria, quality axis with [smells.md](smells.md), no merged
ranking). The final reviewer additionally produces a **coverage diagram
(from gstack)**: trace each entry point through its branches and error
paths as an ASCII tree, grade each path [★★★ behavior+edge+error / ★★ /
★ smoke / GAP], and end with one line — `COVERAGE: N/M paths tested (X%)`.
Coverage claims without the diagram are vibes.

If this plan edited the pipeline's own skill/rule files (this repo, not a
consumer repo): **run `bash eval-fixtures/check-structure.sh` and paste its
summary line** — it verifies the structural guarantees (model/tool pins,
read-only grants, roster completeness) mechanically, and a non-zero exit is
a real failure, not a report. Then, if `eval-fixtures/RULE-INVENTORY.md`
exists: also report
`FIXTURE COVERAGE: N/M rules fixture-covered (X%)` from that file's
`## Current coverage` totals, alongside its enforced count, and list
any rule this plan added or changed that the table doesn't yet have a row
for — an unlisted new rule is the same silent-regression risk the inventory
exists to catch, one release earlier. This is a report, not a gate: a plan
may ship with fixture gaps, same as `COVERAGE` above never blocks on its own.

Then one fix pass for its findings, and **write the closing ledger line** —
without it `keel-finish` Part 3 has nothing to confirm this review against,
and its check passes vacuously exactly the way the security chain's did
before it was persisted:

```
final-review: PASS — 2 Important (svc/order.py:44 unwired guard; api/admin.py:12 missing authz) → both fixed in 9ed28b5; COVERAGE: 23/27 paths (85%)
```

`FAIL` with findings still open is a legitimate value; what is not legitimate
is the line being absent, because absent and clean are indistinguishable to
the stage that reads it. → **keel-finish**.

## INLINE mode

1. **Run the same pre-flight as ORCHESTRATED mode**, in full, before task 1:
   the plan-contradiction scan (G5), the **Spec drift check**, the
   **Destructive-operation scan** (G9), and the **dependency graph** read of
   step 0. Read the whole plan critically alongside it — concerns get raised
   BEFORE starting, not at task 7.

   Those gates live under ORCHESTRATED above only because that is where they
   were written, not because they are a property of dispatching subagents.
   **INLINE removes the second chance, not the requirement** — and it removes
   it twice over, because the G9 backstop that `keel-exec-implementer` carries
   never fires here: there is no implementer, you are it. This is also the
   mode `PROJECT-TYPE-GUIDE.md` makes the default for serverless/edge, CLI,
   and scraping work — three of the project types most likely to deploy.
2. Create a todo per task. Execute in **dependency order** per step 0, not
   task-number order: follow each step exactly, run each verification, mark
   complete. Update the ledger the same as orchestrated mode — inline
   sessions crash too.
3. Stop and ask rather than guess when: blocked, the plan has a critical
   gap, an instruction is ambiguous, or a verification keeps failing.
   **G6 gate applies here too:** a finding that conflicts with the plan's
   own text is never self-decided just because there's no separate reviewer
   subagent to raise it — the same single session that wrote the code must
   still stop and ask the user which wins, exactly as ORCHESTRATED mode's
   step 3 fix loop requires.
4. **Run the ORCHESTRATED `### Finish` block unchanged** — the final
   whole-branch `code-reviewer`, its coverage diagram, the `FIXTURE COVERAGE`
   report when this repo's own rule files were touched, then one fix pass for
   its findings. Write the closing `final-review:` ledger line.

   INLINE removes the *per-task* reviewers. It does not remove the
   branch-level one — and it is the mode that needs it most, because here the
   code's author and its only reader are the same context. `keel-finish`
   will not cover for a skip: it explicitly does not re-run this review, on
   the stated assumption that it already happened.
5. Then → **keel-finish**.

## Red flags

- Dispatching parallel implementers on overlapping files → conflicts; serialize them
- Letting the implementer's self-review substitute for review → independent reviewer, always
- "I remember where I was" after compaction → no you don't; read the ledger
- Skipping a task's failing-test step because "the code is obviously right" → the test IS the task
