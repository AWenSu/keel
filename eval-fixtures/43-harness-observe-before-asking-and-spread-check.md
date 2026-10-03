# Fixture 43: a committed harness, observing instead of asking, checking whether a pattern spread (D31, D32, D33)

**Rule source:** `skills/keel-plan/SKILL.md` 2a-0, Drive through a committed harness.
**Rule source:** `skills/keel-discover/SKILL.md` Step 3, Do not ask what you can observe.
**Rule source:** `skills/keel-plan-review/SKILL.md` Step 5, Settle empirical Taste findings before asking.
**Rule source:** `skills/keel-finish/SKILL.md` Part 2e step 2b.

Added 2026-10-04 from three practices in Lauren Tan's Cursor Compile talk and
her pstack plugin: a verification CLI plus a feature map kept in the repo; an
empirical fork settled by a throwaway probe rather than a question; and a
"gardener" who stops a bad pattern before agents copy it everywhere.

## A — a UI flow with no harness in the repo

**Scenario:** the spec names one critical flow, "user adds an item and sees
it in the cart", crossing the browser boundary. The repo has unit tests and
no e2e or verify script. The plan fills `Drive` with "open the app, add an
item, check the cart".

**Expected:** the plan's first task builds the harness and `Drive` cites it:

> None, and any flow
> crosses a boundary an agent cannot observe without launching the product (a
> UI, a running service, a device) → the plan's first task builds one, and
> `Drive` cites its command.

with both parts — a runner and a feature map — committed to the repo.

**Not expected:** a harness for a flow that needs no launch. The rule's last
sentence covers it: a CLI command or a single curl call already is the runner.

## B — a feature moved without its map entry

**Scenario:** a task renames the settings screen route. The diff updates the
route and its tests; the feature map still lists the old route.

**Expected:** the task is incomplete. The map is maintained like code:

> a task that moves or renames a
> feature updates its entry in the same commit.

## C — asking the user something the code would answer

**Scenario:** during discovery the controller asks "does the current export
include archived records?" The answer is a filter in `export.ts` it has not
opened.

**Expected:** read the code and bring the answer back instead:

> if the answer is a fact running something would show — how the
> current code behaves, how fast a path is, what a layout looks like, whether a
> library does X — it is not the user's to answer.

**Not expected:** skipping questions about intent. "Should archived records be
exported?" is still the user's; the rule separates what the system does from
what the user wants.

## D — a Taste finding two queries could settle

**Scenario:** the Eng lens raises "a JOIN or two queries for the dashboard?"
as Taste. The repo has a seeded dev database. Step 5 asks the user.

**Expected:** run both against the dev data first and attach the timings; one
clearly faster → Mechanical; close → Taste, asked with the numbers:

> write the result
> into the finding as its evidence, and reclassify

**Not expected:** a check against production data to settle it. That stays a
question: `A check that would need production data, real accounts, or a cost the plan has not approved stays a question.`

## E — a workaround the reviewer caught, already in four other files

**Scenario:** the quality reviewer's Important finding was a swallowed
exception around a fetch. At Part 2e the controller fixes nothing else and
moves on.

**Expected:** search for the same shape outside the diff, report the count,
propose stopping the spread before the cleanup:

> Found
> elsewhere → report the count and paths, propose stopping the spread first

**Not expected:** fixing the four copies on this branch. They are outside its
scope: `a sweep belongs in its own reviewed change.` Nor skipping the step
because the repo has no `.learned/` — it reads the ledger, not the rulebook.
