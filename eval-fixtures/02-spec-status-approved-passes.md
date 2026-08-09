# Fixture 02: spec Status: approved lets keel-plan proceed

**Rule source:** `skills/keel-plan/SKILL.md` INPUT block

## Scenario

INPUT to `keel-plan` is a spec file path. The spec file's header contains:

```
**Status:** approved (2026-08-07, a1b2c3d)
```

## Expected

`keel-plan` proceeds normally to "Scope check, then map files" (Step 1) — no
`BLOCKED`. The plan header it writes copies the spec's approval marker into
`**Spec Version:**` (`skills/keel-plan/SKILL.md` Step 2 header template):

```
**Spec Version:** a1b2c3d
```

## Not expected (would be a regression)

- Blocking on an approved spec
- Dropping the commit hash/timestamp when copying into the plan header's
  `Spec Version:` field
