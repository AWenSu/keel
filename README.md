# keel

**A five-stage software development lifecycle for Claude Code — one skill per stage, a named subagent for every role, and hard gates where correctness matters more than speed.**

> *The keel is the first timber laid in a ship, and every frame is built off it. Get it wrong and the hull is wrong — which is this pipeline's whole argument for gating the early stages hardest.*

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skills-blueviolet)](https://code.claude.com/docs/en/skills)
[![No dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)](#install)

[繁體中文版 README](README.zh-TW.md)

```
┌──────────────┐   ┌──────────┐   ┌─────────────────┐   ┌─────────────┐   ┌────────────┐
│ keel-discover │──▶│ keel-plan │──▶│ keel-plan-review │──▶│ keel-execute │──▶│ keel-finish │
│  idea → spec │   │  spec →  │   │  large/risky    │   │ orchestrated│   │  evidence  │
│   (gated)    │   │ artifact │   │  plans only     │   │  or inline  │   │ gate+merge │
└──────────────┘   └──────────┘   └─────────────────┘   └─────────────┘   └────────────┘
        ▲                                  │                     │
        └──────────── keel-discover ◀───────┘   keel-plan ◀────────┘   keel-debug ◀── keel-finish
                (round 3 still unresolved)   (contradicts plan)   (evidence can't be produced)
        ▲
        └──────────────────────────────────────────── post-merge Signals came back negative
                                                      (the requirement was wrong, not the code)
```

`keel-workflow` sits above all five stages as the router: it detects which
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
spec reviewer, quality reviewer, five review lenses, two tiers of adversarial
skeptic, fixer, research ticket — is a named agent definition with its own
pinned model and its own tool access. You can watch a run and know, from the
name alone, exactly who is doing what. See [Subagent roster](#subagent-roster).

## The five stages

| # | Skill | What it does | Spine | Key grafts |
|---|-------|--------------|-------|------------|
| 1 | [`keel-discover`](skills/keel-discover/SKILL.md) | Vague idea → user-approved, evidence-grounded spec. Hard gate: no code before approval. | superpowers:brainstorming | gstack spec's code-evidence rule (`path:line` before questions), five-question intake, scope lock, parallel "design it twice" exploration under diverging constraints; **a prior-art scan that searches outside the repo, not just inside it** — adopt/adapt/build becomes a recorded decision with a named 差異點, and the feature list of mature solutions is harvested even when the answer is build; spec carries a `Status: draft\|approved` gate, a `Spec Version` field, and Given-When-Then Success Criteria |
| 2 | [`keel-plan`](skills/keel-plan/SKILL.md) | Spec → plan an engineer with zero context could execute. Sizing guide, `Interfaces:` blocks, banned placeholders. | superpowers:writing-plans | planner agent's risk grading; per-task `Skills:` field naming domain skills to invoke; mattpocock to-tickets' vertical-slice task framing and post-breakdown granularity/dependency quiz; UI-heavy plans get a mandatory `### 2b.` feature matrix |
| 3 | [`keel-plan-review`](skills/keel-plan-review/SKILL.md) | Multi-lens automated review (CEO/Design/Eng/Security/DX) with a mandatory prior-art web scan — auto-decides routine choices, escalates only real judgment calls, adversarially refutes its own findings before trusting them. | gstack autoplan's decision system | doubt-driven refutation; Mechanical / Taste / User-Challenge taxonomy; 6 auto-decision principles; two-tier skeptic escalation; Step 5 auto-emits a one-paragraph ADR when a decision clears the auto-decide bar |
| 4 | [`keel-execute`](skills/keel-execute/SKILL.md) | Reviewed plan → working code. Fresh implementer + two-to-three **independent** reviewers per task (spec axis, quality axis, plus a conditional security axis when R4 triggers — never merged into one verdict), crash-safe progress ledger. Inline fallback when subagents aren't available. | superpowers:subagent-driven-development | executing-plans inline mode; planning-with-files filesystem-as-memory; pre-flight spec-drift check against a plan's recorded `Spec Version`; G6 plan-conflict gate restated for INLINE mode; Finish step reports `FIXTURE COVERAGE` against `eval-fixtures/RULE-INVENTORY.md` when a plan edits this repo's own skill files |
| 5 | [`keel-finish`](skills/keel-finish/SKILL.md) | Before any "done" claim: fresh verification evidence for every claim, drive the real flow end-to-end, reconcile every open item scattered across the run, then integrate the branch. | superpowers:verification-before-completion | claim→evidence table; red-green regression rule; branch integration options; skips re-verifying a claim already covered by a Step-5 ADR, and Success Criteria are confirmed live by the user rather than re-derived; Part 2c's secrets-scan check names the exact `gitleaks detect` invocation to run when installed |

**Built-in skip rules.** Small tasks (single file, reversible, <30 min) bypass
stages 1–3 entirely; only large or risky plans go through review. Planning
overhead should never exceed ~20% of the task itself.

**Regression-testing this pipeline's own rules.** [`eval-fixtures/`](eval-fixtures/)
verifies keel against itself two ways. `check-structure.sh` is a script —
every agent pins a model and a tool list, no read-only agent holds write
tools, every dispatched name resolves to a definition — run it before
committing any change to this repo:

```bash
bash eval-fixtures/check-structure.sh    # exit 0 = all pass
```

The `NN-*.md` files are scenario fixtures for rules a script can't judge
(does a spec marked `draft` block `keel-plan`? does a plan-vs-code
contradiction route back?), graded by walkthrough. `RULE-INVENTORY.md` lists
every declared rule with where each is enforced and what verifies it — a
row with no verifier is a rule that can regress silently, and a row whose
`Enforced at` is empty is a rule that is already broken.

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
`/keel-discover`, `/keel-plan`, `/keel-plan-review`, `/keel-execute`,
`/keel-finish` — or through the router, `/keel-workflow`.

## Usage

```text
# starting from a fuzzy idea
/keel-discover I want rate limiting on the public API

# requirements already clear
/keel-plan add CSV export to the reports page, spec in docs/specs/...

# plan is big or touches production data
/keel-plan-review

# ready to build
/keel-execute

# before you say "done"
/keel-finish

# or just describe the task and let the router figure out the stage
/keel-workflow add OAuth login to the admin panel
```

Each stage announces its successor and hands off — you intervene at
**named gates**, not between every step. Every subagent's return is
broadcast the moment it lands (verdict, one anchored finding, next step) — you
are never staring at a silent pipeline wondering what four agents are doing.

### The gates — the only points that stop for your answer

Everything else in the pipeline proceeds without asking permission. These
never do:

| Gate | Stage | What it asks |
|------|-------|--------------|
| **G1** | `keel-discover` | Spec approval. No code before you approve it; no exception for "simple" projects. |
| **G2** | `keel-plan`, Step 6 | Task-breakdown granularity and dependency edges — skipped only when the plan is going through `keel-plan-review` anyway. |
| **G3** | `keel-plan-review`, Step 0 | "This plan assumes X, Y, Z — correct?" The one always-asked premise check; wrong premises make every downstream finding worthless. |
| **G4** | `keel-plan-review`, Step 5 | Every surviving Taste decision and User Challenge, one finding per question, **batched by dependency frontier** (see below), full context + options + consequence. |
| **G5** | `keel-execute`, pre-flight | Batched plan-contradiction questions, asked once before Task 1 — not mid-task. |
| **G6** | `keel-execute`, per-task review | A finding that contradicts the plan's own text (`PLAN-CONFLICT`) — never auto-resolved, never auto-applied. |
| **G7** | `keel-finish`, Part 2 | Each Success Criterion, confirmed by you on the spot. The agent's own assessment never closes a box. |
| **G8** | `keel-finish`, Part 3 | Which integration option — and the literal typed `discard` if that's the one. |
| **G9** | any stage | An irreversible operation outside the repo: deploy, migration against a non-ephemeral database, data deletion, external publication, credential rotation, push/merge to a protected branch. Named target, exact command, asked at the point of action — **even when the plan already says to do it.** |

G1–G9 are not checkpoints. Each is a point where continuing without your
answer would skip a hard gate or do something that can't be undone — which is
why the list is closed in the other direction too: a generic "shall I
continue?" that isn't one of these rows is forbidden.

**G4 batches by dependency frontier, not one-at-a-time (from mattpocock
batch-grill-me).** Strict one-question-serial is safe but slow when most
findings don't actually depend on each other. Instead: map which findings
depend on another's answer (choice of auth pattern gates session-storage
format, say), then work it in rounds. The **frontier** is every finding whose
prerequisites are already settled — ask the whole frontier in one
`AskUserQuestion` call (its native cap is 4 questions; a bigger frontier
splits across the fewest calls needed). Apply every answer before computing
the next round — an answer often resolves or reshapes what's still open. A
question whose answer depends on one still open this round waits for the
next round; the constraint is dependency, never convenience. Done when the
frontier is empty.

### Backward routes — when a later stage finds an earlier mistake

| Trigger | From | Back to |
|---------|------|---------|
| Execution finds the plan contradicts the code as it now stands (beyond one task's fix) | `keel-execute` | `keel-plan` |
| Plan review round 3 still has unresolved decisions — the plan is fighting the spec | `keel-plan-review` | `keel-discover` |
| `keel-finish`'s evidence gate can't produce proof for a claim | `keel-finish` | `keel-debug` |
| Debugging concludes the requirement itself is wrong | `keel-debug` | `keel-discover` |
| The plan's `Spec Version` doesn't match the current spec | `keel-execute` | `keel-plan` |
| A stage's INPUT contract cannot be satisfied | any stage | the stage that owes the missing artifact |

### Suggested routing (what `keel-workflow` detects)

| Signal | Route |
|--------|-------|
| Fuzzy idea, requirements unclear | `keel-discover` |
| Spec exists, multi-step work ahead | `keel-plan` |
| Plan is large/risky (>8 files, new architecture, production data) | `keel-plan-review` |
| Plan ready and straightforward | `keel-execute` |
| About to claim done / open a PR | `keel-finish` |
| Bug, test failure, unexpected behavior | [`keel-debug`](skills/keel-debug/SKILL.md) — loop-first: no hypothesis without a red repro command |
| UI/visual work | your design-skill router |

### Per-project-type defaults

Which stages to run, which review lenses fire, and what to layer on top for
**web apps, APIs, CLIs, MCP servers, serverless, docs repos, and scrapers**:
see **[PROJECT-TYPE-GUIDE.md](PROJECT-TYPE-GUIDE.md)**. Backend API projects
now get a contract-first OpenAPI/AsyncAPI Task 0; Serverless/edge projects
with a real deploy step get a Release Runbook produced at `keel-finish`.

### Domain-skill layering

Skill selection happens at **plan time**, where there's global context: every
task in a `keel-plan` artifact carries a `Skills:` field naming the domain
skills its implementer must invoke (a UI-design skill for visual tasks, a
platform skill for Workers/MCP idioms). `keel-execute` passes that field into
each implementer's brief.

## Subagent roster

Every dispatch in this pipeline names a specific `subagent_type` — never the
generic `general-purpose` fallback. The name alone tells you the stage and the
role; the frontmatter pins the model and locks the tool access, so the
decision can't quietly drift the way a prose instruction ("remember to use
opus here") tends to.

**Read-only by tool grant, not by prose.** Lenses, skeptics, the designer,
and the researcher get `Read, Grep, Glob` (plus search tools where named) —
no shell at all, so read-only is a property of what they hold rather than a
promise they make. The three `keel-exec-reviewer-*` agents additionally get
`Bash`, since reviewing a diff requires `git diff`; each restricts that shell
to read-only commands in its own definition, a weaker guarantee and the
reason the grant goes no further. Only implementers and fixers get
`Edit`/`Write`. This is what makes "the reviewer must not edit the code it's
reviewing" structural instead of a prompt that can be ignored.

| subagent_type | Stage | Role | model | Tools |
|---|---|---|---|---|
| `keel-discover-designer` | 1 discover | One of 3 parallel approach proposals, each under a different constraint | sonnet | read-only |
| `keel-plan-lens-ceo` | 3 review | Should this exist at all — plus a mandatory prior-art web scan | **opus** | read-only + tavily, exa, context7 |
| `keel-plan-lens-design` | 3 review | Every user-visible state named (conditional: UI-heavy plans) | sonnet | read-only |
| `keel-plan-lens-eng` | 3 review | Buildable as written — plus an API-currency check against live docs | sonnet | read-only + context7, Ref |
| `keel-plan-lens-dx` | 3 review | Developer onboarding cost (conditional: API/CLI/SDK-facing plans) | sonnet | read-only + context7 |
| `keel-plan-lens-security` | 3 review | Design-time STRIDE threat modeling (conditional: 2+ security keywords, high-risk marker, or new external endpoint) | **opus** | read-only |
| `keel-plan-skeptic` | 3 review | Refute one High finding — single-point evidence check | sonnet | read-only, **no search** |
| `keel-plan-skeptic-critical` | 3 review | Refute one Critical / security / cross-file-reasoning finding | **opus** | read-only, **no search** |
| `keel-exec-implementer` | 4 execute | Build one task, test-first enforced | sonnet | full |
| `keel-exec-reviewer-spec` | 4 execute | Spec-compliance axis only | sonnet | read-only + shell restricted to `git diff`/`log`/`show`, `which`, tests |
| `keel-exec-reviewer-quality` | 4 execute | Code-quality axis only | sonnet | read-only + shell restricted to `git diff`/`log`/`show`, `which`, tests |
| `keel-exec-reviewer-security` | 4 execute | Security axis only, dispatched conditionally when an R4 trigger is hit | **opus** | read-only + shell restricted to `git diff`/`log`/`show`, `which`, tests |
| `keel-exec-fixer` | 4 execute | Apply only the findings it was given | sonnet | full |
| `keel-exec-fixer-critical` | 4 execute | Fix-loop rounds 4-5 only, after the standard tier stalls twice | opus | full |
| `keel-wayfind-researcher` | pre-stage | Resolve one externally-answerable research ticket | sonnet | read-only + full search |

`keel-exec-reviewer-spec` grades every Interface-drift finding by contract-test
evidence strength (existing test > described contract > unverified claim)
rather than taking the plan's word for it.

Plus six agents this pipeline dispatches by name but does not ship — their
model and tools are whatever your install defines, which is why the roster
above cannot pin them: `planner` (Medium-task one-shot plan),
`code-reviewer` (final whole-branch review), `test-engineer`,
`silent-failure-hunter`, `build-error-resolver` (dispatched by `keel-debug`
when the symptom is a build error). `security-auditor` is a separate, ad-hoc specialist —
it is invoked by `/security-review` or `/ship`, never dispatched by
`keel-plan-review` or `keel-execute`; the pipeline's own security coverage in
those two stages now lives in `keel-plan-lens-security` (stage 3) and
`keel-exec-reviewer-security` (stage 4, third axis). A final whole-branch
review at the end of `keel-execute` uses `code-reviewer` with **no model
override** — it inherits whatever the strongest model in the session is,
because it's the last line of defense before `keel-finish`.

### Tiering by agent identity, not by model parameter

The naive way to make a "skeptic" cheaper on easy findings is to pass a
`model` override at dispatch time based on severity. This pipeline
deliberately does **not** do that — routing by model parameter is a decision
buried in a function call, invisible in the progress display, and easy to
forget under time pressure (the earlier version of this pipeline had exactly
that kind of "remember to do X" prose rule, and audits showed it was ignored
every time).

Instead, tier selection **is** agent selection:

- `keel-plan-skeptic` (sonnet) handles findings a single-point check can settle
  — does the cited line exist, does it say what's claimed.
- `keel-plan-skeptic-critical` (opus) handles Critical severity, anything
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

The same pattern governs `keel-execute`'s fix loop (ported from superpowers
6.2.0): rounds 1-3 resume the standard `keel-exec-fixer` (sonnet); rounds 4-5
switch to a fresh `keel-exec-fixer-critical` (opus) dispatch, because a fixer
that failed twice with the same context and model isn't going to succeed a
third time unchanged. At round 5, unresolved findings trip a circuit breaker
— load-bearing ones block the task and go to the user, cosmetic ones get
parked in the ledger with a ruling. No stage in this pipeline escalates by
passing a `model` override; every escalation is a named agent.

### Prior-art scanning — catching "this is already solved" before it's built

The CEO lens (`keel-plan-lens-ceo`) runs a mandatory external scan before any
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

The Eng lens (`keel-plan-lens-eng`) runs a parallel check on API currency —
verifying that every framework/library/API the plan names against current
documentation hasn't been deprecated or removed since the plan was written.

**Every external finding requires a URL, a retrieval date, and a verbatim
quote** — the same evidence discipline the pipeline already applies to
internal `file:line` citations. Fetched content is explicitly treated as
untrusted input: instructions embedded in a search result or a doc page are
ignored, only factual claims are extracted.

### Fan-out ceiling

No stage dispatches an unbounded number of agents. The cap is **≤8 concurrent,
≤16 total per task loop**; if the real workload exceeds that, the pipeline sorts
by severity, covers the top N, and **must** emit a `SKIPPED: <n> — <reason>`
line. Silent truncation is treated as a bug — a stage that quietly covers 60%
of the findings and reports as if it covered 100% is worse than one that never
ran.

## Provenance & upstream sync

These are **syntheses, not forks** — upstream keeps evolving. Every SKILL.md
records its sources and their versions in frontmatter. Snapshot at synthesis
time (2026-07-14; subagent roster 2026-07-30; discovery-stage prior-art scan and the design lens's visual/routing checks 2026-08-10):

| Upstream | Version | Repo |
|----------|---------|------|
| superpowers | 6.1.1 | [obra/superpowers](https://github.com/obra/superpowers) |
| gstack | 1.60.1.0 | [garrytan/gstack](https://github.com/garrytan/gstack) |
| planning-with-files | 3.5.0 | [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) |
| mattpocock/skills | unversioned monorepo — synced by commit, not tag | [mattpocock/skills](https://github.com/mattpocock/skills) |
| keel-security-review requirements (2026-08-07) | internal doc, not a repo | sources: STRIDE threat modeling, OWASP Top 10:2025, Veracode 2025 GenAI report, slopsquatting research |
| keel-workflow SDD 元素整合需求書 (2026-08-07) | internal doc, not a repo | sources: 外部分享的 SDD/Contract-first/ADR 流程比對 |

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
