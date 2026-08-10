# Fixture 07: three full review passes still unresolved → keel-discover

**Rule source:** `skills/keel-plan-review/SKILL.md` Step 5 exit gate —

> Max 3 **full review passes** — one pass being Steps 1→5 run end to end. If
> a third pass still has unresolved items, the plan is fighting the spec; go
> back to keel-discover. Step 5's internal frontier batches are not passes
> and are not counted: a dependency chain four batches deep is a normal plan
> being questioned in the right order, not a plan in trouble.

plus `skills/keel-workflow/SKILL.md` Backward routes.

The counted unit is the **pass**, not the batch. This fixture originally
tested batches and would have failed correct behaviour — the rule text calls
a deep batch chain normal, and the fixture called it a route-back.

## A — three full passes, still open

**Scenario:** the plan has been through Steps 1→5 three separate times. After
the third, one Taste finding is still unresolved.

**Expected:** no fourth pass. Route back to `keel-discover` — three passes
without convergence is read as the plan fighting the spec, not as
under-review.

## B — one pass, four frontier batches

**Scenario:** a single review pass. Step 5's dependency tree is four levels
deep, so four rounds of questions go out before the frontier empties.

**Expected:** **no route-back, and no finding.** Frontier batches are not
passes. The rule names this case explicitly: *"a dependency chain four
batches deep is a normal plan being questioned in the right order."*

**This is the boundary the fixture exists for.** Counting batches as passes
sends a healthy plan back to requirements-gathering after one review.

## C — resolved in pass 2

**Scenario:** everything settles during the second pass.

**Expected:** proceed to the closing summary and `REVIEW REPORT`
(`NO UNRESOLVED DECISIONS`). No third pass is manufactured to fill a quota.

## Not expected (any scenario)

- Counting Step 5's frontier batches toward the three-pass limit
- A fourth full pass instead of routing back
- Treating "still unresolved after three passes" as an ordinary
  deferred-to-TODOS item rather than a spec-level problem
