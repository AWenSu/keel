# Fixture 23: name the signal before integrating (D12, A7)

**Rule source:** `skills/keel-finish/SKILL.md` Part 2d, and the
`keel-workflow` Backward-routes row *"Shipped work's `## Signals` say it did
not work — the requirement was wrong, not the code"*.

This is the cheap half of a product loop. The pipeline ends at merge, which
is where the code's life starts; a full post-release stage is a scope this
repo cannot honestly claim to run, but writing down **while the context still
exists** what reality would have to show is what makes the loop closable at
all.

## A — the question is asked before integrating, not after

**Scenario:** all Success Criteria confirmed, Part 2b clean, Part 2c no
BLOCKED. About to present the integration options.

**Expected:** Part 2d runs first — two one-line answers written to the plan's
`## Signals` section. After integration the context that knew what "working"
meant is gone, and the question becomes unaskable.

**Not expected:** deferring it to "we'll see how it goes."

## B — "what would tell us this was wrong" is not "a bug appears"

**Scenario:** a new onboarding flow. The failure signal offered is "users
report errors."

**Expected:** insufficient. That is a defect signal, and defects already have
a lane (`keel-debug`). Part 2d asks for the observation that would mean the
**requirement** was mistaken — e.g. "completion rate stays where it was, with
no errors logged," which says the flow works and nobody wanted it.

**Why the distinction carries weight:** those two observations route to
different stages. A defect goes to `keel-debug`; a wrong requirement goes to
`keel-discover`. Conflating them sends the wrong work to the wrong place.

## C — nothing to watch is a legitimate answer

**Scenario:** the change fixes a typo in a README.

**Expected:** "nothing to watch" answers the question correctly. Part 2d is
one question asked once, not a gate — it does not block integration and it
does not demand a metric for work that has none.

**Not expected:** inventing a signal to fill the field.

## D — no instrumentation is a TODO, not a shrug

**Scenario:** the success signal is a conversion metric nobody currently
records.

**Expected:** a `TODOS.md` entry in the standard format. The signal is named
and the gap to producing it is recorded — otherwise "we'll know it worked"
rests on data that does not exist.

## E — the return path uses the evidence it has

**Scenario:** three weeks later, the signal came back negative in the way
Part 2d predicted. The work re-enters at `keel-discover`.

**Expected:** intake starts from **"which part of the original requirement
was mistaken,"** quoting the plan's Signals line and the observation that
contradicted it — not from a blank five-question intake. A requirement that
failed in reality carries evidence a fresh one does not.

**Not expected:** treating it as a new idea and re-deriving the same wrong
spec.

## Not expected (any scenario)

- Part 2d blocking integration — it is a question, not a gate
- A failure signal that is really a defect signal
- Routing a negative signal to `keel-debug`, or a defect to `keel-discover`
