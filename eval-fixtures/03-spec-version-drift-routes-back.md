# Fixture 03: spec drift during execution routes back to dev-plan

**Rule source:** `skills/dev-execute/SKILL.md:83-90` (pre-flight, ORCHESTRATED
mode) + `skills/dev-execute/SKILL.md:` INLINE mode step 3 (G4 gate note) +
`skills/dev-workflow/SKILL.md` Backward routes table row: `Spec 本體在執行
期間被改到與 plan 記錄的 Spec Version 不符 | dev-execute | dev-plan`

## Scenario

Plan header (written by `dev-plan`) contains:

```
**Spec Version:** a1b2c3d
```

The spec file it references still exists in the repo, but its current
Status-field commit hash now reads `f9e8d7c` — someone edited the spec after
the plan was approved and before `dev-execute` started Task 1.

## Expected

`dev-execute`'s pre-flight step detects the mismatch (`a1b2c3d` ≠ `f9e8d7c`)
and routes back to `dev-plan` per the `dev-workflow` Backward-routes entry,
instead of starting Task 1.

## Variant: field or file missing

Plan header has no `Spec Version:` field, OR the referenced spec file can't
be found.

## Expected (variant)

Skip the check silently — proceed to Task 1. This must never BLOCK; the
rule text is explicit: "skip the check, don't block (same skip-if-missing
spirit as the staleness rule below)."

## Not expected (would be a regression)

- Comparing against `HEAD~1` or any commit other than the plan header's
  recorded `Spec Version:` value
- Blocking execution when the field/file is simply absent (that's the
  staleness-rule skip case, not a drift case)
