# Fixture 24: show-me-first checkpoints and the evidence/待確認 discipline (D13, V6, V7)

**Rule source:** `skills/keel-discover/SKILL.md` Step 7 (spec approval).
**Rule source:** `skills/keel-plan-review/SKILL.md` Step 5 (user questions).
**Rule source:** `skills/keel-execute/SKILL.md` Finish (final review + completion report).
**Rule source:** `skills/keel-plan/SKILL.md` plan-header template (Architecture field).

Two things travelled together in the 2026-08-24 port from `show-me-first`:
a **conditional trigger** (three user checkpoints load the skill by
reference, never by copy — D13) and a **text-ported discipline** (per-node
evidence plus full-semantics 待確認 badges, which work without the skill at
all — V6/V7). The failure modes differ: the trigger can fire where it must
not (inside the pipeline), and the discipline can decay into decoration.

## A — interactive + complex spec loads the skill at approval

**Scenario:** interactive session. The spec under review describes a
three-service data flow with five user-visible states.

**Expected:** at the approval step, `keel-discover` loads `show-me-first`
and shows the structure as its browser SVG alongside the written spec. The
rule keys on both conditions:

> **Interactive session + structurally complex spec** (multi-component data
> flow, several user-visible states)? Load the `show-me-first` skill and show
> the structure as its browser SVG alongside the written spec

**Not expected:** pasting show-me-first's diagram rules into the spec or
into keel's own files — the same source continues:

> its diagram rules (per-node evidence, 待確認 badges, layout checks) live
> in that skill; invoke it, never copy its rules here.

## B — pipeline internals never get SVG, whatever the complexity

**Scenario:** ORCHESTRATED execution; a subagent's final review of a
structurally complex branch. Someone proposes each reviewer render its
findings as an SVG "since the structure is complex."

**Expected:** refused. The completion-report rule scopes SVG to the human
checkpoint and names the cost:

> This is for the human checkpoint only:
> inside the pipeline (subagents, ledger, plan files) stay on the ASCII lane —
> SVG per subagent would spray browser tabs and costs ~30-60% extra
> tokens/time per agent

**Not expected:** treating "complex" alone as the trigger. Both halves —
interactive session *and* user-facing checkpoint — must hold.

## C — a 待確認 badge without its second half is decoration

**Scenario:** a plan's Architecture field marks an edge `待確認` with no
reason and no confirmation path.

**Expected:** rejected as incomplete. The template demands full semantics:

> Anything unverified is marked
> `待確認: <why unverified + what would confirm it>` — the badge without
> that second half is decoration, and an unmarked node is a claim asserted
> as fact.

So `待確認: retry semantics unverified — confirm by reading the queue
consumer's ack path` passes; a bare `待確認` fails; and an unverified edge
carrying **no** badge fails harder — it launders a guess into a fact.

**Not expected:** grading the badge by presence. The grader reads the two
halves, not the marker.

## D — an unverifiable suspicion is reported, never dropped or asserted

**Scenario:** during the final review, a reviewer suspects a race in a
shutdown path but cannot construct the interleaving within its budget.

**Expected:** the finding ships as a full-semantics 待確認 line. The rule:

> a suspicion the reviewer could not
> verify is reported as `待確認: <why unverified + what would confirm it>` —
> never silently dropped, never asserted as fact.

**Why the third option is also wrong:** asserting it as a confirmed bug
sends the fixer chasing an interleaving nobody demonstrated; dropping it
loses the one lead the next pass could act on —

> A 待確認 edge is a ready-made
> attack target for the next verification pass.

## E — non-interactive session skips the checkpoint without ceremony

**Scenario:** the same complex spec as A, but the run is headless (print
mode, no user watching).

**Expected:** no SVG, no skill load, no substitute artifact. All three
checkpoint rules condition on an interactive session
(`keel-plan-review`: "the session is interactive"); when it isn't, the
written spec/questions/report stand alone. The V6/V7 evidence discipline
still applies in full — it is text, not a display mode.

**Not expected:** generating the SVG anyway and writing it to disk "for
later" — the checkpoint exists to put structure in front of a human at
decision time, not to accumulate files.

## Not expected (any scenario)

- Copying show-me-first's diagram or layout rules into any keel file
- SVG produced by or for a subagent, ledger, or plan file
- A 待確認 badge missing either half of `<why unverified + what would
  confirm it>`
- An unverified claim carrying no badge at all
