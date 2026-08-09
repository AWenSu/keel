# Fixture 11: PLAN-CONFLICT gate (G6), INLINE mode — same rule, no separate reviewer subagent

**Rule source:** `skills/keel-execute/SKILL.md` INLINE mode step 3 — "G6 gate
applies here too: a finding that conflicts with the plan's own text is
never self-decided just because there's no separate reviewer subagent to
raise it."

## Scenario A — INLINE session notices a self-contradiction

Running INLINE mode (no subagents available), the same session that's
implementing Task 3 notices the plan's Task 3 text says "reuse the existing
`formatDate` helper" but Task 3's own `Files:` line targets a file where
`formatDate` was deleted two tasks ago per this same plan's Task 1.

## Expected A

The session stops and asks the user which wins (reintroduce `formatDate`,
or update Task 3's text to use its replacement) — same as the
ORCHESTRATED-mode G6 gate, even though there's no separate reviewer agent
in this loop to have raised it as a formal "finding."

## Scenario B — ordinary ambiguity, not plan-conflicting

Task 3's `Files:` line doesn't specify which of two similarly-named test
files to add the new test to.

## Expected B

This is ordinary "stop and ask rather than guess" (INLINE mode step 3's
general clause) — it doesn't need the G6-specific framing since nothing in
the plan's own text conflicts with anything else.

## Not expected (would be a regression)

- Treating G6 as an ORCHESTRATED-only mechanism because INLINE has no
  separate reviewer to "trigger" it
- The INLINE session silently picking the interpretation it thinks is
  right and continuing, since "no one's reviewing this anyway"
