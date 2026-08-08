# Fixture 02: spec Status: approved lets dev-plan proceed

**Rule source:** `skills/dev-plan/SKILL.md:26-31`

## Scenario

INPUT to `dev-plan` is a spec file path. The spec file's header contains:

```
**Status:** approved (2026-08-07, a1b2c3d)
```

## Expected

`dev-plan` proceeds normally to "Scope check, then map files" (Step 1) — no
`BLOCKED`. The plan header it writes copies the spec's approval marker into
`**Spec Version:**` (`skills/dev-plan/SKILL.md:87-88`):

```
**Spec Version:** a1b2c3d
```

## Not expected (would be a regression)

- Blocking on an approved spec
- Dropping the commit hash/timestamp when copying into the plan header's
  `Spec Version:` field
