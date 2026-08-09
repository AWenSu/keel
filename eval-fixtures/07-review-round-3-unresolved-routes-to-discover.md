# Fixture 07: plan review round 3 still unresolved → keel-discover

**Rule source:** `skills/keel-plan-review/SKILL.md:304-305` — "Max 3 review
rounds — if round 3 still has unresolved items, the plan is fighting the
spec; go back to keel-discover." + `skills/keel-workflow/SKILL.md:36`

## Scenario A — round 3 still has open items

`keel-plan-review` Step 5 runs three rounds of Taste/User-Challenge
questions. After round 3, one Taste finding is still unresolved (the user's
answer to round 2 reopened a dependency that round 3's question didn't
fully settle).

## Expected A

`keel-plan-review` does not attempt a round 4. It routes back to
`keel-discover` — the plan is judged to be "fighting the spec," not just
under-reviewed.

## Scenario B — resolved by round 2

All findings resolved after round 2; round 3 never triggers (empty
frontier).

## Expected B

`keel-plan-review` proceeds to the closing summary and `REVIEW REPORT`
(`NO UNRESOLVED DECISIONS`) — no route-back, no forced round 3.

## Not expected (would be a regression)

- Running a 4th round instead of routing back
- Treating "still unresolved after round 3" as a normal deferred-to-TODOS
  item instead of a spec-level problem
