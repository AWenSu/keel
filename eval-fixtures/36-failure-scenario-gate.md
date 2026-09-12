# Fixture 36: a finding names the failure, not just the line (V8, D21)

**Rule source:** `rules/failure-scenario.txt`, appearing verbatim in the three execution reviewers and `skills/keel-execute/SKILL.md`.
**Rule source:** `agents/keel-exec-reviewer-quality.md` Evidence gate, Read the tests first, Output.
**Rule source:** `agents/keel-exec-reviewer-security.md` Evidence gate, Output.
**Rule source:** `agents/keel-exec-reviewer-spec.md` Evidence gate, Read the tests first, Output.
**Rule source:** `skills/keel-execute/smells.md` Runtime cost smells.

Ported 2026-09-13 from the built-in `/code-review`, whose findings contract
makes a concrete failure scenario a **required** field, and from a
locally-installed `code-reviewer` agent outside this repo, whose performance
dimension covered ground `smells.md` did not. keel's evidence gate already required a quoted line; a
quoted line proves the code *says* something, not that saying it is *wrong* —
the same gap fixture `29` scenario G pins for plan-review skeptics, which the
execution reviewers had no equivalent of.

The canonical line, carried verbatim by all four files:

> Name the failure, not just the line: concrete inputs or state, and the wrong output, crash, or missed requirement they produce. Cannot name one → capped at confidence 5.

## A — a real quote under a finding that cannot fail

**Scenario:** the quality reviewer flags `svc/cart.py:88` — a `for` loop that
recomputes a total each iteration. The line is quoted correctly. Asked what
goes wrong, the answer is "it is inefficient".

**Expected:** capped at confidence 5 by the rule above, because no input or
state was named at which the inefficiency produces a wrong or unacceptable
result. The `失效:` field reads `unproven`, which is a legitimate entry:

> 失效: <concrete inputs/state → the wrong output it produces; "unproven" if you could not name one>

and the smells file says the same thing for this exact shape:

> "This is O(n²)" with
> no statement of what n is in this system is a shape observation, not a
> finding.

**Not expected:** dropping the finding (an unproven suspicion is still worth
reporting — silently discarding it is what fixture `29` scenario D forbids);
or promoting it to Critical on the strength of the quote alone.

## B — the same shape, with the failure named

**Scenario:** same line, but the reviewer states: a cart with 500 line items
(the plan's own Global Constraints allow 1000) recomputes 500 times inside a
request whose budget is 200ms, measured at 1.4s.

**Expected:** the `失效:` field carries that, and the confidence cap does not
apply. This is the difference the rule exists to make visible — same line,
same reviewer, different evidentiary weight.

**Not expected:** treating A and B as the same finding because they cite the
same `file:line`.

## C — the spec axis names a missed requirement, not a crash

**Scenario:** the spec reviewer finds task 4's `Delivers:` promises "rejects
an expired token" and the diff has no expiry branch.

**Expected:** the failure half is satisfied by the third alternative in the
rule — "missed requirement" — not by inventing a crash:

> the wrong output, crash, or missed requirement they produce

An expired token being accepted **is** the concrete state and the wrong
output; no runtime failure needs to be constructed.

**Not expected:** the spec axis reporting `失效: unproven` because nothing
throws. The axis's own subject is compliance, and non-compliance is a
nameable failure.

## D — tests are read before the implementation

**Scenario:** the reviewer opens the diff, reads the implementation, forms a
view, then reads the tests and finds they agree with it.

**Expected:** the order is the rule, and the reason is stated:

> **Read the tests first.** They state what the author believed the change
> should do; reading them before the implementation is how you notice the
> belief is wrong, rather than absorbing it and grading the code against it.

**Not expected:** treating "the tests agree with the code" as corroboration
when the code was read first — that agreement is the expected outcome of
having anchored on the implementation, so it carries no information.

## E — runtime cost smells are gradeable, not automatic

**Scenario:** a query sits inside a loop over a fixed three-entry
configuration list.

**Expected:** not an N+1. The entry is written to be graded, not
pattern-matched:

> **N+1** — a query inside a loop over rows another query returned. Grade by
> what the loop is over: a fixed-size config list is not an N+1, a user's
> orders is.

**Boundary — a list endpoint with no pagination:** that *is* the smell, and
is not answerable as a product decision:

> Missing pagination on a collection that grows is this smell, not a feature
> request.

**Not expected:** flagging every loop containing a call; deferring an
unbounded collection read to the backlog as scope.

## F — the axes stay separate

**Scenario:** the quality reviewer, now equipped with the runtime-cost list,
notices the slow path is also missing an authorization check.

**Expected:** it reports the cost finding on its own axis and does not grade
the authorization gap — that belongs to the security axis, and the axes are
never merged:

> **Never merge or rerank across the other axes** — each
> axis reports its own findings and its own worst issue, with no single winner.

**Not expected:** one reviewer producing a combined verdict because it can
see both problems. That is what the built-in `code-reviewer` agent does by
design (five dimensions, one APPROVE/REQUEST CHANGES verdict) and is
precisely the property keel did **not** port.

## Not expected (any scenario)

- A finding above confidence 5 whose `失效:` field is `unproven`
- `失效: unproven` used as a reason to delete a finding rather than to cap it
- A performance claim with no statement of the input size at which it bites
- The implementation read before the tests
- Any reviewer merging axes, or emitting a single cross-axis verdict
