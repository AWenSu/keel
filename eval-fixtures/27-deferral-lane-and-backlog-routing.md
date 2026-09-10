# Fixture 27: where a deferral lands, and what it must point at (D18)

**Rule source:** `skills/keel-finish/SKILL.md` Part 2b: Open-items reconciliation.

The Part 2e half of D18 — an unfixed problem is work, not a rule — is
scenario J of fixture `26`; this fixture pins the Part 2b half: which lane a
deferral takes, what the disposition must cite, and what happens when the
citation resolves to nothing.

## A — with a `.learned/`, a deferred problem becomes a backlog item

**Scenario:** Part 2b's reconciled list has one item: a `DONE_WITH_CONCERNS`
flag about a retry path, confirmed real, agreed with the user to fix next
round. The repo has a `.learned/`.

**Expected:** the deferral goes through the backlog, and the disposition
names the file that now exists:

> With a `.learned/`
> (`python3 ~/.claude/skills/learned/scripts/learned.py root`), a confirmed
> problem deferred to a later round goes to
> `learned.py backlog add <H|M|L> <狀態> <slug> "<中文>"`

**Why the backlog and not a TODO line** — the lane is not a style choice:

> the backlog carries
> priority, an overdue hook, and a close discipline (`--rule <ID>` or a stated
> reason) that a TODO line cannot enforce

**Not expected:** writing it to `TODOS.md` anyway because that is the older
habit; a disposition that says "deferred to backlog" without naming the
created file.

## B — without a `.learned/`, `TODOS.md` with a line number, as before

**Scenario:** same item, but the repo has no `.learned/`.

**Expected:**

> Without one, `TODOS.md` with a line number, as
> before.

**Not expected:** running `learned.py init` uninvited to make lane A
available — Part 2e owns that one-line offer; Part 2b takes the repo as it
finds it.

## C — a deferral pointing at nothing blocks

**Scenario:** the final summary claims an item was "deferred to backlog",
but no backlog file exists (the `backlog add` was never run, or failed
silently).

**Expected:** blocked, by the disposition rule itself:

> Either way the reference must resolve: a deferral pointing at
> nothing is the "neither" case and blocks.

which lands it back in the base rule:

> Every item gets one of two dispositions: **resolved** (with the evidence) or
> **explicitly deferred**. **An item with neither blocks completion.**

**Not expected:** treating the sentence "deferred to backlog" as the
deferral. The artifact is the deferral; the sentence is a claim about it,
and here the claim fails verification like any other claim in this stage.

## D — the reconciliation still pulls all three sources first

**Scenario:** the plan's REVIEW REPORT has an unresolved decision, `TODOS.md`
has two review-era entries, and the ledger has one `DONE_WITH_CONCERNS` —
and the controller is tempted to reconcile only the ledger because "that is
where execution problems live".

**Expected:** one list from all three, before any lane question arises:

> Loose ends live in three places that never talk to each other. Pull all three
> into ONE list before integrating, because a decision that exists in only one of
> them is a decision nobody will find again

Lane choice (A/B above) is per-item and comes after the list is complete.

**Not expected:** reconciling one source; presenting no list because
everything looks clean —

> "nothing outstanding" is a claim, and like
> every other claim here it needs to show its work.

## Not expected (any scenario)

- A deferral whose cited file or line does not exist
- `TODOS.md` used in a repo that has a `.learned/`, or `learned.py init` run
  uninvited in one that does not
- An item with neither a resolution nor a resolvable deferral passing Part 2b
- The lane decision made before the three-source list is assembled
