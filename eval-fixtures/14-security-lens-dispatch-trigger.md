# Fixture 14: dev-plan-review Security lens dispatch trigger

**Rule source:** `skills/dev-plan-review/SKILL.md:47-50` — any ONE of: 2+
hits of auth/login/session/token/secret/key/credential/permission/role/
upload/個資/PII/payment/delete/export/webhook/external API; the plan's
Global Constraints or any task carries a high-risk marker; the plan adds
any externally reachable endpoint.

## Scenario A — 2+ keyword hits

Plan text: "Add **login** flow, issue a **session** **token** on success."
(3 hits: login, session, token.)

## Expected A

Security lens (`dev-plan-lens-security`) is dispatched in Step 2, after CEO
and Design, before Eng/DX per the fixed lens order.

## Scenario B — high-risk marker, 0 keyword hits

Plan text: "Batch-rewrite the `orders` table's `status` column type from
string to enum." No security-keyword hits, but Task 1 carries `[Risk:
High]`.

## Expected B

Security lens still dispatches — the OR-condition triggers on the risk
marker alone, independent of keyword count.

## Scenario C — new externally reachable endpoint, 0 keyword hits, no risk marker

Plan text: "Expose a new public `GET /api/status` health-check endpoint
returning `{status: "ok"}`." No security keywords, no risk marker.

## Expected C

Security lens still dispatches — the OR-condition triggers on the new
external endpoint alone.

## Scenario D — no trigger

Plan text: "Rename the `formatDate` helper to `formatDisplayDate`
throughout the codebase." 0 keyword hits, no high-risk marker, no new
endpoint.

## Expected D

Security lens is skipped. The roster announcement (per Step 2's "Announce
the roster before dispatching") names it as skipped and states which of
the three OR-conditions was checked and found absent.

## Scenario E — exactly 1 keyword hit (boundary)

Plan text: "Add a **login** button to the homepage nav bar." (1 hit:
login. No session/token/secret/etc.)

## Expected E

Security lens does NOT dispatch on the keyword-count condition alone (the
rule requires 2+, not 1+) — unless a high-risk marker or new endpoint also
applies, which this scenario has neither of.

## Not expected (would be a regression)

- Requiring keywords AND a risk marker AND an endpoint (rule is OR, not AND)
- Dispatching on exactly 1 keyword hit
- Silently skipping without stating which condition was checked
