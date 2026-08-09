# Fixture 05: ADR offer criteria at keel-finish Part 2

**Rule source:** `skills/keel-finish/SKILL.md` Part 2 ADR check

> a decision this work locked that is hard to reverse + surprising without
> context + a real trade-off → offer a one-paragraph ADR before integrating.
> If the plan file already has a matching `## ADR: <decision name>` section
> ... skip the offer

## Scenario A — offer

During execution the team chose to store session tokens in an httpOnly
cookie instead of localStorage (hard to reverse once clients depend on it;
surprising to a reader who'd expect localStorage from the rest of the
codebase; real trade-off — XSS resistance vs. needing CSRF protection). The
plan file has no `## ADR: ...` section.

## Expected A

`keel-finish` Part 2 offers to write a one-paragraph ADR into the plan file
before integrating.

## Scenario B — skip, already produced

Same decision, but the plan file already contains a `## ADR: session token
storage` section written by `keel-plan-review` Step 5 at decision time.

## Expected B

`keel-finish` Part 2 skips the offer — does not ask again.

## Scenario C — no offer

The work only renamed an internal helper function (easily reversible, not
surprising, no real trade-off).

## Expected C

`keel-finish` Part 2 does not offer an ADR.

## Not expected (would be a regression)

- Offering an ADR for every decision regardless of the three criteria
- Re-asking when a matching `## ADR: <decision name>` section already exists
- Silently skipping the check for a decision that does meet all three
  criteria
