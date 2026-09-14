# Fixture 39: which rulebook reaches which stage (D24)

**Rule source:** `skills/keel-execute/SKILL.md` Universal rules — Project rulebook.
**Rule source:** `skills/keel-discover/SKILL.md` step 4 (parallel design exploration).
**Rule source:** `skills/keel-plan/SKILL.md` step 1 (Scope check, then map files).

`learned.py search` returns hits from the repo's own `.learned/` **and** from
every rulebook that repo mounts, each labelled by source: `project:` for the
local one, the rulebook's own name otherwise. Added 2026-09-14: the two kinds
are routed to different stages, because they are consumed at different
moments, not because one is larger.

A task-level pitfall changes how you write the line in front of you, so it is
due when that line is being written. A cross-project pattern changes what
shape you choose, so it is due while the shape is still open — and by the time
a task brief exists, that decision is several stages old.

## A — execute takes `project:` hits only

**Scenario:** ORCHESTRATED execution, task 3. The repo mounts a shared
rulebook. `learned.py search` on the task's keywords returns two `project:`
hits and three from the mount.

**Expected:** the two go into the implementer and reviewer briefs; the three
do not:

> **Use the `project:`-labelled hits only.** `search` also returns hits from
> any rulebook the repo mounts, labelled by that rulebook instead; those are
> cross-project design knowledge, and they are consumed at
> `keel-discover`/`keel-plan`/`keel-plan-review`, where the shape is still
> open. Arriving here they are unusable by construction — the architecture was
> settled stages ago — so they cost brief length and buy nothing.

**Not expected:** passing everything through on the grounds that more context
is safer. An implementer told at task 3 to "consider a different boundary"
cannot act on it without leaving its own Scope, which is a review failure.

**Note on the label, not the name:** the test is whether the hit is
`project:`, never what the mounted rulebook happens to be called. A mount's
label is its directory name, so two mounts can share one, and a rule keyed to
a specific name breaks the first time a second rulebook is added.

## B — discover puts the mounted hits in front of the designers

**Scenario:** `keel-discover` step 4 is about to dispatch three
`keel-discover-designer` agents under diverging constraints.

**Expected:** the search runs *before* dispatch and the non-`project:` hits
ride in each designer's brief:

> **Before dispatching, search any
> mounted rulebook** (`learned.py search "<kw>"` on the problem's domain terms)
> and put the non-`project:` hits in every designer's brief: those are patterns
> already judged worth keeping across projects, and this is the last stage at
> which a proposal can still be shaped by one.

and the local hits stay out, for the mirror reason:

> The `project:` hits stay out —
> they are task-level pitfalls with nothing to say about which design to
> propose.

**Not expected:** running the search after the proposals return and using it
to grade them — the point is to shape the proposals, and a designer that never
saw the pattern cannot be faulted for not using it.

## C — plan searches before the shape is chosen, not after

**Scenario:** `keel-plan` step 1 has mapped the files and is about to write
tasks.

**Expected:** the search happens here, at scope-check time:

> **Search any mounted rulebook before choosing the shape**, not after:
> `learned.py search "<kw>"` on the modules, frameworks and protocols this plan
> touches

and the reason is a claim about value decaying with time, not about volume:

> A pattern that would
> have changed the decomposition is worth minutes here and nothing at all once
> the tasks are written.

**Not expected:** deferring the search to a later review; treating it as
optional because the plan "already has a shape in mind" — that shape is
precisely what the search exists to challenge while challenging is still cheap.

## D — no mount, or nothing mounted matches

**Scenario:** the repo mounts no additional rulebook at all.

**Expected:** every stage behaves as it did before — `keel-execute` injects
`project:` hits, `keel-discover` and `keel-plan` find nothing to add, and
nothing blocks. A repo with only a local rulebook is the normal case.

**Not expected:** a stage stalling or warning because no cross-project
rulebook is mounted; a mount being created to satisfy the rule.

## Not expected (any scenario)

- Mounted-rulebook hits injected into implementer or reviewer briefs
- `project:` hits injected into designer briefs as design guidance
- The routing keyed to a mounted rulebook's name rather than to the absence
  of the `project:` label
- A design-stage search run after the design it was meant to inform
