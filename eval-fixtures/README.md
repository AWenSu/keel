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
| `01-spec-status-draft-blocks.md` | spec approval gate | `dev-plan/SKILL.md` |
| `02-spec-status-approved-passes.md` | spec approval gate | `dev-plan/SKILL.md` |
| `03-spec-version-drift-routes-back.md` | spec drift check | `dev-execute/SKILL.md` |
| `04-feature-matrix-trigger.md` | UI-heavy feature matrix | `dev-plan/SKILL.md` |
| `05-adr-offer-trigger.md` | ADR offer criteria | `dev-finish/SKILL.md` |

Adding a new SDD/pipeline rule that has a clear trigger/no-trigger boundary?
Add a fixture here in the same format — that boundary is exactly what
silently breaks first when unrelated wording nearby gets edited.
