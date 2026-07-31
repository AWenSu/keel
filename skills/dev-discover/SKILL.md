---
name: dev-discover
description: Use when starting any feature, change, or project whose requirements are not yet nailed down — turns a vague idea into a user-approved, evidence-grounded spec before any code is written. Stage 1 of the unified dev pipeline; hands off to dev-plan.
provenance:
  synthesized: 2026-07-14
  sources:
    - superpowers:brainstorming @6.1.1 (workflow spine, HARD-GATE, one-question rule, spec self-review)
    - gstack:spec @1.60.1.0 (five-question intake, code-evidence rule, dedupe, scope lock)
    - mattpocock/skills domain-modeling @1.2.0 (CONTEXT.md glossary: challenge terms, sharpen fuzzy language, inline updates; ADR three-condition trigger added 2026-07-23)
    - mattpocock/skills codebase-design + DEEPENING @1.2.0 (design.md vocabulary, deletion test, dependency-category test strategy, design-it-twice; added 2026-07-23)
  dropped: visual companion (niche, heavy), Codex quality gate (external dep), telemetry, GitHub issue filing (use gstack spec directly when you need issues)
---

# dev-discover — Requirements Discovery & Spec

```
INPUT   a raw idea or request, plus access to the real codebase
OUTPUT  a user-approved spec: scope locked, test seams agreed, every
        requirement grounded in evidence rather than recollection
```

Turn "I want X" into a written, approved spec. Nothing downstream (plan, review,
execution) can be better than the spec it started from.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project,
or take any implementation action until a design has been presented and the
user has approved it. This gate has no exceptions for "simple" projects —
simple projects are where unexamined assumptions waste the most work.
</HARD-GATE>

## When to skip

Skip this skill only when a written spec already exists, or the change is a
single-file reversible edit with an obvious shape. If you skip, say so in one
line and go to dev-plan or straight to work.

## Workflow

Create a task for each step. Do them in order.

### 1. Ground yourself in evidence, not memory

Before asking the user anything, read the project: relevant files, docs,
recent commits. **The evidence rule (from gstack spec):** every technical
question you ask must be backed by at least one thing you actually read —
cite `path:line` when you reference existing behavior. If you searched and
found nothing, say "greenfield, nothing to cite" explicitly. Never ask the
user something the codebase already answers.

Read `CONTEXT.md` at the repo root if it exists — it is the project's domain
glossary. Use its vocabulary in every question, spec section, and name you
propose from here on.

### 2. Five-question intake

Answer these five (ask the user only for the ones evidence can't answer):

1. **Who** is affected / who is this for?
2. **What happens today** (current behavior, with `path:line` evidence)?
3. **What should happen** instead?
4. **Why now** — what breaks or is lost by not doing this?
5. **How will we know it's done** — observable success criteria?

**Dedupe check:** before going deeper, search for prior art — existing
issues, TODOs, docs, or code that already solves part of this. Duplicated
work is the most expensive kind.

### 3. Clarify — one question per message

Ask clarifying questions **one at a time**, multiple-choice where possible.
Batching five questions gets you five shallow answers; one good question gets
a real decision.

**Two depth settings (grill mode from mattpocock grilling):**

- **Fast (default):** stop when you can state the requirements without
  guessing.
- **Grill:** activated when the user says "grill me" (or equivalent), or
  automatically when the work is high-risk (production data, security
  paths, irreversible operations). Every question carries your recommended
  answer. Walk every branch of the decision tree, resolving dependent
  decisions one by one — don't stop at "probably fine". Exit only when the
  user explicitly confirms shared understanding; never declare it yourself.
  In grill mode, note in the spec header: `Discovery: grill mode`.

**Domain-language discipline (from domain-modeling)** — runs throughout this
step, not after it:

- **Challenge conflicts.** The user uses a term that contradicts `CONTEXT.md`
  → call it out immediately: "Glossary defines 'cancellation' as X, you seem
  to mean Y — which is it?"
- **Sharpen fuzzy terms.** Vague or overloaded word ("account", "sync",
  "done") → propose a precise canonical term and get agreement.
- **Cross-check code.** The user states how something works → verify the code
  agrees; surface contradictions with `path:line`.
- **Update CONTEXT.md inline.** The moment a term is resolved, write it to
  `CONTEXT.md` — don't batch. Create the file on the first resolved term if
  it doesn't exist. Format: `**Term** — definition (one line, no
  implementation details)`. CONTEXT.md is a glossary and nothing else — no
  specs, no scratch notes, no implementation decisions.

If the request spans multiple subsystems, decompose FIRST: each sub-project
gets its own discover → plan → execute cycle. Don't interrogate details of
part 3 before part 1 is scoped.

### 4. Propose approaches

Present 2–3 approaches with trade-offs. Lead with your recommendation and
say why. Always include the minimal-viable option — the user must see what
"smallest thing that works" looks like even if you recommend more.

**Design it twice (from mattpocock codebase-design)** — when the work
centers on a new interface or module boundary (not for straightforward
changes): spawn 3 parallel `dev-discover-designer` subagents (never
`general-purpose`, no model override — the agent pins its own), each designing
under a *different* constraint — "minimize the interface, 1-3 entry points max"
/ "maximize flexibility" / "optimize for the most common caller". Name the
constraint in each dispatch and broadcast each proposal as it returns, so the
divergence is visible before you compare. Each returns
interface + usage example + what's hidden + trade-offs. Compare by depth,
locality, and seam placement (design.md terms), then present a strong
recommendation, not a menu. Approaches from one context correlate — they
share your blind spots; constraint-differentiated ones don't.

### 5. Lock scope

State explicitly, and get agreement on:
- **In scope** — what this delivers
- **Out of scope** — named things you are deliberately NOT doing
- **MVP cut line** — if time runs out, what ships first
- **Failure modes** — what can go wrong at runtime, and the rollback story

Scope agreed = scope locked. Later expansion is a new decision, not a drift.

### 5b. Agree the test seams (from mattpocock to-spec/tdd)

A **seam** is the public interface a test exercises without reaching inside.
Use the vocabulary and judgment tools in [design.md](design.md) — deep vs
shallow modules, the deletion test, "one adapter is a hypothetical seam,
two make it real". Before writing the spec, sketch the seams this work will
be tested at and confirm them with the user in one question. Three rules:

- **Existing seams first** — prefer interfaces the codebase already has
- **Highest seam possible** — test where the behavior is observable to a
  caller, not where the code happens to live
- **Fewer is better** — the ideal number is one; each extra seam needs a
  reason

For each confirmed seam, classify its dependencies with design.md's
four-category table — the category decides mock vs stand-in vs real
mechanically, so dev-plan doesn't answer it ad hoc per task.

The confirmed list (seams + dependency categories) goes in the spec's
**Test seams** section. Downstream, dev-plan may only place tests at these
seams — a task that needs an unconfirmed seam is a spec change, not a
planning decision.

### 6. Write the spec

Write the design to `docs/specs/YYYY-MM-DD-<topic>.md` and commit it.
Sections: Problem / Current behavior (with evidence) / Proposed design /
Alternatives considered / Test seams (from 5b) / Out of scope /
Success criteria.

Write the spec in `CONTEXT.md` vocabulary throughout — a spec that invents
its own words for things the glossary already names is a defect (step 7
checks this).

**ADR offer (from mattpocock domain-modeling):** if a decision locked in
this spec meets ALL three conditions — hard to reverse, surprising without
context, the result of a real trade-off — offer to record it as an ADR in
`docs/adr/NNNN-<slug>.md`. One paragraph is a valid ADR: the decision,
the why, the trade-off accepted. Miss any condition → skip; ADR noise is
worse than no ADRs. Specs get archived; ADRs are what stops a future
session from unknowingly re-litigating this.

### 7. Self-review, then user review

One inline pass before showing the user — fix and move on, no re-review loop:
- Placeholder scan: no "TBD", no "figure out later"
- Glossary check: every domain term matches `CONTEXT.md`; terms resolved
  during step 3 are actually written there
- Consistency: does any section contradict another?
- Ambiguity: could a stranger implement from this without asking you anything?
- Scope: does anything in the design exceed what was locked in step 5?

Then the user reviews the written spec. Wait for explicit approval.

## Exit

The ONLY skill you invoke after dev-discover is **dev-plan**, with the
approved spec as input. If the user wants a GitHub issue instead of local
execution, hand off to gstack `spec --file-only` rather than duplicating its
issue machinery here.

## Red flags

- Writing code "just to explore" before the gate → stop, that's implementation
- Asking a question you could answer with grep → read first
- "The user seems in a hurry, skip the spec" → a two-paragraph spec beats none; shrink the artifact, never the gate
