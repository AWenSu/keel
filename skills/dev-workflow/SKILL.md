---
name: dev-workflow
description: Software development lifecycle orchestrator — detects the current stage and routes to the matching dev-* pipeline skill (dev-discover → dev-plan → dev-plan-review → dev-execute → dev-finish), with lanes for debugging, UI work, issue-driven work, and heavyweight review. Pure router; contains no duplicated skill content.
argument-hint: "[task description]"
---

# /dev-workflow — Development Lifecycle Router

Routes any development task to the right stage skill. This file contains
routing only — every behavior lives in the routed skill (single source of
truth, no inlined copies to go stale).

## Stage detection → route

| Signal | Stage | Invoke |
|--------|-------|--------|
| "I have an idea / want to build X", requirements fuzzy | DISCOVER | `dev-discover` |
| Spec/requirements exist, multi-step work ahead | PLAN | `dev-plan` |
| Plan exists, large/risky (>8 files, new architecture, production data) | REVIEW | `dev-plan-review` |
| Plan exists and is straightforward, or reviewed plan ready | EXECUTE | `dev-execute` |
| Implementation done, wrapping up / about to claim done / PR time | FINISH | `dev-finish` |
| Idea too big for one session AND the route is still foggy | WAYFIND | `dev-wayfind` (decision map; exits to dev-discover once clear) |
| Bug, test failure, unexpected behavior | DEBUG | `dev-debug` (loop-first: no hypothesis without a red repro command) |
| Frontend/UI task | UI | `frontend-workflow` (own router; don't mix pipelines) |
| Output should be a GitHub issue / backlog item | ISSUE | gstack `spec` |
| Very large plan (>15 files, new product surface) needing dual-model review | HEAVY REVIEW | gstack `/autoplan` instead of dev-plan-review |
| Multiple independent failures / parallelizable work | PARALLEL | `superpowers:dispatching-parallel-agents` |
| Need isolated workspace for risky work | INFRA | `superpowers:using-git-worktrees` |

### Backward routes (a stage may send work back)

| Trigger | From | Back to |
|---------|------|---------|
| Execution finds the plan contradicts the code as it now is (beyond one task's fix) | dev-execute | `dev-plan` |
| Spec body changed during execution and no longer matches plan's recorded Spec Version | dev-execute | `dev-plan` |
| Plan review round 3 still has unresolved decisions — the plan is fighting the spec | dev-plan-review | `dev-discover` |
| dev-finish gate cannot produce the evidence a claim requires | dev-finish | `dev-debug` |
| Debugging concludes the requirement itself is wrong | dev-debug | `dev-discover` |
| A stage's INPUT contract is unsatisfiable (see below) | any | the stage that owes the missing artifact |

## Stage contracts

Every stage skill declares an **INPUT** block (what must exist before it may
start) and an **OUTPUT** block (what it guarantees on completion). Check INPUT
on entry and OUTPUT before announcing completion. On a miss, emit one line and
take the backward route — do not proceed on a partial artifact:

```
BLOCKED: 缺 <artifact/field> → 退回 <stage>
```

Contract violations that surface mid-execution are the most expensive class of
failure in this pipeline; checking on entry is nearly free.

## Size shortcut (before routing at all)

- **Small** (single file, reversible, <30 min): skip the pipeline. Do it,
  then run the dev-finish gate function on your claim. Planning cost must
  stay under ~20% of the task.
  **Exception — the shortcut does not cover security.** A single-file change
  to an authentication/authorization/session, encryption, file-upload,
  outbound-call, or database-query-construction path, or one that adds an
  externally-reachable endpoint, additionally runs `dev-finish` Part 2c
  before it is done. "Reversible in git" and "safe to ship unreviewed" are
  different properties; one file is exactly the size most auth bugs are.
- **Medium** (multi-file, half a day): `planner` agent one-shot plan →
  execute → dev-finish. It must also carry a header **Success Criteria**
  list: `dev-finish` Part 2 opens that checklist unconditionally, and a plan
  without one arrives at the final gate with nothing to check. (`Spec
  Version` is genuinely exempt on this path — there is no spec file — and
  that exemption is stated, not an oversight.) **Plus the four fields
  dev-execute consumes** — `Delivers:`, `Files:`, `Interfaces:`, `Skills:` —
  so say so in the planner dispatch. Without them, dev-execute's brief
  extraction, staleness check, and spec-axis review all fail silently. Any
  field missing on return → do not enter dev-execute; go through `dev-plan`.
- **Large / high-risk**: full pipeline, stages 1–5.

## Cross-cutting layers (invoke, don't restate)

- **Coding philosophy**: `andrej-karpathy-skills:karpathy-guidelines` —
  invoke when writing/reviewing code.
- **Persistence**: `planning-with-files` — its hooks run automatically when
  installed; comply with its plan/findings/progress files, don't duplicate.
- **High-risk overlay**: `doubt-driven-development` — layer on any stage for
  production / security / irreversible operations.

## Subagent roster — never dispatch as `general-purpose`

Every pipeline dispatch names a purpose-built `subagent_type`. The type name
IS the progress display: reading it tells you which stage is running and who
is working. A `general-purpose` dispatch inside this pipeline is a bug.

| subagent_type | Stage | Role | model |
|---------------|-------|------|-------|
| `dev-discover-designer` | 1 discover | Parallel approach proposals | sonnet |
| `dev-plan-lens-ceo` | 3 review | Should this exist + prior-art scan | opus |
| `dev-plan-lens-design` | 3 review | User-visible states (conditional) | sonnet |
| `dev-plan-lens-eng` | 3 review | Buildable as written + API currency | sonnet |
| `dev-plan-lens-security` | 3 review | STRIDE threat modeling (design-time, conditional) | opus |
| `dev-plan-lens-dx` | 3 review | Developer onboarding cost (conditional) | sonnet |
| `dev-plan-skeptic` | 3 review | Refute one High finding — single-point check | sonnet |
| `dev-plan-skeptic-critical` | 3 review | Refute one Critical / security / cross-file finding | opus |
| `dev-exec-implementer` | 4 execute | Build one task | sonnet |
| `dev-exec-reviewer-spec` | 4 execute | Spec-compliance axis | sonnet |
| `dev-exec-reviewer-quality` | 4 execute | Code-quality axis | sonnet |
| `dev-exec-reviewer-security` | 4 execute | Security review axis (R4 conditional trigger) | opus |
| `dev-exec-fixer` | 4 execute | Apply review findings | sonnet |
| `dev-exec-fixer-critical` | 4 execute | Fix-loop round 4-5 — standard tier stalled | opus |
| `dev-wayfind-researcher` | pre | Resolve one research ticket | sonnet |

**External agents — shipped elsewhere, not in this repo's `agents/`.** Still
valid `subagent_type` values for the pre-dispatch check below, but their
model and tools are whatever the local installation defines; this table
cannot pin them.

| subagent_type | Stage | Role | model |
|---------------|-------|------|-------|
| `planner` | 2 plan | Medium-task one-shot plan (must return Delivers/Files/Interfaces/Skills) | — (external) |
| `code-reviewer` | 4 execute | Final whole-branch review | — (external; inherits strongest) |
| `security-auditor` | ad-hoc | `/security-review`／`/ship` only — not dispatched by dev-plan-review/dev-execute | — (external) |
| `test-engineer` | 3 review | Test-strategy findings | — (external) |
| `silent-failure-hunter` | 3 review | Swallowed-error audit | — (external) |
| `build-error-resolver` | debug | Compile/build failures — dispatched by `dev-debug` when the symptom is a build/compile error | — (external) |

Each agent file pins its own `tools:` and `model:`. **Do not pass a `model`
override** — the pin is the decision, and overriding it re-introduces the
silent-inheritance bug it exists to prevent.

**Read-only is enforced by the tool list, not by prose.** Lenses, skeptics,
the designer, and the researcher hold `Read, Grep, Glob` (plus search tools
where their job needs them) — no shell, so "read-only" is a property of the
grant rather than a promise. The three `dev-exec-reviewer-*` agents
additionally hold `Bash`, because reviewing a diff requires `git diff`; each
one's definition restricts that shell to read-only commands in its own text,
which is a weaker guarantee and is the reason the grant stops there. Only
implementers and fixers hold `Edit`/`Write`.

**Fan-out ceiling:** ≤8 concurrent, everywhere. Total-agent budgets belong to
each stage, not to this table — dev-execute's is ≤16 per *task loop*
(`dev-execute` Fan-out ceiling), dev-plan-review's is ≤8 skeptics per round
(`dev-plan-review` Step 4). Over a ceiling, sort by severity, take the top N,
and emit `SKIPPED: <n> — <id + reason>`. Silent truncation reads as full
coverage when it isn't.

**Pre-dispatch self-check (mandatory, every dispatch).** Naming the rule above
is not enough on its own — a `general-purpose` dispatch can still slip through
under context pressure since nothing forces the tool call's `subagent_type`
field to match. Immediately before every Task/Agent tool call in this
pipeline, state the intended `subagent_type` on its own line, copied verbatim
from the roster table, e.g.:

```
派工: dev-exec-reviewer-spec（規格軸，stage 4）
```

Then make the call with that exact string. If the string you're about to
state isn't a row in the roster table above, stop — the roster is missing a
role (report `BLOCKED: roster 缺 <role>` and ask before improvising) or the
task doesn't belong in this pipeline. Never silently fall back to
`general-purpose` to avoid stopping.

## Progress broadcast (mandatory)

Every subagent return is announced **immediately** — never batched to the end
of a stage, never summarized away. The controller writes this block; the
subagent returns structured data.

```
◆ <subagent_type>  ▸ <target>
  <verdict / score>
  最重要: <the single most important finding, with file:line or URL>
  下一步: <what the controller does now>
```

And at each stage entry:

```
▶ 階段：<name> (<skill>)
  將派出：<subagent_type list, in order; note which conditional lenses were skipped and why>
```

Rules: a broadcast must contain one quotable anchor (`file:line` or URL) — "found
some issues" is not a broadcast. A score never appears without its evidence.

## Pipeline state file

Maintain `.dev-pipeline/state.md`, overwritten on every stage transition and
every task completion. The ledger records what finished; this records where you
are:

```
專案：<name>          分支：<branch>
階段：<stage> (<n>/5)
Task：<done>/<total> 完成，T<n> <status>
未決問題：<count>
已延後：<count>（見 TODOS.md）
最後更新：<timestamp>
```

Add `.dev-pipeline/` to the repo's `.gitignore` on first creation.

## Protocol

1. Detect stage. Output one line: `STAGE: <x> → SKILL: <y>`. If ambiguous,
   ask ONE question.
2. Check the stage's INPUT contract. Unsatisfiable → `BLOCKED:` line + backward
   route.
3. Invoke the routed skill with full task context — do not summarize.
4. When a stage completes, verify its OUTPUT contract, announce the next stage,
   and continue **without asking permission.**

**The gates that may stop the pipeline for a user answer:**

| Gate | Where | What |
|------|-------|------|
| G1 | dev-plan-review Step 0 | Premise confirmation — the one always-asked question |
| G2 | dev-plan-review Step 5 | Each surviving Taste / User Challenge, asked one finding per question, batched by dependency frontier (never all at once, never forced serial past the frontier) |
| G3 | dev-execute pre-flight | Batched plan-contradiction questions before Task 1 |
| G4 | dev-execute per-task review | `PLAN-CONFLICT` finding arbitration |
| G5 | dev-discover | Spec approval — no code before the user approves; no exceptions for "simple" projects |
| G6 | dev-plan Step 6 | Task-breakdown granularity and `Depends on` edges (skipped only when the plan is heading into dev-plan-review anyway) |
| G7 | dev-finish Part 2 | Each Success Criterion, confirmed on the spot by the user — the agent's own assessment never closes a box |
| G8 | dev-finish Part 3 | Branch-integration choice, and the typed `discard` confirmation if that option is taken |
| G9 | any stage | An irreversible operation outside the repo — deploy, migration against a non-ephemeral database, data deletion, external publication, credential rotation, push/merge to a protected branch. Named target + exact command, asked at the point of action, **even when the plan already specifies it** |

A "should I continue?" that is **not one of the rows above** is forbidden —
generic checkpoint questions burn the user's time and are not a safety
mechanism. The distinction matters: G5–G9 are not checkpoints, they are the
points where proceeding without an answer would either skip a hard gate or
do something that cannot be undone. Treating the table as shorter than it is
does not make the pipeline faster; it makes it unsafe in exactly the places
speed is worth the least.

**Never work on `main`/`master` without explicit user consent** — branch first.
This binds every stage that writes, dev-execute and dev-finish alike; neither
redefines it locally. Because subagents never read this file, the agents that
actually commit (`dev-exec-implementer`, `dev-exec-fixer`,
`dev-exec-fixer-critical`) carry their own pre-commit branch check — a rule
stated only here would not reach the process performing the action.

**Smart-zone rule (from mattpocock ask-matt/handoff):** past ~120k tokens of
context, reasoning degrades. If a long conversational stage (discover, plan)
approaches that before finishing — don't push on degraded, and don't compact
mid-stage (it severs the thinking the stage builds on). Instead write a
handoff file and fork to a fresh session: save it OUTSIDE the repo (temp
dir), reference existing artifacts by path instead of re-quoting them,
include the stage, decisions so far, and next action, and redact secrets.
dev-execute's ledger covers crash recovery; this rule covers voluntary
handoff before quality drops. Execution subagents are exempt — each starts with
a fresh context.

**The execution controller is not exempt.** Before entering dev-execute's
ORCHESTRATED mode, check your own context: past ~100k, write the handoff and
fork first. The controller keeps accumulating (ledger reads, report summaries,
G4 arbitration) and will hit mid-stage compaction — which is precisely the
failure the ledger exists to survive, not one to walk into deliberately.

## Project-type presets

See PROJECT-TYPE-GUIDE.md in the unified-dev-skills repo
(github.com/AWenSu/unified-dev-skills) for per-project-type stage defaults
and domain-skill layering.
