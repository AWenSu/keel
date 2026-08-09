# Fixture 04: UI-heavy plan triggers the feature matrix step

**Rule source:** `skills/keel-plan/SKILL.md:98-109` (`### 2b. Feature matrix
for UI-heavy plans`), reusing `keel-plan-lens-design`'s trigger: "2+
view/rendering/UI/component/screen keywords"

## Scenario A — trigger

A plan's Goal/spec text reads: "Add a new **screen** with a settings
**component** and a loading **view** state." (3 keyword hits: screen,
component, view.)

## Expected A

Before writing tasks (Step 3), `keel-plan` produces a feature ×
state/role/platform matrix (table form) under a new `## Feature Matrix`
section in the plan file — heading text exactly `## Feature Matrix`, not a
paraphrase, so the check in
`.keel/task-4-report.md`'s acceptance grep (`"^## Feature Matrix\|###
2b\."`) actually matches.

## Scenario B — no trigger

A plan's Goal/spec text reads: "Add a retry wrapper around the payment
webhook handler." (0 UI keyword hits.)

## Expected B

`keel-plan` skips Step 2b entirely — no matrix, no `## Feature Matrix`
section, no added planning overhead.

## Not expected (would be a regression)

- Inventing a second, different keyword list instead of reusing
  `keel-plan-lens-design`'s trigger verbatim
- Producing the matrix for every plan regardless of keyword count
- Using a heading other than `## Feature Matrix` (breaks the grep-based
  acceptance check and the repo's own `### 2b.`/`### 3b.` numbering
  convention — see the Task 4 quality-review "optimizing for the check, not
  the behavior" finding this rule was fixed against)
