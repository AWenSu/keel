# unified-dev-skills

**A five-stage software development lifecycle for Claude Code — one skill per stage, a named subagent for every role, and hard gates where correctness matters more than speed.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skills-blueviolet)](https://code.claude.com/docs/en/skills)
[![No dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)](#install)

[繁體中文版 README](README.zh-TW.md)

```
┌──────────────┐   ┌──────────┐   ┌─────────────────┐   ┌─────────────┐   ┌────────────┐
│ dev-discover │──▶│ dev-plan │──▶│ dev-plan-review │──▶│ dev-execute │──▶│ dev-finish │
│  idea → spec │   │  spec →  │   │  large/risky    │   │ orchestrated│   │  evidence  │
│   (gated)    │   │ artifact │   │  plans only     │   │  or inline  │   │ gate+merge │
└──────────────┘   └──────────┘   └─────────────────┘   └─────────────┘   └────────────┘
        ▲                                  │                     │
        └──────────── dev-discover ◀───────┘   dev-plan ◀────────┘   dev-debug ◀── dev-finish
                (round 3 still unresolved)   (contradicts plan)   (evidence can't be produced)
```

`dev-workflow` sits above all five stages as the router: it detects which
stage a request belongs to, dispatches the matching skill, and — this is the
part most routers skip — knows how to send work **backward** when a later
stage discovers the earlier one got something wrong.

## Why this exists

A well-equipped Claude Code setup accumulates overlapping planning skills:
superpowers' lifecycle chain, gstack's heavyweight review suite,
planning-with-files' persistence layer, custom planner agents. Each is
excellent — but the overlap costs you: **four ways to "make a plan," no single
obvious flow, and routing tables to memorize.**

This repo keeps **one skill per stage**. Each absorbs the mechanisms that
earned their place — hard gates, evidence rules, decision taxonomies, progress
ledgers, verification laws — and drops what didn't (external CLI dependencies,
telemetry, duplicated prose). Every skill is a single self-contained
`SKILL.md`: no build step, no hooks, nothing to install beyond the files
themselves.

**What changed since the first release:** the pipeline no longer dispatches
work as anonymous `general-purpose` subagents. Every role — implementer,
spec reviewer, quality reviewer, four review lenses, two tiers of adversarial
skeptic, fixer, research ticket — is a named agent definition with its own
pinned model and its own tool access. You can watch a run and know, from the
name alone, exactly who is doing what. See [Subagent roster](#subagent-roster).

## The five stages

| # | Skill | What it does | Spine | Key grafts |
|---|-------|--------------|-------|------------|
| 1 | [`dev-discover`](skills/dev-discover/SKILL.md) | Vague idea → user-approved, evidence-grounded spec. Hard gate: no code before approval. | superpowers:brainstorming | gstack spec's code-evidence rule (`path:line` before questions), five-question intake, scope lock, parallel "design it twice" exploration under diverging constraints |
| 2 | [`dev-plan`](skills/dev-plan/SKILL.md) | Spec → plan an engineer with zero context could execute. Sizing guide, `Interfaces:` blocks, banned placeholders. | superpowers:writing-plans | planner agent's risk grading; per-task `Skills:` field naming domain skills to invoke |
| 3 | [`dev-plan-review`](skills/dev-plan-review/SKILL.md) | Multi-lens automated review (CEO/Design/Eng/DX) with a mandatory prior-art web scan — auto-decides routine choices, escalates only real judgment calls, adversarially refutes its own findings before trusting them. | gstack autoplan's decision system | doubt-driven refutation; Mechanical / Taste / User-Challenge taxonomy; 6 auto-decision principles; two-tier skeptic escalation |
| 4 | [`dev-execute`](skills/dev-execute/SKILL.md) | Reviewed plan → working code. Fresh implementer + two **independent** reviewers per task (spec axis, quality axis — never merged into one verdict), crash-safe progress ledger. Inline fallback when subagents aren't available. | superpowers:subagent-driven-development | executing-plans inline mode; planning-with-files filesystem-as-memory |
| 5 | [`dev-finish`](skills/dev-finish/SKILL.md) | Before any "done" claim: fresh verification evidence for every claim, drive the real flow end-to-end, reconcile every open item scattered across the run, then integrate the branch. | superpowers:verification-before-completion | claim→evidence table; red-green regression rule; branch integration options |

**Built-in skip rules.** Small tasks (single file, reversible, <30 min) bypass
stages 1–3 entirely; only large or risky plans go through review. Planning
overhead should never exceed ~20% of the task itself.

## Install

Copy `skills/` and `agents/` into any location Claude Code loads them from:

```bash
# per-project
cp -R skills/* your-repo/.claude/skills/
cp -R agents/* your-repo/.claude/agents/

# or global
cp -R skills/* ~/.claude/skills/
cp -R agents/* ~/.claude/agents/
```

`agents/` is optional but strongly recommended — without it, the pipeline
still runs, but every subagent dispatch silently falls back to Claude Code's
generic `general-purpose` agent: no pinned model, no restricted tool access,
no name in the progress display to tell you which role is running.

Restart Claude Code once after installing (new skill/agent directories are
only picked up from session start). Each skill is then available directly —
`/dev-discover`, `/dev-plan`, `/dev-plan-review`, `/dev-execute`,
`/dev-finish` — or through the router, `/dev-workflow`.

## Usage

```text
# starting from a fuzzy idea
/dev-discover I want rate limiting on the public API

# requirements already clear
/dev-plan add CSV export to the reports page, spec in docs/specs/...

# plan is big or touches production data
/dev-plan-review

# ready to build
/dev-execute

# before you say "done"
/dev-finish

# or just describe the task and let the router figure out the stage
/dev-workflow add OAuth login to the admin panel
```

Each stage announces its successor and hands off — you intervene at
**named gates**, not between every step. Every subagent's return is
broadcast the moment it lands (verdict, one anchored finding, next step) — you
are never staring at a silent pipeline wondering what four agents are doing.

### The four gates — the only points that stop for your answer

Everything else in the pipeline proceeds without asking permission. These four
never do:

| Gate | Stage | What it asks |
|------|-------|--------------|
| **G1** | `dev-plan-review`, Step 0 | "This plan assumes X, Y, Z — correct?" The one always-asked premise check; wrong premises make every downstream finding worthless. |
| **G2** | `dev-plan-review`, Step 5 | Every surviving Taste decision and User Challenge, **one question at a time**, full context + options + consequence. Never batched into a summary. |
| **G3** | `dev-execute`, pre-flight | Batched plan-contradiction questions, asked once before Task 1 — not mid-task. |
| **G4** | `dev-execute`, per-task review | A finding that contradicts the plan's own text (`PLAN-CONFLICT`) — never auto-resolved, never auto-applied. |

### Backward routes — when a later stage finds an earlier mistake

| Trigger | From | Back to |
|---------|------|---------|
| Execution finds the plan contradicts the code as it now stands (beyond one task's fix) | `dev-execute` | `dev-plan` |
| Plan review round 3 still has unresolved decisions — the plan is fighting the spec | `dev-plan-review` | `dev-discover` |
| `dev-finish`'s evidence gate can't produce proof for a claim | `dev-finish` | `dev-debug` |
| Debugging concludes the requirement itself is wrong | `dev-debug` | `dev-discover` |

### Suggested routing (what `dev-workflow` detects)

| Signal | Route |
|--------|-------|
| Fuzzy idea, requirements unclear | `dev-discover` |
| Spec exists, multi-step work ahead | `dev-plan` |
| Plan is large/risky (>8 files, new architecture, production data) | `dev-plan-review` |
| Plan ready and straightforward | `dev-execute` |
| About to claim done / open a PR | `dev-finish` |
| Bug or test failure | your debugging skill — the pipeline is for building |
| UI/visual work | your design-skill router |

### Per-project-type defaults

Which stages to run, which review lenses fire, and what to layer on top for
**web apps, APIs, CLIs, MCP servers, serverless, docs repos, and scrapers**:
see **[PROJECT-TYPE-GUIDE.md](PROJECT-TYPE-GUIDE.md)**.

### Domain-skill layering

Skill selection happens at **plan time**, where there's global context: every
task in a `dev-plan` artifact carries a `Skills:` field naming the domain
skills its implementer must invoke (a UI-design skill for visual tasks, a
platform skill for Workers/MCP idioms). `dev-execute` passes that field into
each implementer's brief.

## Subagent roster

Every dispatch in this pipeline names a specific `subagent_type` — never the
generic `general-purpose` fallback. The name alone tells you the stage and the
role; the frontmatter pins the model and locks the tool access, so the
decision can't quietly drift the way a prose instruction ("remember to use
opus here") tends to.

**Read-only by declaration.** Every reviewer, lens, skeptic, and researcher
below is restricted to `Read, Grep, Glob, Bash` (plus search tools where
named) — it can describe a fix, never apply one. Only implementers and fixers
get write access. This is what makes "the reviewer must not edit the code it's
reviewing" a structural guarantee instead of a prompt that can be ignored.

| subagent_type | Stage | Role | model | Tools |
|---|---|---|---|---|
| `dev-discover-designer` | 1 discover | One of 3 parallel approach proposals, each under a different constraint | sonnet | read-only |
| `dev-plan-lens-ceo` | 3 review | Should this exist at all — plus a mandatory prior-art web scan | **opus** | read-only + tavily, exa, context7 |
| `dev-plan-lens-design` | 3 review | Every user-visible state named (conditional: UI-heavy plans) | sonnet | read-only |
| `dev-plan-lens-eng` | 3 review | Buildable as written — plus an API-currency check against live docs | sonnet | read-only + context7, Ref |
| `dev-plan-lens-dx` | 3 review | Developer onboarding cost (conditional: API/CLI/SDK-facing plans) | sonnet | read-only + context7 |
| `dev-plan-skeptic` | 3 review | Refute one High finding — single-point evidence check | sonnet | read-only, **no search** |
| `dev-plan-skeptic-critical` | 3 review | Refute one Critical / security / cross-file-reasoning finding | **opus** | read-only, **no search** |
| `dev-exec-implementer` | 4 execute | Build one task, test-first enforced | sonnet | full |
| `dev-exec-reviewer-spec` | 4 execute | Spec-compliance axis only | sonnet | read-only |
| `dev-exec-reviewer-quality` | 4 execute | Code-quality axis only | sonnet | read-only |
| `dev-exec-fixer` | 4 execute | Apply only the findings it was given | sonnet | full |
| `dev-wayfind-researcher` | pre-stage | Resolve one externally-answerable research ticket | sonnet | read-only + full search |

Plus three general-purpose specialists this pipeline dispatches by their
existing names when a finding calls for them: `security-auditor`,
`test-engineer`, `silent-failure-hunter`. A final whole-branch review at the
end of `dev-execute` uses `code-reviewer` with **no model override** — it
inherits whatever the strongest model in the session is, because it's the last
line of defense before `dev-finish`.

### Why two skeptic tiers instead of one model parameter

The naive way to make a "skeptic" cheaper on easy findings is to pass a
`model` override at dispatch time based on severity. This pipeline
deliberately does **not** do that — routing by model parameter is a decision
buried in a function call, invisible in the progress display, and easy to
forget under time pressure (the earlier version of this pipeline had exactly
that kind of "remember to do X" prose rule, and audits showed it was ignored
every time).

Instead, tier selection **is** agent selection:

- `dev-plan-skeptic` (sonnet) handles findings a single-point check can settle
  — does the cited line exist, does it say what's claimed.
- `dev-plan-skeptic-critical` (opus) handles Critical severity, anything
  touching security/data-loss/irreversible operations, or anything needing
  cross-file reasoning (tracing callers, finding existing guards, sizing blast
  radius).
- The standard tier can return `ESCALATE` instead of guessing past its depth
  — the controller re-dispatches to the critical tier. `ESCALATE` is never
  treated as a verdict.
- **When unsure, escalate.** The cost asymmetry is real: a skeptic that
  wrongly kills a genuine Critical finding lets a defect ride straight through
  execution to surface in production; a skeptic that wrongly spares a weak
  finding costs one extra fix-review round. The pipeline's default bias
  ("refute when evidence is weak") already leans toward killing findings — the
  model tier is the one thing standing between that bias and a real mistake.

### Prior-art scanning — catching "this is already solved" before it's built

The CEO lens (`dev-plan-lens-ceo`) runs a mandatory external scan before any
internal reasoning: existing products/libraries via web search, known failure
modes and deprecation notices via deep research, whether a named framework
already ships the feature via documentation lookup. It reports three sections
— existing solutions, known dead ends, and a **concrete difference** that
justifies building this anyway.

That third section is a hard gate deliberately: a prior-art finding that can't
name a specific difference from our situation is capped at low confidence and
can never sink a plan or become a User Challenge on its own. Surface-level name
collision is not duplication, and killing legitimate work on a shallow match
would be the single most expensive mistake this lens could make.

The Eng lens (`dev-plan-lens-eng`) runs a parallel check on API currency —
verifying that every framework/library/API the plan names against current
documentation hasn't been deprecated or removed since the plan was written.

**Every external finding requires a URL, a retrieval date, and a verbatim
quote** — the same evidence discipline the pipeline already applies to
internal `file:line` citations. Fetched content is explicitly treated as
untrusted input: instructions embedded in a search result or a doc page are
ignored, only factual claims are extracted.

### Fan-out ceiling

No stage dispatches an unbounded number of agents. The cap is **≤8 concurrent,
≤16 total per stage**; if the real workload exceeds that, the pipeline sorts
by severity, covers the top N, and **must** emit a `SKIPPED: <n> — <reason>`
line. Silent truncation is treated as a bug — a stage that quietly covers 60%
of the findings and reports as if it covered 100% is worse than one that never
ran.

## Provenance & upstream sync

These are **syntheses, not forks** — upstream keeps evolving. Every SKILL.md
records its sources and their versions in frontmatter. Snapshot at synthesis
time (2026-07-14; subagent roster and prior-art scanning added 2026-07-30):

| Upstream | Version | Repo |
|----------|---------|------|
| superpowers | 6.1.1 | [obra/superpowers](https://github.com/obra/superpowers) |
| gstack | 1.60.1.0 | [garrytan/gstack](https://github.com/garrytan/gstack) |
| planning-with-files | 3.5.0 | [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) |

To sync with upstream:

1. Check upstream releases against the versions above.
2. Read their changelogs for **mechanism** changes (new gates, new protocols).
   Prose rewrites and fixes to machinery deliberately dropped here (Codex
   hooks, telemetry, mockup boards) don't apply.
3. Port mechanism changes into the affected stage skill; bump the version in
   its frontmatter.

If you run the upstream skills alongside these, prefer the heavyweight
originals when their extra machinery earns its cost — e.g. gstack `/autoplan`
for >15-file plans (dual-model consensus), gstack `spec` when the output
should be a GitHub issue.

## Design rules

- **Distill, don't concatenate** — a mechanism gets in by being load-bearing,
  not by existing.
- **Gates are sacred, artifacts can shrink** — under time pressure, write a
  smaller spec; never skip approval.
- **Evidence over reports** — a subagent's "success," a stale test run, and
  "should work" are not evidence; diffs and fresh command output are.
- **Filesystem over context window** — anything that must survive compaction
  goes in a file.
- **A named agent over a prose reminder** — if a rule matters ("use the strong
  model here," "don't let this one write files"), encode it in the
  dispatched agent's frontmatter, not in a sentence hoping to be remembered.

## Contributing

Issues and PRs welcome — especially reports of upstream mechanism changes this
repo hasn't ported yet, or a stage/gate/agent that turned out not to earn its
keep in real use. Keep the design rules above in mind: a contribution should
distill, not add a fourth way to do something the pipeline already does once.

## License

[MIT](LICENSE)
