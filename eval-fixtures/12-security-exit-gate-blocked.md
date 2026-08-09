# Fixture 12: keel-finish Part 2c BLOCKED condition

**Rule source:** `skills/keel-finish/SKILL.md:138-156`

## Scenario A — unresolved Critical from check (2), no risk-acceptance

`keel-exec-reviewer-security` raised a Critical finding during Task 5
(SQL built via string concatenation from user input). It was never fixed
and the user never explicitly accepted the risk.

## Expected A

`keel-finish` returns `BLOCKED: 資安 finding 未關閉` and does not proceed to
Part 3 (branch integration options are never presented).

## Scenario B — same finding, explicit risk-acceptance recorded

Same Critical finding, but the user explicitly accepted it and it's
recorded in `TODOS.md` (What/Why deferred/Effort/Priority + the finding's
`file:line`), per the Risk-acceptance format.

## Expected B

Not BLOCKED — check (2) treats this as resolved (risk-accepted counts),
proceeds to Part 3.

## Scenario C — checks (1) and (3a) unavailable (no scanner installed)

No gitleaks/semgrep, no dependency-CVE scanner. Checks (2), (3b), (4) are
all clean/n/a.

## Expected C

Not BLOCKED. `keel-finish` states "secrets scan: not executed" and "CVE
scan: not executed" plainly, proceeds to Part 3 — (1) and (3a) never
trigger BLOCKED on their own, per the rule's explicit carve-out.

## Not expected (would be a regression)

- Proceeding to Part 3 with an unresolved Critical from (2)/(3b)/(4) and no
  risk-acceptance record
- Blocking on (1) or (3a) alone because a scanner isn't installed —
  that's the alarm-fatigue failure mode the rule text explicitly rules out
