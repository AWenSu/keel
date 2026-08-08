# TODOS

Deferred work from review decisions. Format: What / Why deferred / Effort (S/M/L/XL) / Priority.

## 2026-08-07 — dev-workflow SDD integration (docs/plans/2026-08-07-sdd-integration.md)

- ~~Eval-fixture harness for Task 1-7's prompt/skill-rule changes~~ — done
  2026-08-09: `eval-fixtures/` (repo root, not `.dev-pipeline/` — that path
  is gitignored process-artifact space, unsuitable for a versioned test
  asset) with 5 fixtures covering spec-status gate (draft/approved),
  spec-version drift routing, feature-matrix trigger, and ADR offer
  criteria. Manual-walkthrough grading (no compiler/runtime for markdown
  skill files exists yet); structural/behavioral automation left as future
  work if the fixture set grows past what manual walkthrough can carry.
