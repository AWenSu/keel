# Fixture 01: spec Status: draft blocks keel-plan

**Rule source:** `skills/keel-plan/SKILL.md:26-31`

> the spec's `Status:` field must read `approved` before this skill
> proceeds; otherwise `BLOCKED: spec 未核准 → 退回 keel-discover`

## Scenario

INPUT to `keel-plan` is a spec file path. The spec file's header contains:

```
**Status:** draft
```

## Expected

`keel-plan` does not proceed to Step 1. It returns:

```
BLOCKED: spec 未核准 → 退回 keel-discover
```

## Not expected (would be a regression)

- Proceeding to write the plan header regardless
- Treating `draft` as "close enough" and warning instead of blocking
- Applying this block to the "requirements clear enough to name exact file
  paths" path or the Medium-task lightweight shortcut — the rule text
  scopes the check to "an actual spec file" only (line 28-31)
