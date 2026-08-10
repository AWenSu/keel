# Eval fixtures

Regression checks for the pipeline's prompt/skill-rule changes — no
compiler or test runner exists for markdown skill definitions, so each
fixture is a hypothetical scenario plus the exact rule text it should
trigger, graded by manual walkthrough (same substitute the
2026-08-07 SDD-integration plan used for its own verification).

## Two kinds of check

**`check-structure.sh` — run it.** Mechanical facts about files (does every
agent pin a model and a tool list? is any read-only agent holding write tools?
does every dispatched name resolve to a definition?) are verified by script,
not by prose. One second, exact filenames on failure. Both real defects in the
2026-08-09 audit were of this kind.

```
bash eval-fixtures/check-structure.sh     # exit 0 = all pass
```

The last check compares this repo against a `~/.claude` install and is
skipped when there isn't one — so a fresh clone reports one check fewer
than a maintainer's run. That is not a regression.

**`NN-*.md` — walk them.** Scenario fixtures pin trigger/no-trigger boundaries
that no script can judge ("does a spec marked draft block `keel-plan`?"). These
need a human or an agent reading the rule text against the scenario.

## How to run the scenario fixtures

For each fixture:

1. Read `Scenario` — the hypothetical INPUT/state.
2. Open the cited `Rule source` file:line.
3. Walk the rule's text against the scenario exactly as an agent following
   it would — no interpretation beyond what the text says.
4. Compare the result to `Expected`. Record PASS/FAIL with the actual
   quoted output.

Run this set whenever a skill file in the table below changes. A FAIL means
the edit broke a previously-working rule — fix before continuing, don't
proceed with a known regression.

## Fixture index

| Fixture | Rule under test | Skill file |
|---------|-----------------|------------|
| `01-spec-status-draft-blocks.md` | spec approval gate | `keel-plan/SKILL.md` |
| `02-spec-status-approved-passes.md` | spec approval gate | `keel-plan/SKILL.md` |
| `03-spec-version-drift-routes-back.md` | spec drift check | `keel-execute/SKILL.md` |
| `04-feature-matrix-trigger.md` | UI-heavy feature matrix | `keel-plan/SKILL.md` |
| `05-adr-offer-trigger.md` | ADR offer criteria | `keel-finish/SKILL.md` |
| `06-plan-contradicts-code-routes-back.md` | backward route: plan vs. code | `keel-workflow/SKILL.md` |
| `07-review-round-3-unresolved-routes-to-discover.md` | backward route: round-3 unresolved | `keel-plan-review/SKILL.md` |
| `08-finish-evidence-gap-routes-to-debug.md` | backward route: evidence gap | `keel-finish/SKILL.md` |
| `09-debug-wrong-requirement-routes-to-discover.md` | backward route: wrong requirement | `keel-workflow/SKILL.md` |
| `10-plan-conflict-gate-orchestrated.md` | PLAN-CONFLICT gate (G6), ORCHESTRATED | `keel-execute/SKILL.md` |
| `11-plan-conflict-gate-inline.md` | PLAN-CONFLICT gate (G6), INLINE | `keel-execute/SKILL.md` |
| `12-security-exit-gate-blocked.md` | Part 2c BLOCKED condition | `keel-finish/SKILL.md` |
| `13-r4-security-axis-triggers.md` | R4 conditions (5 sub-scenarios) | `keel-execute/SKILL.md` |
| `14-security-lens-dispatch-trigger.md` | Security lens dispatch (OR of 3 conditions) | `keel-plan-review/SKILL.md` |
| `15-irreversible-operation-consent.md` | Consent guards for unrecoverable actions (5 sub-scenarios) | `keel-workflow`, `keel-execute`, `keel-finish`, the 3 write-capable agents |
| `16-merge-push-consent.md` | merge / push / force-push need explicit consent (G8) | `keel-finish` Part 3 |
| `17-branch-level-security-coverage.md` | A branch with zero security review (Part 2c check 0) | `keel-finish` Part 2c |
| `18-release-runbook-criterion.md` | Release Runbook fires on the deploy, not the platform | `PROJECT-TYPE-GUIDE.md`, `keel-finish` |
| `19-finish-user-confirmations.md` | Per-criterion confirmation and integration choice (G7/G8) | `keel-finish` Part 2 / Part 3 |
| `20-prior-art-scan-at-discovery.md` | Prior-art scan at discovery; build vs adopt as a decision | `keel-discover` Step 2b |
| `21-design-lens-visual-routing.md` | Visual source of truth + design-skill routing on UI tasks | `keel-plan-lens-design` |
| `22-plan-field-contracts.md` | `Depends on:` consumption; rollback + risk-grade verification | `keel-execute`, `keel-plan-lens-eng` |

Adding a rule that is a **fact about files**? Add a check to
`check-structure.sh`, not a fixture — a test nobody runs is worse than no test,
because the inventory then reads as covered.

Adding a rule with a clear trigger/no-trigger boundary?
Add a fixture here in the same format — that boundary is exactly what
silently breaks first when unrelated wording nearby gets edited. Then add a
row to `RULE-INVENTORY.md`, which tracks every declared rule (covered or
not) as the denominator for the `FIXTURE COVERAGE: N/M` line `keel-execute`'s
Finish step reports whenever a plan edits this repo's own skill files.
