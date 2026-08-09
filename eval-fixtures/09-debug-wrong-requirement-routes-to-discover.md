# Fixture 09: debugging concludes the requirement is wrong → keel-discover

**Rule source:** `skills/keel-workflow/SKILL.md:38` — "Debugging concludes
the requirement itself is wrong | keel-debug | keel-discover"

## Scenario A — requirement is wrong

While debugging why a "cancel subscription" feature charges the user one
extra day, root-cause analysis shows the code does exactly what the spec
says (charge through end of current billing period) — the spec itself is
the bug: it never considered mid-cycle cancellation as a distinct case.

## Expected A

`keel-debug` does not just patch the code to "feel more correct." It routes
back to `keel-discover` to re-derive the requirement, since the defect is in
what was asked for, not in the implementation.

## Scenario B — requirement is right, code is wrong

Same symptom, but root-cause shows the code has an off-by-one error against
a spec that correctly says "charge through end of period, prorate the
final day."

## Expected B

Ordinary bug fix — no route-back. Fix the code, verify against the existing
(correct) requirement.

## Not expected (would be a regression)

- Silently reinterpreting the requirement mid-debug instead of routing back
  to keel-discover for an explicit re-derivation
- Routing back to keel-discover for ordinary implementation bugs where the
  requirement was never in question
