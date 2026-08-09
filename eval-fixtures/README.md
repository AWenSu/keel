# Eval fixtures

Regression checks for the pipeline's prompt/skill-rule changes — no
compiler or test runner exists for markdown skill definitions, so each
fixture is a hypothetical scenario plus the exact rule text it should
trigger, graded by manual walkthrough (same substitute the
2026-08-07 SDD-integration plan used for its own verification).

## How to run

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
| `10-g4-gate-orchestrated.md` | G4 gate, ORCHESTRATED mode | `keel-execute/SKILL.md` |
| `11-g4-gate-inline.md` | G4 gate, INLINE mode | `keel-execute/SKILL.md` |
| `12-security-exit-gate-blocked.md` | Part 2c BLOCKED condition | `keel-finish/SKILL.md` |
| `13-r4-security-axis-triggers.md` | R4 conditions (5 sub-scenarios) | `keel-execute/SKILL.md` |
| `14-security-lens-dispatch-trigger.md` | Security lens dispatch (OR of 3 conditions) | `keel-plan-review/SKILL.md` |
| `15-irreversible-operation-consent.md` | Consent guards for unrecoverable actions (5 sub-scenarios) | `keel-workflow`, `keel-execute`, `keel-finish`, the 3 write-capable agents |

Adding a new SDD/pipeline rule that has a clear trigger/no-trigger boundary?
Add a fixture here in the same format — that boundary is exactly what
silently breaks first when unrelated wording nearby gets edited. Then add a
row to `RULE-INVENTORY.md`, which tracks every declared rule (covered or
not) as the denominator for the `FIXTURE COVERAGE: N/M` line `keel-execute`'s
Finish step reports whenever a plan edits this repo's own skill files.
