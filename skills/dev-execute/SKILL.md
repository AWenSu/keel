---
name: dev-execute
description: Use when a reviewed plan is ready to implement — orchestrates subagent-driven execution with per-task review and a crash-safe progress ledger, or falls back to inline execution when subagents aren't available. Stage 4 of the unified dev pipeline; hands off to dev-finish.
provenance:
  synthesized: 2026-07-14
  sources:
    - superpowers:subagent-driven-development @6.1.1 (orchestration spine, ledger, status protocol, model matrix, two-verdict review, BASE rule; report files, pre-flight plan review, plan-mandated arbitration added 2026-07-23); capped fix-loop with round-4 tier escalation and circuit-breaker adjudication ported from @6.2.0 2026-08-01 (routed to a named `dev-exec-fixer-critical` agent instead of a model-override parameter, to match this pipeline's model-pinning discipline)
    - superpowers:executing-plans @6.1.1 (inline fallback, stop conditions, branch rule)
    - superpowers:test-driven-development @6.1.1 (delete-code-before-test, testing anti-patterns in smells.md; added 2026-07-23)
    - planning-with-files @3.5.0 (filesystem-as-memory: findings/progress files, 2-action rule)
    - mattpocock/skills code-review @1.2.0 (Fowler smell baseline in smells.md, two-axis no-merged-ranking rule, staleness/relocate-by-Delivers rule; added 2026-07-22)
    - gstack plan-eng-review sections @1.60.1.0 (evidence gate, coverage diagram; added 2026-07-23)
  dropped: task-brief/review-package helper scripts (plugin-internal paths; inlined their intent as prompt rules)
---

# dev-execute — Plan Execution

```
INPUT   a plan file whose every task carries Delivers / Files / Interfaces /
        Skills; if it came from dev-plan-review, a REVIEW REPORT ending in
        NO UNRESOLVED DECISIONS
OUTPUT  all tasks committed and reviewed on a non-main branch; ledger complete
        in .dev-pipeline/progress.md; final whole-branch review passed
```

Missing INPUT → `BLOCKED: 缺 <field> → 退回 dev-plan`. A plan without those
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
  (the rule itself lives in dev-workflow; this is a reference, not a redefinition).
- **Controller context check before ORCHESTRATED mode:** past ~100k tokens,
  write a handoff and fork to a fresh session first. The controller keeps
  accumulating across the whole stage and will hit mid-stage compaction —
  the exact failure the ledger exists to survive, not one to walk into.
- **Pipeline artifacts are not code.** On first creating `.dev-pipeline/`,
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

### Per task loop

1. **Extract the task brief** — the task's own text plus the plan header
   (Goal, Global Constraints) plus the Interfaces blocks of completed tasks
   it consumes. Pass briefs as *file paths*, never pasted into the prompt —
   pasted history bloats every downstream dispatch.
2. **Dispatch a fresh `dev-exec-implementer`** with the brief. If the task
   names domain skills (its `Skills:` field), the implementer invokes them
   before writing code. It implements, tests, commits, and reports status.
   **Staleness rule:** before editing, the implementer verifies the task's
   `Files:` paths/lines still match reality. Mismatch → relocate using the
   task's `Delivers:` behavior, note the drift in the status report; never
   blind-edit whatever now sits at the stated lines.
   **Test-first is enforced, not aspirational (from superpowers TDD):** the
   brief states that production code written before its failing test gets
   deleted and redone — not kept as "reference", not "adapted". Sunk cost is
   the wrong frame: untested code is a liability, not progress.
   **Report file:** the implementer writes its full report (what it did,
   test evidence, concerns) to `.dev-pipeline/task-N-report.md`; its final
   message is ≤15 lines — status, commits, one-line test summary, concerns.
   Full reports flowing back inline is how controller contexts blow up.
3. **Review the diff with two independent reviewers** — one per axis, both
   read-only by declaration (they describe fixes; only the fixer writes):
   (a) `dev-exec-reviewer-spec` — does it do what the task's `Delivers:` says:
   missing behavior, scope creep, implemented-but-wrong, interface drift;
   (b) `dev-exec-reviewer-quality` — repo standards first, plus the smell
   baseline in [smells.md](smells.md) and the design vocabulary/judgment tools
   in `dev-discover/design.md` (include both paths in the brief). Both must
   pass.
   Give each the **base commit explicitly** — the commit before the task
   started, **never `HEAD~1`**, which silently drops all but the last commit
   of a multi-commit task. A reviewer with no stated base returns BLOCKED
   rather than guessing. Both diffs exclude `.dev-pipeline/`.
   Splitting the axes across two agents is what makes the no-merge rule below
   structural rather than aspirational: neither reviewer can see, and so
   cannot be swayed by, the other's verdict.
   **Broadcast both verdicts the moment they land** — axis, PASS/FAIL, the
   single worst issue with its `file:line` anchor, and what you do next.
   **Never merge or rerank across the two axes** — each axis reports its own
   findings and its own worst issue, no single winner (from mattpocock
   code-review: a change can follow every standard and build the wrong
   thing, or vice versa; one axis must not mask the other).
   The reviewer reads the task brief and report as *file paths* and returns
   findings the same way when long — same inline-bloat rule as step 2.
   **Evidence gate:** every finding quotes the diff/code line that motivates
   it (file:line + verbatim text); no quotable line → confidence 4-5/10,
   appendix only, never the main verdict.
   **Plan-mandated findings (from superpowers):** a finding that conflicts
   with the plan's own text is the USER's decision. Present the finding and
   the plan line side by side and ask which wins. Never dismiss it because
   "the plan says so" — the plan's authorship does not grade its own work —
   and never dispatch a fix that contradicts the plan without asking.
4. **Fix loop (capped, from superpowers 6.2.0):** Critical/Important findings
   → `dev-exec-fixer` → scoped re-review of only the findings just fixed →
   repeat. The fixer touches only the listed findings; anything else it
   changes enters the next review as unreviewed risk. `PLAN-CONFLICT`
   findings are never handed to the fixer — they go to the user (gate G4).

   **Round cap: 5.** Rounds 1–3 resume the same `dev-exec-fixer` dispatch.
   Rounds 4–5 switch to `dev-exec-fixer-critical` (opus, fresh context, no
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
5. **Ledger append** (see below), update `.dev-pipeline/state.md`, next task.

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
| `dev-exec-implementer` | sonnet | Ordinary implementation |
| `dev-exec-reviewer-spec` | sonnet | Checklist-shaped, high volume |
| `dev-exec-reviewer-quality` | sonnet | Checklist-shaped, high volume |
| `dev-exec-fixer` | sonnet | Scope is a given findings list |
| `dev-exec-fixer-critical` | opus | Fix-loop rounds 4-5 only — standard tier stalled twice |
| `code-reviewer` (final branch) | inherit | Widest scope, last line of defence |

Do not override these at the call site. If a task is pure transcription — the
plan already contains the exact code — that is a signal the task is too small
to dispatch, not a reason to hand-tune a model.

Turn count beats token price: a cheap model that takes 4 retries costs more
than a capable one that takes 1.

### Progress ledger — crash safety

Append one line per completed task to `.dev-pipeline/progress.md`:

```
Task 3: auth middleware — DONE, reviewed (2 findings fixed), commit a1b2c3d
```

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
Coverage claims without the diagram are vibes. Then one fix pass for its
findings → **dev-finish**.

## INLINE mode

1. Read the whole plan critically. Concerns → raise them BEFORE starting,
   not at task 7.
2. Create a todo per task. Execute in order: follow each step exactly, run
   each verification, mark complete. Update the ledger the same as
   orchestrated mode — inline sessions crash too.
3. Stop and ask rather than guess when: blocked, the plan has a critical
   gap, an instruction is ambiguous, or a verification keeps failing.
4. After all tasks → **dev-finish**.

## Red flags

- Dispatching parallel implementers on overlapping files → conflicts; serialize them
- Letting the implementer's self-review substitute for review → independent reviewer, always
- "I remember where I was" after compaction → no you don't; read the ledger
- Skipping a task's failing-test step because "the code is obviously right" → the test IS the task
