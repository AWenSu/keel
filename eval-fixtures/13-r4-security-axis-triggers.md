# Fixture 13: R4 conditions — when the security review axis dispatches

**Rule source:** `skills/dev-execute/SKILL.md:121-143` — five conditions,
any one match triggers `dev-exec-reviewer-security` as a third independent
axis; none matching skips it (logged, not silent).

One fixture, five sub-scenarios — the five conditions share a single
dispatch mechanism, so they're graded together rather than as five separate
files.

## 1 — semantic auth/encryption/upload/outbound/DB-query touch

**Trigger:** task's `Delivers:` says "narrow the order-history query to the
requesting user's own orders," `Files:` says `services/order.py` (no "auth"
string anywhere). **Expected:** triggers — judged against `Delivers:`
semantics (an ownership filter on a DB query), not the literal filename.
**No-trigger control:** `Delivers:` says "add a computed `total_items`
field to the order summary response" — no auth/encryption/upload/outbound/
DB-query-construction behavior in the Delivers text → does not trigger on
this condition alone.

## 2 — externally-reachable endpoint

**Trigger:** diff adds a new public `POST /api/webhooks/stripe` route.
**Expected:** triggers. **No-trigger control:** diff adds a new *internal*
helper function called only from existing, already-reviewed endpoint code
→ does not trigger on this condition alone.

## 3 — dev-plan marked the task high-risk

**Trigger:** task header reads `[Risk: High]`. **Expected:** triggers
regardless of what the task's content is. **No-trigger control:**
`[Risk: Low]` → does not trigger on this condition alone.

## 4 — plan-stage security lens previously flagged this task

**Trigger:** `dev-plan-lens-security`'s `FINDINGS:` output has an entry
tagged `## Task 5`, and this is Task 5 — triggers even if that finding was
already fixed before execution started ("previously raised," not "still
unresolved"). **No-trigger control:** the lens's findings only tag `## Task
3` and `## Task 7`; this is Task 5 → does not trigger on this condition.

## 5 — sensitive-string pattern match

**Trigger:** diff includes a line matching `api[_-]?key`.
**Expected:** triggers. **No-trigger control:** diff mentions the English
word "secretary" — must not fire on a substring match unless it actually
matches the stated pattern set (`password`, `secret`, `token`,
`api[_-]?key`, `BEGIN.*PRIVATE KEY`, connection-string shape); "secretary"
does not match `secret` as a whole-pattern per the rule's intent, though a
naive substring `grep secret` implementation would — this sub-scenario
exists specifically to catch that false-positive failure mode.

## Zero conditions matched

**Scenario:** a task only bumps a dependency's version number in a package
list. **Expected:** security axis skipped; ledger line cites which
condition was checked and why none matched (per dependency-only diffs,
cites deferral to `dev-finish` Part 2c(3) explicitly, not a bare "skip").

## Not expected (would be a regression)

- Any one condition failing to trigger the axis when it should
- Triggering on a literal filename/keyword match for condition 1 instead of
  the semantic Delivers-content judgment
- A skipped axis with no ledger explanation (silent omission)
