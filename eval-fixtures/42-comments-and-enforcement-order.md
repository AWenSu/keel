# Fixture 42: new comments need a reason; a lesson is enforced before it is written down (D29, D30)

**Rule source:** `skills/keel-execute/smells.md` Comment smells.
**Rule source:** `agents/keel-exec-implementer.md` Standards you write to.
**Rule source:** `skills/keel-finish/SKILL.md` Part 2e step 2a.

Added 2026-10-04 after Lauren Tan's Cursor Compile talk: agents cited the
comments around a workaround as the reason not to fix it, the habit spread
through the codebase in days, and her framework banned comments outright.
keel already graded "what" comments and stale comments; it did not grade the
comment that excuses a band-aid, and it let every lesson become a prose rule
first.

## A — a new narration comment in a comment-heavy repo

**Scenario:** the repo's existing files carry a comment above nearly every
function. The implementer adds a new function with a matching
`// Loops over the orders and sums the totals` line. The quality reviewer
lets it pass because it matches the surrounding convention.

**Expected:** a finding. The comment rule names this case and overrides the
"match the repo" instinct for comments the diff adds:

> This holds even in a repo full of
> comments: agents copy the patterns they read, so a comment habit spreads the way
> a workaround does, and the diff is graded on what it adds, not on matching the
> volume around it.

**Not expected:** the reviewer flagging the repo's *existing* comments, or the
fixer deleting them. The same paragraph closes with
`Comments the diff did not touch are out of scope.`

## B — a comment that excuses the band-aid

**Scenario:** the diff wraps a crash in a null check and adds
`// TODO: real fix needs the cache rewrite, fine for now`. The reviewer files
a Minor finding: "reword the comment".

**Expected:** an Important-or-higher finding about the workaround itself:

> Grade it as an **unfixed problem, not a comment**: the
> comment is how the band-aid passed review, and the next agent will read it as
> permission to add another. The finding is the workaround; deleting the
> comment alone does not close it.

**Not expected:** a fix round that deletes the comment and reports the finding
closed. The null check is still there.

## C — the implementer is told before it writes

**Scenario:** an implementer brief carries the smells path; the implementer
adds three explanatory comments, then the quality reviewer flags all three.

**Expected:** the implementer's own file already said not to:

> **Default to writing no comments.**

so the round was avoidable, which is the reason D23 puts the standards in the
author's brief at all.

## D — a lesson that a lint rule could carry

**Scenario:** at keel-finish Part 2e a survivor reads "agents keep importing
the main-process module from renderer code". The repo has ESLint configured.
The controller writes it straight into the rulebook as a new rule.

**Expected:** the controller first proposes the lint rule:

> Before writing any survivor as a rule, try to make it impossible
> instead.

and with ESLint in reach, `no-restricted-imports` is (b) in the order the step
names. The rule is written only as a pointer to that change until it lands.

**Not expected:** skipping the rulebook entirely because a lint rule *could*
exist. Until it lands, the pointer is what the next brief carries; and a
lesson neither the code nor a check can enforce still becomes a rule on its
own.
