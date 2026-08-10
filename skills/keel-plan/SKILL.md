---
name: keel-plan
description: Use when you have an approved spec or clear requirements for a multi-step task, before touching code — produces a plan file precise enough that an engineer with zero codebase context could execute it. Stage 2 of the unified dev pipeline; hands off to keel-plan-review (large tasks) or keel-execute.
provenance:
  synthesized: 2026-07-14
  sources:
    - superpowers:writing-plans @6.1.1 (plan artifact format, Interfaces block, No Placeholders, task right-sizing, type-consistency check)
    - ~/.claude/agents/planner.md (risk grading, sizing guide, success-criteria checklist)
    - mattpocock/skills to-tickets + tdd @1.2.0 (Delivers behavior line, tests-only-at-confirmed-seams, expand–contract wide-refactor sequencing; added 2026-07-22); vertical-slice task framing and post-breakdown granularity/dependency quiz added 2026-08-01
  dropped: nothing significant — the sources composed cleanly
---

# keel-plan — Implementation Planning

Write the plan for an engineer with zero context for this codebase and
questionable taste. Every ambiguity you leave is a decision they will make
wrong.

```
INPUT   an approved spec (keel-discover) or requirements clear enough to name
        exact file paths
OUTPUT  a plan file: header (Goal, Spec Version, Global Constraints, Success
        Criteria) + tasks each carrying Delivers / Files / Interfaces /
        Skills, no placeholder phrases
```

Missing INPUT → `BLOCKED: 缺 <approved spec | requirements naming exact file
paths> → 退回 keel-discover`. This is the INPUT-contract miss every stage
declares; it is distinct from the spec-status gate below, which fires when a
spec *exists* but is not yet approved.

**If INPUT is the spec path**, the spec's `Status:` field must read
`approved` before this skill proceeds; otherwise `BLOCKED: spec 未核准 →
退回 keel-discover`. This check is scoped to an actual spec file — it does
not apply to the "requirements clear enough to name exact file paths" path
or the Medium-task lightweight shortcut below, neither of which has a spec
file to check.

## When to skip

Single-file reversible changes don't need a plan file. Medium tasks
(multi-file, under half a day) may use the lightweight path: dispatch the
`planner` agent (by name, never `general-purpose`; **do not pass a `model`
override**) for a one-shot plan you review in-conversation, skip the
artifact. This skill's full artifact is for work that will be executed over
multiple sessions or by subagents.

**The lightweight path still owes the four fields.** `keel-execute` consumes
`Delivers:` (spec-axis review + staleness relocation), `Files:` (brief
extraction + staleness check), `Interfaces:` (downstream task briefs), and
`Skills:` (domain-skill invocation), and `Depends on:` (dispatch order,
parallelism, and which Interfaces reach a brief). State the required shape in the `planner`
dispatch, and check the return. Any field missing → the shortcut is void; write
the full artifact here. A plan that omits them doesn't fail loudly at
execution — it silently disables three of that stage's safety mechanisms.

## Sizing guide (from planner)

| Size | Phases | Steps | Plan artifact? |
|------|--------|-------|----------------|
| Small | 1 | 3–5 | No — just do it with a todo list |
| Medium | 2–3 | 8–15 | Optional — planner agent one-shot usually enough |
| Large | 3–5 | 15–30 | Required — this skill, full format |

If you're above 5 phases or 30 steps, the spec covers too much: go back and
split it into separate specs first.

## Workflow

### 1. Scope check, then map files

Multi-subsystem spec → separate plans. Then, before writing any task, map the
file structure the work will touch — this is where decomposition decisions
get locked in. Read enough real code to name exact paths.

Read `CONTEXT.md` at the repo root if it exists — the project's domain
glossary. Task names, new symbols, and Interfaces blocks must use its
vocabulary; a plan that renames a glossary concept is planting an
inconsistency. Also read `docs/adr/` for the areas this plan touches —
ADRs record decisions the plan must not re-litigate; a task that
contradicts one must say so explicitly ("contradicts ADR-0007 — reopened
because …"), never silently.

### 2. Write the plan header

Save to `docs/plans/YYYY-MM-DD-<feature>.md` with this header:

```markdown
# Plan: <feature>

> **For agentic workers:** execute with keel-execute.

**Goal:** <one sentence>
**Spec:** <link to the keel-discover spec>
**Spec Version:** <commit hash or timestamp copied from the spec's `Status:`
  field at the moment it was approved>
**Architecture:** <2-3 sentences, ASCII diagram if data flows>
**Global Constraints:** <exact values copied verbatim from the spec —
  limits, formats, naming, versions. Never paraphrase.>
**Success Criteria:** <checklist copied from the spec's "how will we know
  it's done" — the final gate checks these boxes. Format follows the spec's
  Given-When-Then three-part form (scenario / condition / expected result),
  not rewritten into prose>
```

### 2a. Reserve the Signals section

Immediately after the header, write the section `keel-finish` Part 2d fills
in before integrating — empty now, with the three prompts as placeholders:

```markdown
## Signals
<!-- keel-finish Part 2d writes these before integrating; leave them here -->
**Worked:** <the observation that would show this did what it was for>
**Wrong:** <the observation meaning the requirement was mistaken, not the code>
**Instrumented:** <yes / TODOS.md ref / nothing to watch>
```

A `##` section, not a header field: six places downstream read
`## Signals` by that exact name — `keel-finish` Part 2d, `keel-workflow`'s
SIGNALS route and its Backward-routes row, `keel-discover`'s negative-signal
intake, and fixture `23`. A field named `Signals:` in the header would
satisfy none of them, which is what this file shipped with for one commit.

### 2b. Feature matrix for UI-heavy plans

Reuse `keel-plan-lens-design`'s existing trigger, verbatim — do not invent a
second keyword rule: it "runs only when the plan hits 2+
view/rendering/UI/component/screen keywords." When this plan hits that same
criterion, before writing tasks, produce a feature × state/role/platform
matrix (table form) and save it under a new `## Feature Matrix` section in
the plan file (or in `CONTEXT.md` if the project already has one, with the
plan file linking to it).

Under the same trigger, add one line to the plan header:

```
**Visual source of truth:** <approved mockup path | the existing screen this
  must match | the design system/theme it follows | the design skill whose
  conventions it adopts>
```

One of those four, named. Without it the plan can specify every state and
still leave every visual decision to whoever picks up the ticket — and three
tasks will answer it three different ways. `keel-plan-lens-design` §B checks
that one of those four is named *somewhere* in the plan; this header line is
the cheapest way to satisfy it, and until it existed that check fired on
nearly every UI plan — which is how a reviewer learns to skim an axis.

Plans that do not hit the criterion skip this step entirely — no matrix, no
visual-source line, no added planning overhead.

### 3. Write tasks

**Context check first.** Task-writing is long and detail-dense. Past ~120k
tokens, write a handoff and fork rather than pushing on degraded — a plan
written past that line is where placeholder phrases and type-inconsistent
names come from. (`keel-workflow`'s smart-zone rule.)


Each task uses this template:

```markdown
## Task N: <name>   [Risk: Low|Med|High]

**Delivers:** <the end-to-end behavior this task makes work, stated so it
  can be verified without reading the code — the task's source of truth>
**Files:** exact paths, with line ranges for edits (`src/auth.py:123-145`) —
  location hints, not truth; see the staleness rule below
**Depends on:** Task M / none
**Skills:** <domain skills the implementer must invoke, or "none" — e.g. a
  UI-design skill for visual tasks, a platform skill (Cloudflare, MCP
  builder) for platform idioms. Name them now so execution doesn't have to
  rediscover them.>
**Interfaces:**
  - Consumes: <exact names + signatures this task uses from earlier tasks>
  - Produces: <exact names + signatures later tasks will use>

- [ ] Write failing test for <specific behavior>
- [ ] Run it, verify it fails
- [ ] Implement minimal code to pass
- [ ] Run it, verify it passes
- [ ] Commit
```

Rules that make plans executable:

- **Delivers is the truth; Files are hints (from mattpocock to-tickets).**
  Behavior statements don't go stale; line numbers do. Write **Delivers**
  from the user's perspective, precise enough to verify. Paths and line
  ranges stay — they save the implementer a search — but if reality
  disagrees with them at execution time, the implementer relocates by the
  Delivers line instead of editing whatever now sits at those lines.
- **Each step is one action (2–5 minutes).** A step you can't verify in one
  command is two steps.
- **Interfaces block is mandatory** wherever tasks share symbols. A task's
  implementer sees only their own task — this block is how they learn what
  their neighbors named things.
- **Risk grade every task** (from planner): High = data migration,
  auth/security paths, irreversible operations. High-risk tasks get a named
  rollback step.
- **Right-sizing:** split only where a reviewer could meaningfully reject one
  task while approving its neighbor. Smaller is not automatically better.
- **Vertical slices, not horizontal (from mattpocock to-tickets).** A task
  cuts a narrow but complete path through every layer it touches (schema,
  API, UI, tests) — not "the DB layer" as one task and "the UI layer" as
  another. A completed task is demoable or verifiable on its own; a
  horizontal slice never is until every other layer's task also lands. The
  wide-refactor exception in 3b is deliberate — that's the one case a
  horizontal cut is correct.
- **Tests only at confirmed seams.** Every "write failing test" step names
  the seam from the spec's **Test seams** section it exercises, and the test
  observes behavior through that interface only — no internals, no private
  methods, no side channels. A task that needs an unconfirmed seam is a
  design change: stop and take it back to the spec. If the spec predates
  seam negotiation and has no Test seams section, propose the seam list to
  the user before writing any task.
- **Expected values are independent.** A test step's expected value comes
  from a source the implementation can't influence — a known-good literal,
  a worked example, the spec. Recomputing it the way the implementation
  computes it makes the test tautological: it passes by construction.

### 3b. Wide refactors — expand–contract, not slices (from mattpocock to-tickets)

A **wide refactor** is one mechanical change — rename a column, retype a
shared symbol — whose blast radius fans across the codebase, so no vertical
task can land green on its own. Don't force it into the normal task shape;
sequence it as **expand–contract**:

1. **Expand** (one task): add the new form beside the old — nothing breaks.
2. **Migrate** (one task per batch): move call sites over in batches sized
   by blast radius (per package, per directory). Every batch depends on the
   expand task; each leaves CI green because the old form still exists.
3. **Contract** (one task, depends on every migrate batch): delete the old
   form once zero callers remain.

If even the batches can't stay green alone, keep the same sequence on a
shared integration branch, all batches feeding one final integrate-and-verify
task — green is promised only there, and the plan says so explicitly.

### 4. No placeholders — banned phrases

A plan containing any of these is unfinished:
- "TBD" / "figure out during implementation"
- "Add appropriate error handling" (name the errors and what happens)
- "Similar to Task N" (repeat the code — implementers don't see Task N)
- References to types/functions no task defines

### 5. Self-review

One pass, fix and move on:
- Every spec requirement maps to a task (coverage)
- Placeholder scan (step 4 list)
- **Type-consistency across tasks:** `clearLayers()` in Task 3 but
  `clearFullLayers()` in Task 7 is a bug you're planting now
- Each phase leaves the system working (incremental, from planner)

### 6. Quiz the user on the breakdown (from mattpocock to-tickets)

Present the task list as titles + **Depends on** edges only (not the full
plan) and ask two questions before exit:

- Does the granularity feel right — any task too coarse to review as one
  unit, or too fine to be worth a separate task?
- Are the `Depends on` edges correct — does each task depend only on tasks
  that genuinely gate it, no more and no less?

This is the only human checkpoint most plans get on their task breakdown —
**keel-plan-review is optional and skipped by most plans** (only large/risky
ones route through it). Skip this quiz only when the plan is heading into
keel-plan-review anyway; `keel-plan-lens-eng` re-examines the breakdown and
the `Depends on:` edges in more depth
and asking twice wastes a round-trip.

## Exit

Offer exactly two paths:

1. **Large / risky plan** → **keel-plan-review** first (recommended when: >8
   files, new architecture, production data, or you have any Taste-level
   doubt about the approach)
2. **Plan is straightforward** → **keel-execute** directly

Return only the plan. Do not begin implementation — that's keel-execute's job,
after any review.
