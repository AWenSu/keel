# TODOS

Deferred work from review decisions. Format: What / Why deferred / Effort (S/M/L/XL) / Priority.

## 2026-08-07 — dev-workflow SDD integration (docs/plans/2026-08-07-sdd-integration.md)

- **What:** Eval-fixture harness for Task 1-7's prompt/skill-rule changes — a
  repeatable `.dev-pipeline/eval-fixtures/` set of hypothetical plans to
  regression-test dispatch logic (e.g. feature-matrix trigger, ADR offer
  trigger, spec-status gate) instead of one-off manual walkthroughs.
  `file:line`: Eng lens finding, `.dev-pipeline/eng-lens-report.md` (this
  review round).
- **Why deferred:** This round's 7 tasks are all prompt/skill definition
  files with no compiler/runtime/test framework; the grep-c + manual
  walkthrough substitute (see plan's "專案類型調整" section) is sufficient
  for this round's verification. A reusable eval harness is a larger,
  separate investment not required to ship R1-R6 + SDD mechanisms.
- **Effort:** M
- **Priority:** Low
