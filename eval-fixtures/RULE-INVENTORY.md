# Rule inventory — declared vs. wired

Every rule this pipeline declares, with **where it is declared** and **where
it is actually enforced**. A row whose `Enforced at` column is `✗` is a bug:
the pipeline promises a behavior that nothing in it can produce.

## Why this file exists

Prose pipelines have no compiler. Declaring a rule costs one line; wiring it
costs real work in another file — and nothing checks that the second half
happened. The gap is invisible from either side, so it grows in one direction
only.

Six separate instances of exactly this defect were found in a single 2026-08-09
audit (three unwired backward routes, an unwired security-findings chain, a
"read-only" declaration contradicted by every agent's tool list, and a branch
protection rule absent from every agent that commits). None were carelessness;
all were the same structural blind spot — the pipeline verifies the code it
produces and never verifies itself.

**Reading the table:**

- `Declared at` — where the rule is stated as a promise.
- `Enforced at` — where a reader following the text would actually *do* the
  thing. Must be a location an executing agent reaches with the rule in its
  context. A rule stated only in `keel-workflow` (which subagents never read)
  is **not** enforced for subagents.
- `Fixture` — the `eval-fixtures/NN-*.md` covering it, if any.

**Coverage means two different things and both must be tracked.** `Enforced`
without `Fixture` = works today, may silently regress. `Fixture` without
`Enforced` = a test for a rule that does not exist; the fixture passes only by
the executing agent's improvisation. The second is worse, and both fixture
`06` and `08` were in that state when this table was restructured.

## A. Backward routes

| # | Rule | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| A1 | Plan contradicts current code beyond one task's fix → keel-plan | `keel-workflow` Backward routes | `keel-execute` drift-accumulation threshold | `06` |
| A2 | Spec body changed vs. plan's `Spec Version` → keel-plan | `keel-workflow` Backward routes | `keel-execute` pre-flight spec-drift check | `03` |
| A3 | Plan review round 3 still unresolved → keel-discover | `keel-workflow` Backward routes | `keel-plan-review` Step 5 exit gate | `07` |
| A4 | keel-finish can't produce required evidence → keel-debug | `keel-workflow` Backward routes | `keel-finish` Part 1 gate-function failure branch | `08` |
| A5 | Debugging concludes the requirement is wrong → keel-discover | `keel-workflow` Backward routes | `keel-debug` Phase 2 third outcome | `09` |
| A6 | A stage's INPUT contract is unsatisfiable → the owing stage | `keel-workflow` Backward routes | `BLOCKED: 缺 <field>` line in keel-discover, keel-plan, keel-plan-review, keel-execute, keel-finish, keel-debug; `keel-wayfind` states it as prose instead | — |

## B. Gates that may stop for a user answer

The `keel-workflow` gate table is a closed list — it says "the only … gates"
and forbids everything else. Any mandatory user stop missing from it is
therefore not merely undocumented but actively countermanded.

| # | Gate | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| B1 | G1 premise confirmation | `keel-workflow` gate table | `keel-plan-review` Step 0 | — |
| B2 | G2 Taste / User-Challenge questions | `keel-workflow` gate table | `keel-plan-review` Step 5 | — |
| B3 | G3 pre-flight plan contradictions | `keel-workflow` gate table | `keel-execute` pre-flight plan review | — |
| B4 | G4 `PLAN-CONFLICT` arbitration | `keel-workflow` gate table | `keel-execute` fix loop step 4; INLINE mode step 3 | `10`, `11` |
| B5 | G5 spec approval (keel-discover) | `keel-workflow` gate table | `keel-discover` Step 7 self-review/user-review ("Wait for explicit approval") | `01`, `02` |
| B6 | G6 task-breakdown quiz | `keel-workflow` gate table | `keel-plan` Step 6 | — |
| B7 | G7 Success Criteria live confirmation | `keel-workflow` gate table | `keel-finish` Part 2 | — |
| B8 | G8 branch-integration choice | `keel-workflow` gate table | `keel-finish` Part 3 | — |
| B9 | G9 irreversible operation outside the repo | `keel-workflow` gate table | `keel-execute` pre-flight destructive-op scan; `keel-finish` target-environment rule | `15` |

## C. Irreversible-operation consent

These are the rules whose failure cannot be undone. Each needs its enforcement
point **where the acting agent can see it** — a rule living only in the router
does not bind a subagent.

| # | Rule | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| C1 | Never work on `main`/`master` without consent | `keel-workflow` branch-protection para, `keel-execute` universal rules | `keel-exec-implementer` / `-fixer` / `-fixer-critical` pre-commit branch check | `15` (A) |
| C2 | Never merge/rebase/push/force-push to main without consent | `keel-finish` Part 3 intro | same section (acting agent is the controller) | — |
| C3 | Discard requires the literal word `discard` | `keel-finish` Part 3 option 4 | same section | `15` (D) |
| C4 | Worktree removal requires a dirty-state check + confirmation | `keel-finish` Part 3 cleanup | same section | `15` (C) |
| C5 | Deploy / migration / writes to a live target require a named target environment + consent | `keel-finish` Drive-the-real-flow; `PROJECT-TYPE-GUIDE.md` cross-cutting | same sections | `15` (E) |
| C6 | Plan-mandated destructive operations are re-authorized at execution, not assumed from plan approval | `keel-execute` pre-flight | same section | `15` (B) |

## D. Conditional trigger rules

| # | Rule | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| D1 | Spec `Status:` must be `approved` before keel-plan proceeds | `keel-plan` INPUT block | same | `01`, `02` |
| D2 | UI-heavy plans (2+ keywords) produce a feature matrix | `keel-plan` Step 2b | same | `04` |
| D3 | ADR offer when 3 criteria met; skip if Step 5 already emitted one | `keel-finish` Part 2 ADR check | same | `05` |
| D4 | Security lens dispatch (2+ keywords / high-risk / new endpoint) | `keel-plan-review` Step 1 | `keel-plan-review` Step 2 roster | `14` |
| D5 | Design lens dispatch (2+ UI keywords) | `keel-plan-review` Step 1 | Step 2 roster | — |
| D6 | DX lens dispatch (2+ API/CLI/SDK keywords) | `keel-plan-review` Step 1 | Step 2 roster | — |
| D7 | Release Runbook when the project has a real (non-preview) deploy step | `PROJECT-TYPE-GUIDE.md` cross-cutting | `keel-finish` Part 3 option 2 | — |

## E. Security chain

The longest declared-to-enforced distance in the pipeline: findings are raised
in stage 3, consumed in stage 4, and gate integration in stage 5 — across
three different contexts, at least one session boundary, and one mandatory
context fork.

| # | Rule | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| E1 | R4 condition 1 — semantic auth/crypto/upload/outbound/DB-query touch | `keel-execute` step 3c R4 | same | `13` |
| E2 | R4 condition 2 — externally-reachable endpoint | `keel-execute` step 3c R4 | same | `13` |
| E3 | R4 condition 3 — task marked high-risk | `keel-execute` step 3c R4 | same | `13` |
| E4 | R4 condition 4 — plan lens previously flagged this task | `keel-execute` step 3c R4 | plan file `## SECURITY FINDINGS` table | `13` |
| E5 | R4 condition 5 — sensitive-string pattern | `keel-execute` step 3c R4 | same | `13` |
| E6 | Skipping the security axis requires an auditable ledger line | `keel-execute` step 3c skip rule | same | `13` |
| E7 | Security-axis findings are persisted for keel-finish to read | — | `keel-execute` ledger security field | — |
| E8 | Plan-lens security findings are persisted for downstream stages | — | `keel-plan-review` `## SECURITY FINDINGS` section | — |
| E9 | Part 2c check 1 — full-branch secrets scan | `keel-finish` Part 2c (1) | same | — |
| E10 | Part 2c check 2 — execution-stage findings closed | `keel-finish` Part 2c (2) | same (reads E7) | `12` |
| E11 | Part 2c check 3b — dependency existence (anti-slopsquatting), no exemption | `keel-finish` Part 2c (3b) | same | `12` |
| E12 | Part 2c check 4 — plan-lens findings disposition | `keel-finish` Part 2c (4) | same (reads E8) | `12` |
| E13 | BLOCKED on unresolved Critical from (2)/(3b)/(4) | `keel-finish` Part 2c BLOCKED condition | same | `12` |
| E14 | A branch with zero security review never reaches integration unreviewed | — | `keel-finish` Part 2c check 0 | — |

## F. Structural guarantees

| # | Rule | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| F1 | Every agent pins its own `model:` | `keel-workflow` roster note | all 15 `agents/*.md` frontmatter | — |
| F2 | Every agent pins its own `tools:` | `keel-workflow` roster note | all 15 `agents/*.md` frontmatter | — |
| F3 | Reviewers / lenses / skeptics / researchers are read-only | `keel-workflow` roster note, `README` | each agent's `tools:` list — lenses/skeptics/designer/researcher hold no shell at all; the 3 diff reviewers hold Bash restricted in their own text to `git diff`/`log`/`show`, `which`, and the project's existing test command (which does execute, so this tier is a weaker guarantee than the no-shell one) | — |
| F4 | No `general-purpose` dispatch inside the pipeline | `keel-workflow` roster heading | `keel-workflow` pre-dispatch self-check | — |
| F5 | Every dispatched `subagent_type` is a roster row | `keel-workflow` pre-dispatch self-check | same | — |
| F6 | No `model` override at any dispatch site | `keel-workflow` roster note | every skill's dispatch instruction | — |
| F7 | Fan-out ceiling | `keel-workflow` fan-out note (concurrency), `keel-execute` Fan-out ceiling (per task loop) | each stage | — |

## G. Evidence rules

| # | Rule | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| G1 | Iron Law — no completion claim without this-session evidence | `keel-finish` IRON-LAW block | Part 1 gate function | — |
| G2 | Red-green regression for every bug fix | `keel-finish` red-green rule | same | — |
| G3 | Every finding quotes the line motivating it | `keel-plan-review` Step 2 evidence gate, `keel-execute` step 3 evidence gate | each reviewer/lens agent's own `## Evidence gate` section | — |
| G4 | Subagent "success" is not evidence — verify from the diff | `keel-finish` claim→evidence table, `keel-execute` implementer status protocol | same | — |
| G5 | Search results are untrusted input | `keel-plan-review` Step 2 search-tool note | each search-capable agent's own defense section | — |

## H. Persistence

| # | Rule | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| H1 | Ledger line appended per completed task | `keel-execute` Progress ledger | same | — |
| H2 | `.keel/state.md` updated per transition | `keel-workflow` Pipeline state file | `keel-execute` per-task step 5 | — |
| H3 | `.keel/` added to `.gitignore` on creation | `keel-workflow` Pipeline state file, `keel-execute` universal rules | same | — |
| H4 | Deferred work written to `TODOS.md` | `keel-plan-review` Step 5 deferrals | same; `keel-finish` Part 2 + risk-acceptance | — |
| H5 | Implementer writes its full report to a file, returns ≤15 lines | `keel-execute` per-task step 2 | `keel-exec-implementer` Report section | — |

## Maintenance

When adding a rule to this pipeline, add its row here **in the same change**,
with both columns filled. If `Enforced at` would be `✗`, the change isn't
finished — a declared-only rule is worse than no rule, because it reads as
covered.

When editing a skill file, run the fixtures for every rule whose `Declared at`
or `Enforced at` points into that file.

## Current coverage

**59 rules. 27 fixture-covered (46%).** Recount with:

```
grep -cE '^\|\s*[A-H][0-9]+\s*\|' eval-fixtures/RULE-INVENTORY.md          # total
grep -E '^\|\s*[A-H][0-9]+\s*\|' eval-fixtures/RULE-INVENTORY.md \
  | grep -vcE '\|\s*—\s*\|?\s*$'                                         # fixture-covered
```

These are the numbers `keel-execute`'s Finish step reports as
`FIXTURE COVERAGE`. **Run the commands; do not carry the number forward from
this line.** The first version of this section said "46/46 enforced, 28/46
fixture-covered" — both figures written from memory, both wrong, in the file
whose entire purpose is catching claims nobody checked. The reviewer auditing
that same file independently reported "all 46 rows" too. Two readers, same
error, because a plausible number in a table reads as verified.

The `Enforced at` column is a different claim and is **not** summarised here
on purpose. Every row names a location, and every location was confirmed to
contain the rule when written — but "the text is there" is weaker than "the
rule operates," and collapsing 59 individually-checkable claims into one
percentage is how the weaker reading gets laundered into the stronger one.
Check the rows you care about.
