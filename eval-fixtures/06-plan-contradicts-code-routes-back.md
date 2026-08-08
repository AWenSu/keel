# Fixture 06: execution finds the plan contradicts current code

**Rule source:** `skills/dev-workflow/SKILL.md:34` (Backward routes) —
`Execution finds the plan contradicts the code as it now is (beyond one
task's fix) | dev-execute | dev-plan`

## Scenario A — beyond one task's fix

Task 4's implementer discovers the plan assumes `AuthService.validate()`
still exists, but Task 2 (already merged, unrelated branch) removed it
last week — the plan's whole auth-related task sequence (Tasks 4-6) is now
built on a function that's gone, not just one task's file path.

## Expected A

`dev-execute` routes back to `dev-plan`, not just relocating Task 4's edit
by its `Delivers:` line (the ordinary staleness rule) — because the
contradiction spans multiple tasks, one task's fix-and-continue would leave
Tasks 5-6 built on the same wrong assumption.

## Scenario B — one task's fix is enough (no route-back)

Task 4's `Files:` line says `src/auth.py:120-140`, but that code moved to
`src/auth.py:200-220` in an unrelated merge — same function, same
signature, just relocated. The implementer relocates using the `Delivers:`
line (ordinary staleness rule) and continues.

## Expected B

No route-back. This is the staleness-relocation path
(`dev-plan/SKILL.md`'s "Delivers is truth, Files is a hint" rule), not the
plan-contradicts-code path — the boundary between the two is exactly what
this fixture exists to pin down.

## Not expected (would be a regression)

- Routing back to `dev-plan` for every stale `Files:` line regardless of
  scope (that's staleness-relocation's job, not this rule's)
- Silently pushing through a multi-task contradiction by patching each task
  independently instead of stopping to re-plan
