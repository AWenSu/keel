# unified-dev-skills

**Five stage skills for the software development lifecycle — distilled from the best community skills, not concatenated.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skills-blueviolet)](https://code.claude.com/docs/en/skills)
[![No dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)](#install)

```
┌──────────────┐   ┌──────────┐   ┌─────────────────┐   ┌─────────────┐   ┌────────────┐
│ dev-discover │──▶│ dev-plan │──▶│ dev-plan-review │──▶│ dev-execute │──▶│ dev-finish │
│  idea → spec │   │  spec →  │   │  large/risky    │   │ orchestrated│   │  evidence  │
│   (gated)    │   │ artifact │   │  plans only     │   │  or inline  │   │ gate+merge │
└──────────────┘   └──────────┘   └─────────────────┘   └─────────────┘   └────────────┘
```

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
`SKILL.md`: no scripts, no hooks, nothing to install beyond the file itself.

## The five stages

| # | Skill | What it does | Spine | Key grafts |
|---|-------|--------------|-------|------------|
| 1 | [`dev-discover`](skills/dev-discover/SKILL.md) | Vague idea → user-approved, evidence-grounded spec. Hard gate: no code before approval. | superpowers:brainstorming | gstack spec's code-evidence rule (`path:line` before questions), five-question intake, scope lock |
| 2 | [`dev-plan`](skills/dev-plan/SKILL.md) | Spec → plan an engineer with zero context could execute. Sizing guide, Interfaces blocks, banned placeholders. | superpowers:writing-plans | planner agent's risk grading; per-task `Skills:` field naming domain skills |
| 3 | [`dev-plan-review`](skills/dev-plan-review/SKILL.md) | Multi-lens automated review (business/eng/design/DX) — auto-decides routine choices, escalates only real judgment calls, adversarially verifies its own findings. | gstack autoplan's decision system | doubt-driven refutation; Mechanical / Taste / User-Challenge taxonomy; 6 auto-decision principles |
| 4 | [`dev-execute`](skills/dev-execute/SKILL.md) | Reviewed plan → working code. Fresh implementer + independent reviewer per task, crash-safe progress ledger, model cost routing. Inline fallback when subagents aren't available. | superpowers:subagent-driven-development | executing-plans inline mode; planning-with-files filesystem-as-memory |
| 5 | [`dev-finish`](skills/dev-finish/SKILL.md) | Before any "done" claim: fresh verification evidence for every claim, drive the real flow end-to-end, then integrate the branch. | superpowers:verification-before-completion | claim→evidence table; red-green regression rule; branch integration options |

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

`agents/` is optional but recommended — without it, the pipeline still runs,
but every subagent dispatch falls back to Claude Code's generic
`general-purpose` agent instead of a named, tool-scoped, model-pinned one.

Restart Claude Code once after installing (new skill directories are only
watched from session start), then each skill is available as
`/dev-discover` … `/dev-finish`.

**Router included.** [`dev-workflow`](skills/dev-workflow/SKILL.md) detects the
current stage and dispatches — see [Suggested routing](#suggested-routing)
below for the table, or just invoke it and let it route.

**Subagent roster.** [`agents/`](agents/) ships 11 purpose-built subagent
definitions the pipeline dispatches by name — `dev-plan-lens-ceo`,
`dev-exec-reviewer-spec`, `dev-plan-skeptic-critical`, and so on. Each pins its
own model and tool access in frontmatter (reviewers/lenses/skeptics are
read-only; only implementers and fixers write) so the pipeline never falls back
to an unlabeled `general-purpose` dispatch. Copy `agents/*` into
`~/.claude/agents/` (or your project's `.claude/agents/`) alongside `skills/`.

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
```

Each stage announces its successor and hands off — you intervene at gates
(spec approval, unresolved review decisions, branch integration), not between
every step.

### Suggested routing

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

## Provenance & upstream sync

These are **syntheses, not forks** — upstream keeps evolving. Every SKILL.md
records its sources and their versions in frontmatter. Snapshot at synthesis
time (2026-07-14):

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

## License

[MIT](LICENSE)
