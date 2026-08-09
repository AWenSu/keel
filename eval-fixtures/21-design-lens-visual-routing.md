# Fixture 21: design lens checks visual source of truth and skill routing

**Rule source:** `agents/keel-plan-lens-design.md` §B (visual source of
truth), §C (design-skill routing via the task `Skills:` field), §D (reuse
before forking), plus the Specificity rule's extension to all of them.

Context for §C: `keel-plan` writes a `Skills:` field on every task so
execution does not have to rediscover which domain skills apply, and
`keel-exec-implementer` invokes whatever it names — but **no reviewer
verified that field was right**. This lens covers the UI half.

## A — every state named, no visual source of truth

**Scenario:** the plan names empty, error, loading, boundary and transition
states for a new settings screen. It says nothing about what the screen
should look like — no mockup, no existing screen to match, no design system,
no design skill.

**Expected:** a finding. Naming states is the correctness half; without a
visual source of truth the implementer invents the rest, and three tasks
invent three different versions of it.

**Not expected:** a clean pass because the state matrix is complete. The
state matrix and §B are different checks.

## B — the source of truth can be any of four things

**Scenario A:** the plan links an approved mockup. **B:** the plan says
"match the existing `/billing` screen." **C:** the plan names the project's
design system. **D:** the task's `Skills:` names a design-taste skill whose
conventions it adopts.

**Expected:** all four satisfy §B. The check is that *one* exists, not that a
specific one does.

## C — UI task with an empty `Skills:` field

**Scenario:** `Task 3 — build the onboarding carousel`, producing a
user-visible surface. Its `Skills:` field reads `none`.

**Expected:** a finding, with the concrete edit being to name the capability
the task needs. **No route-back, no BLOCKED** — this is a lens finding that
becomes a plan edit, like every other finding this lens produces.

**Boundary:** `Task 5 — add a database index`. No user-visible surface, so
§C does not apply and `Skills: none` is correct.

## D — named skill contradicts the stated visual intent

**Scenario:** the spec describes a "dense operator console with high
information density." The task's `Skills:` names a minimalist editorial
design skill.

**Expected:** a finding. The two will fight at implementation time and
whichever the implementer reads last wins.

**Boundary:** the spec says "calm, sparse, editorial" and the task names the
same minimalist skill → consistent, no finding.

## E — the three routing situations are different

**Scenario:** three UI tasks — (1) a brand-new screen with no visual
precedent, (2) a screen that must match an existing one pixel-for-pixel,
(3) turning an already-approved mockup image into markup.

**Expected:** the lens checks each task's named skill matches *which
situation it actually is* — a from-scratch visual direction, a
match-the-existing job, and a screenshot-to-code job route to different
capabilities. A single skill named across all three is a finding.

## F — capability, not a hardcoded roster

**Scenario:** the lens raises a §C finding.

**Expected:** the suggested edit names the **capability** ("a design-taste
skill for a from-scratch visual direction", "a brand/identity skill"), or
cites the project's own routing table in `CLAUDE.md` / `PROJECT-TYPE-GUIDE.md`
if one exists.

**Not expected:** a hardcoded list of skill names baked into the finding. The
installed set differs per environment and per month; a stale list is worse
than no list. This is the same defect as the `~/.claude/...` absolute paths
removed from `keel-exec-reviewer-quality` on 2026-08-09.

## G — taste is still out of bounds

**Scenario:** the plan is complete on states, has an approved mockup, and
routes correctly. The lens reviewer thinks the mockup looks dated.

**Expected:** **not a finding.** There are no pixels at plan stage; "looks
dated" is unfalsifiable here and belongs to whoever reviews the built screen.
The Specificity rule binds §B–§D exactly as it binds §A.

**The distinction:** "no visual source of truth exists" is checkable from the
plan text. "The visual source of truth is ugly" is not this lens's call.

## H — reuse before forking

**Scenario:** the plan introduces `PrimaryActionButton`. The codebase already
has `Button` with a `variant="primary"` prop.

**Expected:** a finding citing the existing component's `path:line`. Silent
forks are how a UI ends up with four button variants, and the plan is the
cheapest place to catch it.

## Not expected (any scenario)

- Passing a UI plan because its state matrix is full, without checking §B–§D
- Raising a taste judgment from plan text
- A finding without a `file:line` anchor entering the main verdict
  (confidence ≤5, appendix only — the evidence gate is unchanged)
