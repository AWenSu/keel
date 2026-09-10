# Fixture 35: a run you can watch — announce before, broadcast by name (F20)

**Rule source:** `rules/dispatch-announce.txt`, appearing verbatim in all eight dispatching stages.
**Rule source:** `skills/keel-plan-review/SKILL.md` Step 2 (Announce the roster), Step 4 (Broadcast each verdict).
**Rule source:** `skills/keel-execute/SKILL.md` ORCHESTRATED per-task loop step 3 (Broadcast every verdict).
**Rule source:** `skills/keel-discover/SKILL.md` step 4 (parallel design exploration).
**Rule source:** `skills/keel-wayfind/SKILL.md` research-ticket dispatch.

Added 2026-09-11 from a user report: during a real run, the person watching
could not tell which agent was executing or which stage it belonged to. The
agent names already encode both — `keel-exec-*` is stage 4, `keel-plan-lens-*`
is stage 3 — so nothing was missing from the roster. What was missing was any
requirement to **say the name**: only `keel-plan-review` announced before
dispatching, and only its skeptic broadcast named the agent. `keel-execute`
broadcast "axis, PASS/FAIL", which identifies neither the agent nor the stage.

The canonical rule is one line, carried verbatim by every dispatching stage:

> Name the agent, not the role: announce each dispatch before it runs and broadcast each result when it lands, both using the agent's literal `keel-*` name.

## A — the announcement happens before, not only after

**Scenario:** `keel-execute`, task 3. The controller dispatches
`keel-exec-implementer`, waits, and on return posts a summary naming it.
Nothing was said during the seven minutes the implementer was running.

**Expected:** insufficient. The rule has two halves and this satisfies one:

> announce each dispatch before it runs and broadcast each result when it lands

The reason the first half exists is the reason the person filed the report:
the dispatch is the longest part of the run, and it is exactly the window in
which nothing was being said.

**Not expected:** treating the return broadcast as covering both; announcing
a batch after the fact ("ran the implementer and two reviewers").

## B — the role is not the name

**Scenario:** three reviewers return on task 3. The controller writes:
"spec axis PASS, quality axis PASS, security axis PASS."

**Expected:** each verdict carries the agent's literal name:

> the agent's own name
> (`keel-exec-reviewer-quality`, not "the quality reviewer"), its axis,
> PASS/FAIL, the single worst issue with its `file:line` anchor, and what
> you do next.

and the stated reason is precisely the reported symptom:

> The name is what tells a watcher which stage they are in
> and which of the three axes just spoke; a paraphrase loses both.

**Not expected:** "the quality reviewer", "reviewer 2", "the security pass" —
each is a paraphrase that drops the `keel-exec-` prefix, which is the half
that carries the stage.

## C — the skeptic tier is only visible in the name

**Scenario:** a Critical finding is verified and comes back `REFUTED`. The
controller reports the verdict and the reason, without naming the agent.

**Expected:** the name is load-bearing here for a second reason —
`keel-plan-skeptic` and `keel-plan-skeptic-critical` are different tiers with
different rigour, and only the name distinguishes them:

> Broadcast each verdict as it lands — the agent name (so the tier is visible),
> `UPHELD`/`WEAKENED`/`REFUTED`, and the one-line reason. A refutation you never
> see is a decision made on your behalf.

**Not expected:** "the skeptic refuted it" — a reader cannot tell whether a
Critical finding got the heavy tier it was owed.

## D — a roster announcement says what was skipped, too

**Scenario:** `keel-plan-review` Step 1 selects CEO and Eng; Design and DX
miss their keyword thresholds; Security fires. The controller dispatches
three lenses and says nothing about the two it did not.

**Expected:** the roster names the skips and their reason:

> **Announce the roster before dispatching**, naming which conditional lenses
> were skipped and why.

**Why the skips matter more than the runs:** a lens that ran will announce
itself on return. A lens that never ran produces nothing, so its absence is
indistinguishable from a lens that ran and found nothing — the same
coverage-versus-result confusion fixture `30` scenario E pins for
`lens not run` / `no findings`.

**Not expected:** announcing only the three that ran; deferring the skip list
to the Step 5 summary.

## E — every fan-out site, not just the reviewed ones

**Scenario:** `keel-discover` dispatches three `keel-discover-designer`
agents under diverging constraints; `keel-wayfind` dispatches four
`keel-wayfind-researcher` agents on research tickets.

**Expected:** both announce before dispatching and broadcast by name on
return. The canonical rule is carried by all eight dispatching stages, and
`rules/manifest.tsv` lists them under the `dispatching-stage` derivation —
which `check-structure.sh` recomputes from the skill files themselves rather
than trusting the list, so a stage added later cannot be exempt by having no
manifest row (F17).

`keel-discover` additionally names the constraint each designer was given,
because with identical agent names that is the only thing distinguishing
them:

> Name the
> constraint in each dispatch and broadcast each proposal as it returns, so the
> divergence is visible before you compare.

**Not expected:** treating announcement as a review-stage courtesy; a new
stage added later inheriting an exemption because nobody added its manifest
row — the derivation makes that a failing check, not a silent gap.

## F — silence is a steering failure, not a style choice

**Scenario:** a controller suppresses per-agent broadcasts to keep the
transcript short, planning one clean summary at the end.

**Expected:** refused, in the words of the stage that has had this rule
longest:

> Never hold results back for the Step 5 summary; a stage whose
> progress is invisible cannot be steered.

**Not expected:** brevity offered as the justification. The output being
watched is not a log; it is the only surface on which a person can stop a run
that has gone wrong, and a summary arrives after the point where stopping was
possible.

## Not expected (any scenario)

- A dispatch that is only reported after it returns
- A verdict, proposal, or finding attributed to a role, an axis, or a number
  instead of the agent's literal `keel-*` name
- A roster that lists what ran without what was skipped and why
- Any dispatching stage lacking the canonical line, or lacking its manifest
  row — the derivation catches both
- Broadcasts batched into a final summary for tidiness
