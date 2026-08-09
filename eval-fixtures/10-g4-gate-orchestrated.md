# Fixture 10: G4 gate, ORCHESTRATED mode — plan-conflict never self-decided

**Rule source:** `skills/keel-execute/SKILL.md` Per-task loop, step 4 (Fix
loop) — "`PLAN-CONFLICT` findings are never handed to the fixer — they go
to the user (gate G4)." + step 3's "Plan-mandated findings" note.

## Scenario A — finding tagged PLAN-CONFLICT

`keel-exec-reviewer-quality` finds that the task's own brief text
contradicts itself: one line says "match existing English-only format," a
later line supplies literal Chinese replacement text. Tagged
`PLAN-CONFLICT`.

## Expected A

The controller does not dispatch `keel-exec-fixer` for this finding and does
not pick a side itself. It presents both the finding and the plan's
conflicting text to the user via a single question and waits for the
answer before proceeding.

## Scenario B — ordinary Critical/Important finding, not plan-conflicting

`keel-exec-reviewer-quality` finds a genuine bug (off-by-one in a loop
bound) with no relationship to the plan's text.

## Expected B

Goes straight to the normal fix loop — `keel-exec-fixer` — no user question,
no G4 gate.

## Not expected (would be a regression)

- Auto-resolving a `PLAN-CONFLICT` finding by "the plan's authorship
  doesn't grade its own work" reasoning applied backwards (i.e. picking the
  reviewer's side without asking)
- Escalating every ordinary finding to the user because it's easier than
  judging severity
