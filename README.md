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
                (pass 3 still unresolved)    (contradicts plan)   (evidence can't be produced)
        ▲
        └──────────────────────────────────────────── post-merge Signals came back negative
                                                      (the requirement was wrong, not the code)
```

`keel-workflow` sits above the five stages as the router: it detects which
stage a request belongs to, dispatches the matching skill, and — the part most
routers skip — sends work **backward** when a later stage finds that an
earlier one got something wrong.

## What you get

- **One obvious path.** One skill per stage instead of four overlapping ways
  to "make a plan". Small tasks skip straight to building; only large or risky
  plans go through review.
- **Stops only where it matters.** Nine named gates are the only points that
  wait for your answer. Questions a quick check could answer are checked, not
  asked.
- **"Done" means shown working.** Every claim needs fresh evidence, and the
  critical flows named at the start are driven end to end through a
  verification harness committed to the repo — not an agent's say-so.
- **Reviews that can't rubber-stamp.** Each task gets two or three independent
  reviewers who never see each other's verdict, and high-severity plan findings
  must survive a skeptic whose job is to kill them.
- **It gets better per project.** Lessons are pushed into the code or a lint
  rule first, a project rulebook second, and the next plan reads them.

## Install

Copy `skills/` and `agents/` into a location Claude Code loads them from:

```bash
# per-project
cp -R skills/* your-repo/.claude/skills/
cp -R agents/* your-repo/.claude/agents/

# or global
cp -R skills/* ~/.claude/skills/
cp -R agents/* ~/.claude/agents/
```

`agents/` is optional but strongly recommended — without it every subagent
dispatch silently falls back to Claude Code's generic `general-purpose` agent:
no pinned model, no restricted tool access, no name in the progress display.

Restart Claude Code once (new skill/agent directories are picked up at session
start). No build step, no hooks, no packages.

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

# or just describe the task and let the router pick the stage
/keel-workflow add OAuth login to the admin panel
```

Each stage announces its successor and hands off. Every subagent result is
broadcast by the agent's name the moment it lands, so you are never staring at
a silent pipeline wondering what four agents are doing.

## The five stages

| # | Skill | Turns | Guarantees |
|---|-------|-------|------------|
| 1 | [`keel-discover`](skills/keel-discover/SKILL.md) | a vague idea → an approved spec | No code before you approve the spec. Grounded in `path:line` evidence before any question; a prior-art scan inside and outside the repo; one to three **critical flows** named here, each crossing a real integration boundary. |
| 2 | [`keel-plan`](skills/keel-plan/SKILL.md) | the spec → a plan a zero-context engineer could execute | No placeholders. Each task names what it delivers, its files, interfaces, and the domain skills to invoke. Critical flows get an executable `Drive` command through a committed harness — built as the first task when the repo has none. |
| 3 | [`keel-plan-review`](skills/keel-plan-review/SKILL.md) | a rough plan → a reviewed plan | CEO, Eng, and conditional Design, Security, DX lenses. Routine findings are auto-decided; judgment calls come to you, batched by dependency; empirical ones are settled by a throwaway check first. |
| 4 | [`keel-execute`](skills/keel-execute/SKILL.md) | the plan → working code | Test-first implementer per task; spec and quality reviewers (plus security when triggered), never merged into one verdict; a crash-safe progress ledger; inline fallback without subagents. |
| 5 | [`keel-finish`](skills/keel-finish/SKILL.md) | "looks done" → integrated | Fresh evidence for every claim, every critical flow driven, Success Criteria confirmed by you, open items reconciled, lessons promoted, then the branch integrated your way. |

**Side lanes**, entered only when they fit:

| Skill | When |
|-------|------|
| [`keel-wayfind`](skills/keel-wayfind/SKILL.md) | The work is too big for one session and the route is still foggy — chart a map of decision tickets and resolve them one per session. |
| [`keel-debug`](skills/keel-debug/SKILL.md) | Something is broken and the cause is unknown — no hypothesis before a red reproduction command. |
| [`keel-audit`](skills/keel-audit/SKILL.md) | You explicitly ask for a whole-codebase security audit. Cloudflare's security-audit method vendored verbatim (MIT), run source-only with a coverage ledger and one fresh verifier per candidate. Never started by the main flow. |

Which stages and lenses to use for web apps, APIs, CLIs, MCP servers,
serverless, docs repos, and scrapers is in
**[PROJECT-TYPE-GUIDE.md](PROJECT-TYPE-GUIDE.md)**.

## Where it stops for you

### The gates — the only points that wait for your answer

Everything else proceeds without asking. These never do:

<!-- generated:gates — structure from tables/gates.tsv; run tables/render.sh after editing -->
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
<!-- /generated:gates -->

The list is closed in both directions: a generic "shall I continue?" that is
not one of these rows is forbidden. G4 asks every question whose prerequisites
are already settled in one call (up to four), applies the answers, then
computes the next batch — dependency decides the batches, never convenience.

### Backward routes — when a later stage finds an earlier mistake

<!-- generated:routes — structure from tables/routes.tsv; run tables/render.sh after editing -->
| Trigger | From | Back to |
|---------|------|---------|
| Execution finds the plan contradicts the code as it now stands (beyond one task's fix) | `keel-execute` | `keel-plan` |
| The plan's `Spec Version` doesn't match the current spec | `keel-execute` | `keel-plan` |
| Plan review pass 3 still has unresolved decisions — the plan is fighting the spec | `keel-plan-review` | `keel-discover` |
| `keel-finish`'s evidence gate can't produce proof for a claim | `keel-finish` | `keel-debug` |
| Debugging concludes the requirement itself is wrong | `keel-debug` | `keel-discover` |
| Shipped work's `## Signals` say it did not work — the requirement was wrong, not the code | post-merge reality | `keel-discover` |
| A stage's INPUT contract cannot be satisfied | any stage | the stage that owes the missing artifact |
<!-- /generated:routes -->

## How it keeps the work honest

- **Evidence over reports.** A subagent's "success", a stale test run, and
  "should work" are not evidence; a diff and fresh command output are.
- **Critical flows, driven early.** Flows are named at discovery, turned into
  commands at planning, and driven at the first task after which they can run.
  The command goes through a committed **runner** — one command that launches
  the product in a known state and saves the evidence — and a **feature map**
  listing how to reach each feature, so a vague bug report becomes a place the
  runner can go.
- **Independent review axes.** Spec compliance and code quality are graded
  separately, by reviewers who read the tests before the implementation and
  must name the failure, not just the line. PASS means the diff improves code
  health; it does not mean perfect.
- **Comments need a reason.** A comment the diff adds survives only for a
  license header, behaviour forced by something the repo cannot change, a
  public API contract, a link to an issue or spec, or a non-obvious algorithm.
  A comment that excuses a workaround is graded as the unfixed workaround, and
  a constraint that lives only in a comment must become a type, a test, or a
  lint rule.
- **Gates are sacred, artifacts can shrink.** Under time pressure the spec gets
  shorter; approval is never skipped.

## How it learns

Agents copy the patterns they read, so the codebase is their memory. keel
treats every correction as a question of where to put it:

1. **Code a wrong version cannot be written in** — a type, a structure, an API
   shape.
2. **A check that fails** — a linter, compiler setting, or CI step.
3. **A rule in the project rulebook** — read by the next plan's briefs.
4. **A human remembering in review** — the weakest place, used last.

At `keel-finish`, lessons from `.keel/findings.md` are promoted down that
list, and only what neither code nor a check can enforce becomes a rule.
A pattern the reviewers caught is searched for across the repo: copies found
elsewhere are reported with a proposal to stop the spread first and clean up
second. Deferred work goes to the project backlog with a link the next stage
can resolve. Rulebooks come in two scopes: a local one for "how this line is
written here", and a cross-project one for patterns that change how you
design.

## Subagent roster

Every dispatch names a specific `subagent_type` — never the generic
`general-purpose`. The prefix tells you the stage, the tail the role, and each
agent's frontmatter pins its model and locks its tools, so a decision cannot
quietly drift the way a prose reminder ("remember to use opus here") does.

**Read-only by tool grant, not by prose.** Lenses, skeptics, the designer, the
researcher, and both audit agents hold `Read, Grep, Glob` (plus named search
tools) and no shell at all. The three `keel-exec-reviewer-*` agents also hold
`Bash`, because reviewing a diff needs `git diff`; each restricts it in its own
definition, a weaker guarantee and the reason the grant goes no further. Only
implementers and fixers can edit.

<!-- generated:roster — structure from tables/agents.tsv; run tables/render.sh after editing -->
| subagent_type | Stage | Role | model | Tools |
|---|---|---|---|---|
| `keel-discover-designer` | 1 discover | One of 3 parallel approach proposals, each under a different constraint | sonnet | read-only |
| `keel-plan-lens-ceo` | 3 review | Should this exist at all — plus a mandatory prior-art web scan | **opus** | read-only + tavily, exa, context7 |
| `keel-plan-lens-design` | 3 review | Every user-visible state named (conditional: UI-heavy plans) | sonnet | read-only |
| `keel-plan-lens-eng` | 3 review | Buildable as written — plus an API-currency check against live docs | sonnet | read-only + context7, Ref |
| `keel-plan-lens-security` | 3 review | Design-time STRIDE threat modeling (conditional: 2+ security keywords, high-risk marker, or new external endpoint) | **opus** | read-only |
| `keel-plan-lens-dx` | 3 review | Developer onboarding cost (conditional: API/CLI/SDK-facing plans) | sonnet | read-only + context7 |
| `keel-plan-skeptic` | 3 review | Refute one High finding — single-point evidence check | sonnet | read-only, **no search** |
| `keel-plan-skeptic-critical` | 3 review | Refute one Critical / security / cross-file-reasoning finding | **opus** | read-only, **no search** |
| `keel-exec-implementer` | 4 execute | Build one task, test-first enforced | sonnet | full |
| `keel-exec-reviewer-spec` | 4 execute | Spec-compliance axis only | sonnet | read-only + shell restricted to `git diff`/`log`/`show`, `which`, tests |
| `keel-exec-reviewer-quality` | 4 execute | Code-quality axis only | sonnet | read-only + shell restricted to `git diff`/`log`/`show`, `which`, tests |
| `keel-exec-reviewer-security` | 4 execute | Security axis only, dispatched conditionally when an R4 trigger is hit | **opus** | read-only + shell restricted to `git diff`/`log`/`show`, `which`, tests |
| `keel-exec-fixer` | 4 execute | Apply only the findings it was given | sonnet | full |
| `keel-exec-fixer-critical` | 4 execute | Fix-loop rounds 4-5 only, after the standard tier stalls twice | **opus** | full |
| `keel-wayfind-researcher` | pre-stage | Resolve one externally-answerable research ticket | sonnet | read-only + full search |
| `keel-audit-hunter` | side lane | Whole-codebase audit: reconnaissance, one coverage unit per hunter, and coverage-critic passes — source only | sonnet | read-only, **no shell** |
| `keel-audit-verifier` | side lane | One fresh verifier per audit candidate: confirmed, needs_validation (no severity), or rejected | **opus** | read-only, **no shell** |
| `keel-auditor` | meta | Attacks this repo's own checks by mutation — looks for a defect class nobody has encoded | **opus** | read-only + a shell restricted to running the checkers; mutations only in a throwaway copy, never commits |
<!-- /generated:roster -->

Also dispatched by name but not shipped here, so their model and tools are
whatever your install defines: `planner`, `code-reviewer` (the final
whole-branch review, deliberately with no model override so it inherits the
strongest model in the session), `test-engineer`, `silent-failure-hunter`,
and `build-error-resolver`. `security-auditor` is an ad-hoc specialist that
the pipeline never dispatches; its own security coverage lives in
`keel-plan-lens-security` and `keel-exec-reviewer-security`.

**Tiering is agent selection, not a model parameter.** A cheaper skeptic is a
different agent (`keel-plan-skeptic`), not a `model` override on the same one:
the tier then shows in the progress display and cannot be forgotten under time
pressure. The standard tier returns `ESCALATE` rather than guessing past its
depth, and when unsure, findings go to the critical tier — wrongly killing a
real Critical costs a production defect, wrongly sparing a weak one costs one
fix round. The fix loop works the same way: rounds 1–3 use `keel-exec-fixer`,
rounds 4–5 a fresh `keel-exec-fixer-critical`, and round 5 trips a circuit
breaker.

**Prior art before building.** The CEO lens searches for existing products,
known dead ends, and a concrete difference that justifies building anyway; a
match with no named difference cannot sink a plan. The Eng lens checks every
named API against current docs. Every external finding needs a URL, a date,
and a verbatim quote, and fetched pages are untrusted input.

### Fan-out ceiling

No stage dispatches an unbounded number of agents. Over the cap, the pipeline
sorts by severity, covers the top N, and **must** print a
`SKIPPED: <n> — <reason>` line — a stage that quietly covers 60% and reports
100% is worse than one that never ran.

Fan-out ceiling: ≤8 concurrent, ≤16 total per task loop.

## Testing keel itself

There is no compiler for prompts, so [`eval-fixtures/`](eval-fixtures/) checks
keel against itself:

```bash
bash eval-fixtures/check-structure.sh    # facts about the files; exit 0 = all pass
bash eval-fixtures/run-mutations.sh      # proves every check above can fail
bash tables/render.sh                    # regenerates the three shared tables
```

- `check-structure.sh` verifies what a script can: every agent pins a model and
  a tool list, no read-only agent holds write tools, every dispatched name
  resolves, fixtures quote their rule source verbatim, the installed copy
  matches the repo.
- `run-mutations.sh` injects every defect past audits found, one at a time in a
  throwaway copy, and asserts the named check goes red. A check no mutation has
  ever tested fails the run.
- **Rules stated in more than one file have one source** in [`rules/`](rules/),
  compared by bytes. Paraphrasing one copy is a build failure.
- **The roster, gate, and route tables are generated** from
  [`tables/`](tables/) into every document that carries them.
- `NN-*.md` scenario fixtures cover boundaries no script can judge, and
  `RULE-INVENTORY.md` lists every declared rule with where it is enforced and
  what verifies it — deliberately without a coverage percentage.

Counts are left out of this README on purpose; the checker prints them on every
run, and hardcoded numbers went stale twice.

## Provenance & upstream sync

These are **syntheses, not forks**. Every `SKILL.md` records its sources and
versions in its frontmatter.

| Upstream | Version | What it contributed |
|----------|---------|---------------------|
| [obra/superpowers](https://github.com/obra/superpowers) | 6.1.1 | Stage spines: brainstorming, writing-plans, subagent-driven development, verification-before-completion |
| [garrytan/gstack](https://github.com/garrytan/gstack) | 1.60.1.0 | autoplan's decision taxonomy, review lenses, evidence gate |
| [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files) | 3.5.0 | Filesystem as memory, the progress ledger |
| [mattpocock/skills](https://github.com/mattpocock/skills) | unversioned, synced by commit | Vertical-slice tickets, batched grilling, design-it-twice, glossary discipline |
| [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) | `c1c8a8c` | The whole `keel-audit` method, vendored verbatim under MIT |
| Lauren Tan, Cursor Compile 2026 talk and [pstack](https://github.com/cursor/plugins/tree/main/pstack) | 2026-10 | Comment rules, enforcement before rules, the verification harness, observe instead of asking, the spread check |
| keel-security-review requirements (2026-08-07) | internal doc | STRIDE, OWASP Top 10:2025, Veracode 2025 GenAI report, slopsquatting research |

To sync: check upstream releases against the versions above, port
**mechanism** changes (new gates, new protocols) into the affected skill, and
bump its frontmatter version. Prose rewrites, and fixes to machinery dropped
here (Codex hooks, telemetry, mockup boards), don't apply. For very large
plans (>15 files) where gstack is installed, its `/autoplan` earns its extra
machinery.

## Design rules

- **Distill, don't concatenate** — a mechanism gets in by being load-bearing,
  not by existing.
- **Gates are sacred, artifacts can shrink** — write a smaller spec; never skip
  approval.
- **Evidence over reports** — diffs and fresh command output, not "should
  work".
- **Filesystem over context window** — anything that must survive compaction
  goes in a file.
- **Structure over prose** — if a rule matters, encode it in an agent's
  frontmatter, a type, or a check, not in a sentence hoping to be remembered.

## Contributing

Issues and PRs are welcome — especially upstream mechanism changes not yet
ported, or a stage, gate, or agent that did not earn its keep in real use. A
contribution should distill, not add a second way to do something the pipeline
already does once.

## License

[MIT](LICENSE)
