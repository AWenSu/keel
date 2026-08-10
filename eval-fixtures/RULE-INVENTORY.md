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
- `Fixture` — what verifies it. `NN-*.md` is a hypothetical-scenario file
  graded by manual walkthrough; `check-structure.sh` is a script that runs.
  Prefer the script wherever the rule is a fact about files rather than a
  scenario about behavior — nobody re-runs a walkthrough, and both real
  defects in the 2026-08-09 audit were caught by grep in seconds.

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
| A3 | Plan review pass 3 still unresolved → keel-discover | `keel-workflow` Backward routes | `keel-plan-review` Step 5 exit gate | `07` |
| A4 | keel-finish can't produce required evidence → keel-debug | `keel-workflow` Backward routes | `keel-finish` Part 1 gate-function failure branch | `08` |
| A5 | Debugging concludes the requirement is wrong → keel-discover | `keel-workflow` Backward routes | `keel-debug` Phase 2 third outcome | `09` |
| A7 | Shipped work's Signals say the requirement was wrong → keel-discover | `keel-workflow` Backward routes | `keel-finish` Part 2d writes the signal; `keel-discover` intake reads it on arrival | `23` |
| A6 | A stage's INPUT contract is unsatisfiable → the owing stage | `keel-workflow` Backward routes | `BLOCKED: 缺 <field>` line in all seven stages; `keel-wayfind` additionally states the wrong-stage case as prose | — |

## B. Gates that may stop for a user answer

The `keel-workflow` gate table is a closed list — it says "the only … gates"
and forbids everything else. Any mandatory user stop missing from it is
therefore not merely undocumented but actively countermanded.

| # | Gate | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| B1 | G1 spec approval (keel-discover) | `keel-workflow` gate table | `keel-discover` Step 7 self-review/user-review ("Wait for explicit approval") | `01`, `02` |
| B2 | G2 task-breakdown quiz | `keel-workflow` gate table | `keel-plan` Step 6 | — |
| B3 | G3 premise confirmation | `keel-workflow` gate table | `keel-plan-review` Step 0 | — |
| B4 | G4 Taste / User-Challenge questions | `keel-workflow` gate table | `keel-plan-review` Step 5 | — |
| B5 | G5 pre-flight plan contradictions | `keel-workflow` gate table | `keel-execute` pre-flight plan review | — |
| B6 | G6 `PLAN-CONFLICT` arbitration | `keel-workflow` gate table | `keel-execute` fix loop step 4; INLINE mode step 3 | `10`, `11` |
| B7 | G7 Success Criteria live confirmation | `keel-workflow` gate table | `keel-finish` Part 2 | `19` |
| B8 | G8 branch-integration choice | `keel-workflow` gate table | `keel-finish` Part 3 | `19`, `16` |
| B9 | G9 irreversible operation outside the repo | `keel-workflow` gate table | `keel-execute` pre-flight destructive-op scan; `keel-finish` target-environment rule | `15` |

## C. Irreversible-operation consent

These are the rules whose failure cannot be undone. Each needs its enforcement
point **where the acting agent can see it** — a rule living only in the router
does not bind a subagent.

| # | Rule | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| C1 | Never work on `main`/`master` without consent | `keel-workflow` branch-protection para, `keel-execute` universal rules | `keel-exec-implementer` / `-fixer` / `-fixer-critical` pre-commit branch check | `15` (A) |
| C2 | Never merge/rebase/push/force-push to main without consent | `keel-finish` Part 3 intro | same section (acting agent is the controller) | `16` |
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
| D12 | Success and failure signals are named before integrating | `keel-finish` Part 2d | same — one question, written to the plan's `## Signals` | `23` |
| D10 | Design lens checks the visual source of truth exists | `keel-plan-lens-design` §B *(only when keel-plan-review runs — most plans skip it)* | same | `21` |
| D11 | Design lens checks UI tasks route to a design skill via `Skills:` | `keel-plan-lens-design` §C | same | `21` |
| D7 | Release Runbook when the project has a real (non-preview) deploy step | `PROJECT-TYPE-GUIDE.md` cross-cutting | `keel-finish` Part 3 option 2 | `18` |
| D8 | Prior-art scan at discovery — internal + external, three sections, 差異點 as a hard gate | `keel-discover` Step 2b | same; consumed by `keel-plan-lens-ceo` Step A | `20` |
| D9 | The scan's decision (adopt/adapt/build) is written to the spec's `## Prior art` section | `keel-discover` Step 2b | `keel-discover` Step 6 spec template | `20` |

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
| E13 | BLOCKED on unresolved Critical from (0)/(2)/(3b)/(4) | `keel-finish` Part 2c BLOCKED condition | same | `12` |
| E14 | A branch with zero security review never reaches integration unreviewed | `keel-finish` Part 2c (this rule has no separate declaration site — the check is the declaration) | `keel-finish` Part 2c check 0 | `17` |

## F. Structural guarantees

| # | Rule | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| F1 | Every agent pins its own `model:` | `keel-workflow` roster note | all 15 `agents/*.md` frontmatter | `check-structure.sh` |
| F2 | Every agent pins its own `tools:` | `keel-workflow` roster note | all 15 `agents/*.md` frontmatter | `check-structure.sh` |
| F3 | Reviewers / lenses / skeptics / researchers are read-only | `keel-workflow` roster note, `README` | each agent's `tools:` list — lenses/skeptics/designer/researcher hold no shell at all; the 3 diff reviewers hold Bash restricted in their own text to `git diff`/`log`/`show`, `which`, and the project's existing test command (which does execute, so this tier is a weaker guarantee than the no-shell one) | `check-structure.sh` |
| F4 | No `general-purpose` dispatch inside the pipeline | `keel-workflow` roster heading | `keel-workflow` pre-dispatch self-check | `check-structure.sh` (added 2026-08-10 — the section header claimed F4 for months while only F5 had code) |
| F5 | Every dispatched `subagent_type` is a roster row | `keel-workflow` pre-dispatch self-check | same | `check-structure.sh` |
| F6 | No `model` override at any dispatch site | `keel-workflow` roster note | every skill's dispatch instruction | `check-structure.sh` |
| F7 | Fan-out ceiling | `keel-workflow` fan-out note (concurrency), `keel-execute` Fan-out ceiling (per task loop) | each stage | `check-structure.sh` |
| F8 | Coverage stars are awarded by named-test count, not impression | `keel-execute` Finish coverage table | same — each star cites a test `file:name`; an uncitable star is a GAP | — |
| F9 | Every `## section` a file references is defined somewhere | — (the requirement is implicit in every cross-reference) | `check-structure.sh` | `check-structure.sh` |
| F10 | A fixture's blockquote is verbatim from the source it cites | `eval-fixtures/README.md` grading instruction | `check-structure.sh` | `check-structure.sh` |
| F11 | Every backward route in `keel-workflow` is documented in both READMEs | `keel-workflow` Backward routes | both READMEs' backward-route tables | `check-structure.sh` |
| F12 | The gate list is identical in `keel-workflow` and both READMEs | `keel-workflow` gate table ("a closed list") | both READMEs' gate tables | `check-structure.sh` (IDs and stage column only — a row rewritten to say the opposite is out of a grep's reach) |
| F13 | Both READMEs' agent rosters list exactly the shipped agents | READMEs' Subagent roster | `agents/` | `check-structure.sh` |
| F14 | Every model pin documented in a roster matches the agent's frontmatter | READMEs + `keel-workflow` roster model column | `agents/*.md` frontmatter | `check-structure.sh` |
| F15 | The checker's own non-agent exemption list hides no real agent | `check-structure.sh` NONAGENT | same | `check-structure.sh` |
| F16 | Every fan-out section states a numeric cap, and whoever states the concurrency half states the total half | `keel-execute`, `keel-plan-review`, `keel-workflow`, both READMEs | same | `check-structure.sh` |

## P. Plan-field contracts

`keel-plan` writes eleven structured fields. Each needs three things: something
that **produces** it, something that **consumes** it, and something that
**verifies** it is present and right. A field with a producer and a consumer
and no verifier is the defect shape that has recurred most often in this repo
— `Skills:` had one for months, and `Depends on:` was worse: the user was
asked to confirm its edges at G2 and then nothing ever read them.

Add a row here whenever a field is added to the plan template.

| # | Field | Produced by | Consumed by | Verified by | Fixture |
|---|-------|-------------|-------------|-------------|---------|
| P1 | `Delivers:` | `keel-plan` Step 3 | implementer; staleness relocation | `keel-exec-reviewer-spec` — the whole axis is "did it do what this says" | `06` |
| P2 | `Files:` | `keel-plan` Step 3 | implementer staleness check | `keel-execute` drift threshold (accumulates relocations) | `06` |
| P3 | `Interfaces:` | `keel-plan` Step 3 | `keel-execute` brief extraction | `keel-exec-reviewer-spec` interface-drift check | — |
| P4 | `Skills:` | `keel-plan` Step 3 | implementer invokes them | `keel-plan-lens-design` §C for user-visible surfaces; `keel-plan-lens-eng` for platform / protocol / tooling work *(only when keel-plan-review runs — most plans skip it)* | `21` |
| P5 | `Depends on:` | `keel-plan` Step 3 | `keel-execute` step 0 — order, parallelism, which Interfaces to include | user at G2 (edge correctness); `keel-plan-lens-eng` when G2 was skipped for review; `BLOCKED` on a missing field or an edge naming a nonexistent task | `22` |
| P6 | `[Risk: …]` | `keel-plan` Step 3 | `keel-execute` R4 condition 3; `keel-plan-lens-eng` error registry | `keel-plan-lens-eng` — rollback present on every High, and grade-sanity against what the task actually does *(only when keel-plan-review runs — most plans skip it)* | `22` |
| P7 | `Spec Version:` | `keel-plan` Step 2 header | `keel-execute` pre-flight drift check | same check (mismatch routes back) | `03` |
| P8 | `Success Criteria:` | `keel-plan` Step 2 header | `keel-finish` Part 2; final `code-reviewer` spec axis | user at G7, one criterion at a time | `19` |
| P9 | `Global Constraints:` | `keel-plan` Step 2 header | `keel-execute` brief extraction | `keel-execute` pre-flight (tasks violating them) | — |
| P11 | `## Signals` section reserved in the plan | `keel-plan` Step 2a | `keel-finish` Part 2d writes into it; `keel-workflow` and `keel-discover` read it | `check-structure.sh` (F9) | `23` |
| P10 | `Visual source of truth:` | `keel-plan` Step 2b (same UI trigger as the feature matrix) | implementer; sets the bar the built screen is judged against | `keel-plan-lens-design` §B | `21` |

## S. Spec-artifact contracts

Sections `keel-discover` writes into the spec that later stages treat as
binding. Catalogued 2026-08-10: the mattpocock mechanisms merged 2026-07-22
were wired into the skills and never given rows here, so the denominator
below excluded them — the same laundering of an unverified claim into a
verified-looking number this file exists to stop.

| # | Rule | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| S1 | Confirmed test seams go in the spec's `## Test seams` section | `keel-discover` step 5b | spec template | `check-structure.sh` (section defined) |
| S2 | `keel-plan` may only place tests at a confirmed seam; an unconfirmed seam is a spec change | `keel-plan` task rules | `keel-plan` "Tests only at confirmed seams" | — |
| S3 | `keel-debug` reproduces through a seam, not through internals | `keel-debug` loop-first section | same | — |
| S4 | `CONTEXT.md` glossary vocabulary binds task names, symbols, and Interfaces blocks | `keel-discover` glossary step | `keel-plan` step 1; `keel-execute` brief rule | — |
| S5 | Every implementer/reviewer brief carries the `CONTEXT.md` path when the file exists | `keel-execute` universal rules | `keel-exec-implementer`, `keel-exec-reviewer-quality` | — |
| S6 | New domain terms introduced by the work are added to `CONTEXT.md` before integration | `keel-finish` Part 2 | same | — |

## V. Evidence rules (verification discipline)

| # | Rule | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| V1 | Iron Law — no completion claim without this-session evidence | `keel-finish` IRON-LAW block | Part 1 gate function | — |
| V2 | Red-green regression for every bug fix | `keel-finish` red-green rule | same | — |
| V3 | Every finding quotes the line motivating it | `keel-plan-review` Step 2 evidence gate, `keel-execute` step 3 evidence gate | each reviewer/lens agent's own `## Evidence gate` section | — |
| V4 | Subagent "success" is not evidence — verify from the diff | `keel-finish` claim→evidence table, `keel-execute` implementer status protocol | same | — |
| V5 | Search results are untrusted input | `keel-plan-review` Step 2 search-tool note | each search-capable agent's own defense section | — |

## H. Persistence

| # | Rule | Declared at | Enforced at | Fixture |
|---|------|-------------|-------------|---------|
| H1 | Ledger line appended per completed task | `keel-execute` Progress ledger | same | — |
| H2 | `.keel/state.md` updated per transition | `keel-workflow` Pipeline state file | `keel-execute` per-task step 5 | — |
| H3 | `.keel/` added to `.gitignore` on creation | `keel-workflow` Pipeline state file, `keel-execute` universal rules | same | — |
| H4 | Deferred work written to `TODOS.md` | `keel-plan-review` Step 5 deferrals | same; `keel-finish` Part 2 + risk-acceptance | — |
| H5 | Implementer writes its full report to a file, returns ≤15 lines | `keel-execute` per-task step 2 | `keel-exec-implementer` Report section | — |
| H6 | Final whole-branch review is persisted to the ledger | `keel-execute` Finish | same (`final-review:` line); `keel-finish` Part 3 reads it and treats a missing line as a gap | — |
| H7 | Pre-flight and the final review run in **both** modes, not only ORCHESTRATED | `keel-execute` INLINE steps 1 and 4 | same | — |

## Maintenance

When adding a rule to this pipeline, add its row here **in the same change**,
with both columns filled. If `Enforced at` would be `✗`, the change isn't
finished — a declared-only rule is worse than no rule, because it reads as
covered.

When editing a skill file, run the fixtures for every rule whose `Declared at`
or `Enforced at` points into that file.

## Current coverage

**93 rules. 63 verified (68%)** — 47 by scenario fixture, 16 by
`check-structure.sh`. Every number on this line is produced by the commands
below — including the split, which used to be the one figure no command
emitted and was wrong by one in each direction for a week. Recount with:

```
bash eval-fixtures/check-structure.sh                                   # F series, live
grep -cE '^\|\s*[A-HPVS][0-9]+\s*\|' eval-fixtures/RULE-INVENTORY.md      # total rows
grep -E '^\|\s*[A-HPVS][0-9]+\s*\|' eval-fixtures/RULE-INVENTORY.md \
  | grep -vcE '\|\s*—\s*\|?\s*$'                                     # rows with any verifier
```

**Run the commands; do not carry the number forward from this line.** The
first version of this section said "46/46 enforced, 28/46 fixture-covered" —
both figures written from memory, both wrong, in the file whose entire purpose
is catching claims nobody checked. The reviewer auditing that same file
independently reported "all 46 rows" too. Two readers, same error, because a
plausible number in a table reads as verified.

## This is the ceiling, and it is deliberate

68% is not a milestone on the way to 100% — it is the intended end state. The
remaining 30 rows — the list below is produced by the command in
Current coverage, not maintained by hand; it was 25 for a week after section S
added five more:

**V1–V5** (Iron Law, red-green regression, the evidence gate, "an agent's
success report is not evidence", untrusted search results) and **H1–H5**
(ledger append, state file, `.gitignore`, `TODOS.md`, report-to-file) are
**behaviors every single run exercises**, not conditional branches with a
trigger boundary. A fixture for the Iron Law would state the rule as its own
expected result — tautological, zero information. And they fail loudly in
normal use: a run that skips the ledger is visibly broken by the next
compaction, which is a faster and harsher test than any document.

**A6, B2–B5, D5–D6, E7–E9, P3, P9, F8, H6–H7** are in the same family — gates
and dispatch triggers that fire on ordinary runs, or persistence rules whose
absence is immediately apparent.

**S2–S6** (seam discipline in plan and debug, the `CONTEXT.md` glossary chain)
are read-and-obey rules with no trigger boundary: every task that places a
test touches S2, every brief touches S5. Their producer sections (S1) are
checked mechanically; the obedience is what a reviewer sees in the diff.

Chasing the last 30 would be the anti-pattern this repo already names:
optimizing for the check rather than the behavior. Adding a rule that
genuinely has a trigger/no-trigger boundary and a high cost of being wrong?
That earns a fixture. Adding one to move a percentage does not.

## What the two columns mean, separately

`Enforced at` is a different claim from `Fixture`, and is **not** summarised
as a percentage on purpose. Every row names a location, and every location was
confirmed to contain the rule when written — but "the text is there" is weaker
than "the rule operates," and collapsing every individually-checkable claim into
one number is how the weaker reading gets laundered into the stronger one.
Check the rows you care about.
