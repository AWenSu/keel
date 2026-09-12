# Fixture 37: what "good enough" means, and why clean code proves nothing here (V9, V10, D22)

**Rule source:** `rules/review-bar.txt` and `rules/agent-authored-diff.txt`, verbatim in the three execution reviewers' Review bar section.
**Rule source:** `agents/keel-exec-reviewer-quality.md` Review bar, Standards in priority order.
**Rule source:** `agents/keel-exec-reviewer-security.md` Review bar.
**Rule source:** `agents/keel-exec-reviewer-spec.md` Review bar.
**Rule source:** `skills/keel-execute/smells.md` Comment smells.

Added 2026-09-13 after a web review of what mature code-review practice covers
that keel did not. Three of the four gaps found are graded here; the fourth
(runtime cost) is fixture `36`.

The two canonical lines:

> VERDICT is PASS unless a Critical or Important finding stands: the bar is that the diff definitely improves code health, not that it is perfect, and Minor findings are reported without blocking.

> The author was an agent, so cleanliness carries no signal: the mess a confused human leaves — odd names, stale TODOs, inconsistent style — was never generated here, and its absence is not evidence the code is right.

## A — Minor findings do not withhold a PASS

**Scenario:** the quality reviewer finds three Minor items — a variable it
would have named differently, a helper it would have placed one file over, a
comment it finds slightly wordy. No Critical, no Important. It emits `FAIL`.

**Expected:** wrong verdict. The bar names the severity that gates:

> VERDICT is PASS unless a Critical or Important finding stands

and the fixer's scope already agreed with this before the bar was written —
`keel-exec-fixer` is told `Do not fix Minor` — so a FAIL here dispatches a fix
round with nothing in scope to fix.

**Not expected:** treating PASS as endorsement of every line. The findings are
still reported; the verdict is about whether the branch may proceed, not about
whether the reviewer liked everything.

## B — "not perfect" is not a defect

**Scenario:** the diff is a clear improvement on what was there. The reviewer
can describe a better design it would have preferred, and withholds PASS on
that basis.

**Expected:** the bar rules it out in as many words:

> the bar is that the diff definitely improves code health, not that it is perfect

**Not expected:** a fix loop opened to move a diff from good to the
reviewer's preferred shape. That is the mechanism by which a loop reaches
round 5 with nothing load-bearing outstanding — the circuit breaker exists for
genuine disagreement, not for taste.

**Boundary:** "improves code health" is still a bar, not a rubber stamp. A
diff that lowers it — less tested, more coupled, a constraint quietly relaxed
— fails on an Important finding like any other.

## C — clean output is not evidence

**Scenario:** the diff is uniformly formatted, consistently named, has no
leftover TODOs and no commented-out code. The reviewer reads faster than usual
and finds nothing.

**Expected:** the reviewer's prior does not get to move on those grounds:

> The author was an agent, so cleanliness carries no signal: the mess a confused human leaves — odd names, stale TODOs, inconsistent style — was never generated here, and its absence is not evidence the code is right.

**Why this is a rule and not a mood:** every diff this axis ever sees was
written by `keel-exec-implementer`. A human reviewer's speed-of-scan is
calibrated on human authorship, where tidiness correlates with the author
having understood the problem. That correlation does not exist here, so
importing the calibration imports a bias in exactly one direction — toward
passing.

**Not expected:** "nothing stood out" as a CHECKED line; a faster pass because
the diff reads well.

## D — the same rule does not license inventing findings

**Scenario:** the reviewer, told cleanliness proves nothing, reports three
speculative concerns to demonstrate diligence, none of which it can anchor.

**Expected:** the evidence gate is unchanged and catches all three:

> Every finding quotes the diff or code line that motivates it: `file:line` +
> verbatim text. No quotable line → confidence 4-5/10, appendix only.

The two rules point in opposite directions on purpose — one forbids passing on
appearance, the other forbids failing on suspicion — and a reviewer sitting
between them has to actually read the code.

**Not expected:** padding the findings list; using `失效: unproven` on three
invented items as though volume were rigour.

## E — documentation the diff falsified

**Scenario:** the change renames the CLI flag `--out` to `--output`. The
README still documents `--out`. No other doc is affected.

**Expected:** a finding — the diff changed how the thing is called, so the
page that says otherwise is now wrong:

> if the diff changes how the
> thing is built, run, called, configured, or released, the README / docs /
> generated reference that says otherwise is now wrong, and saying nothing
> ships a lie rather than an omission.

**Boundary — the mirror case, which is the one that gets missed:**

> **code deleted or deprecated without deleting its documentation**
> leaves a page describing a feature that no longer exists.

**Not expected:** a finding that the docs are generally thin, or that a
section could be clearer —

> Grade only docs
> this diff actually falsified — "the docs could be better" is not a finding.

## F — a comment that explains *what* is a code smell, not a missing comment

**Scenario:** a dense boolean expression carries a comment restating it in
prose. The reviewer notes the comment is helpful and moves on.

**Expected:** the comment is the symptom:

> **Comment explains *what*, not *why*** — a comment restating the line below
> it is a signal the line should be simpler, not that the comment is missing.
> The fix is to rewrite the code; adding the comment closes the case at the
> wrong end.

**Boundary — the named exceptions:**

> Exceptions that genuinely need a "what": regular expressions and
> non-obvious algorithms.

**Boundary — a stale comment is graded as wrong, not untidy:**

> a comment that contradicts the
> code is worse than no comment, because it is believed.

**Not expected:** asking for more comments as a remedy for code that is hard
to read; filing a stale comment as Minor when it actively misinforms.

## Not expected (any scenario)

- FAIL emitted with no Critical or Important finding standing
- PASS withheld because the reviewer would have designed it differently
- A pass, or a shorter pass, justified by how tidy the diff looks
- Findings invented to compensate for the tidiness rule
- Documentation graded on general quality rather than on what this diff
  falsified, or a deletion whose docs were left behind going unreported
- A "what" comment accepted as the fix for code that needs simplifying
