# Audit brief — for the next adversarial review of this repo

Dispatch `keel-auditor` and give it this file. It is written to be handed over
unchanged.

The first six audits of this repo were dispatched as `general-purpose`, in a
repo whose F4 rule forbids exactly that. An audit is not a pipeline stage so
the rule did not literally bind it, and it was still the failure mode the rule
describes: the roster had no auditor, so the generic agent got the work — no
pinned model, no restricted tools, no name in the display saying which role was
running, and full write access in a repo it was told not to modify. The only
thing enforcing that instruction was the prompt.

## Why this brief exists

Five audits of this repo returned 4, 15, 14, 15 and 15 findings. That looks
like a defect count and is not: it is roughly what one agent produces in an
hour of mutation testing. Reading a work rate as a defect rate kept the work
open indefinitely.

The number that does converge is **defect classes**. Eight audits have produced eleven. The fifth produced none; the sixth and seventh produced two each and the
eighth one — every one of them in machinery built between audits, which is
where new classes come from. So the brief changed: your job is to find a
class nobody has encoded, not to re-find instances of the eleven below. Instances
are cheap now — they are a missing file in `mutations/`, not a work stream.

## Before you start: get the current state yourself

Do not trust any number written in this repo's prose, including in this file.
Run these:

```bash
bash eval-fixtures/check-structure.sh          # the checks, and how many
bash eval-fixtures/run-mutations.sh            # ~4 min; must end 0 failed
bash tables/render.sh --check                  # generated tables up to date
awk -F'|' '/^\|[[:space:]]*[A-HPVS][0-9]+[[:space:]]*\|/ { total++; c=$(NF-1); gsub(/ /,"",c)
  if (c ~ /check-structure/) s++; else if (c != "—" && c != "") f++ }
  END { printf "%d rules, %d verified, fixture %d script %d\n", total, f+s, f, s }' \
  eval-fixtures/RULE-INVENTORY.md
```

If the first three are not clean before you touch anything, stop and report
that — it is a more interesting finding than anything you were going to look
for.

There is no rule → check-id map in this repo, and you will want one to answer
"can the denominator shrink". Build it from `ok "<id>"` call sites in
`check-structure.sh` and the `Fixture` column of `RULE-INVENTORY.md`; the
absence of that mapping is itself why one check id can silently carry five
rules.

## The known classes

Each has red tests in `eval-fixtures/mutations/`; the `# class:` header names
which. Read three or four of them before you begin.

| class | what it is | example |
|---|---|---|
| `declared-not-wired` | a rule stated in one file with no enforcement point anywhere | a backward route in the router that reached neither README |
| `check-cannot-fail` | a check whose green light certifies nothing | candidates derived from the roster, then asserted to be in the roster |
| `regex-reads-prose` | a pattern asked to judge meaning; wrong in both directions | comma-tolerant window read an endorsement as a prohibition; comma-intolerant read a prohibition as an endorsement |
| `derivation-too-narrow` | a derived set that misses real members, so a declaration looks complete | dispatching stages found by the literal token `dispatch`, missing "Launch four subagents" |
| `present-but-inert` | required text present somewhere unreachable | a rule sentence inside an HTML comment, with the file contradicting it three lines later |
| `self-disarm` | the apparatus switched off from inside its own inputs | emptying `rules/anti-patterns.txt`, which the rule-file validator explicitly skipped |
| `unattributed-red` | a red light taken as proof without establishing what caused it | a mutation that edited the checker's own allowlist, graded as evidence the check enforces the rule |
| `round-trip-laundering` | a provenance stamp wider than what the generator derives | the table generator read prose back out of the document and joined it to the source by position |
| `co-deletion-blind` | every consistency check is an equality, and an equality survives deleting the same member from both sides | a backward route removed from its source and from its independent record together, with every board green |
| `lane-dependent-verdict` | the verdict depends on the execution model, not on the artifact | contamination visible only inside one worker lane: `JOBS=1` said DIRTY, `JOBS=8` said clean |
| `unreconciled-floor` | an inequality against a hand-written reference nobody reconciles with reality | the ratchet's own floor was born one below the real check count, and a whole check could leave the repo with it green |

## What counts as a new class

A finding is a **new class** only if fixing it requires a different *kind* of
countermeasure than the eleven above — not a wider regex, not another derivation
input, not one more validated file. If your fix is "add this string to the
blocklist" or "scan this directory too", it is an instance of an existing
class. Say which one.

Two heuristics that have held so far:

- If you can write the mutation for it and an existing check goes red, it is
  not a finding at all — it is already covered.
- If you can write the mutation and *no* check goes red, ask what the smallest
  fix is. If that fix generalises to a shape not in the table above, it is a
  new class.

## Handling what you find

| what you found | what happens |
|---|---|
| instance of a known class | add a mutation file, fix the check, done. Not a work stream. |
| a check that regressed | the mutation suite should have caught it — say why it did not; that gap is the finding |
| a new class | this is what the brief is for. Name it, characterise it, propose the countermeasure shape. |
| something in the stated boundary below | not a finding. Confirm the boundary is described accurately, or report that it is overstated. |

## The boundary — outside both harnesses, by decision

Stated in `rules/README.md` and `RULE-INVENTORY.md`, and counted as mechanical
coverage nowhere:

1. **A contradiction phrased in a way nobody has written before.**
   `rules/anti-patterns.txt` is a literal blocklist: it catches what has been
   written, not what could be written next.
2. **A row rewritten to mean its opposite** — a gate table row saying the fixer
   may auto-resolve a plan conflict, for instance. Structural checks compare
   identifiers and stages; meaning is not a lexical property.

3. **Any restriction on an agent that holds Bash.** Seven agents declare it in
   frontmatter: the three implementer/fixer agents, which are meant to write,
   and four read-only ones — the three diff reviewers and `keel-auditor` —
   which are not, and which hold it because none of them can do their job
   without running something. Bash writes files. So the restriction is prose,
   and what `reviewer-shell-prose` actually asserts is narrower and wider than
   "the sentence is present": it requires **two independent case-sensitive
   substrings** — `read-only inspection only` and
   `Never write, delete, move, install, push` — anywhere in the file's *live*
   text, with no requirement that they be adjacent or in the same section, and
   with HTML comments and fenced blocks stripped first. Lowercasing one letter
   fails it; a copy inside a comment does not satisfy it; and a paragraph
   underneath announcing that the policy is withdrawn satisfies it completely.
   The seventh audit put the underlying point plainly about itself: removing
   `Edit`/`Write` from a grant that keeps Bash changed which tool name appeared
   in its transcript and nothing else. The one structural gain is real but
   narrow — `write-grant` catches a *declared* `Write` in frontmatter, which is
   a guard against a careless edit, not against an agent that decides
   otherwise.
The first two belong to the scenario fixtures (`NN-*.md`, graded by walkthrough)
and to audits like yours. The third belongs to whoever dispatches you. Reporting that they are uncovered is not a finding. Reporting
that a document *claims* they are covered is.

## Method

Mutation only. Injecting a defect and seeing the board stay green is evidence;
reading code and reasoning about it is a hypothesis. Mark anything you could
not execute as UNVERIFIED and say so plainly.

- run `check-structure.sh` under `/bin/bash` (macOS stock bash 3.2) at least
  once — three earlier defects only appeared there
- the install-drift line fires on any edit under `skills/` or `agents/`; ignore
  it when judging whether your mutation fired
- **Mutate in a throwaway copy, never in the live tree.** `cp -R` the repo to
  a temp directory, or use `eval-fixtures/run-mutations.sh`, which makes one
  for you. An earlier version of this brief said "revert with `git checkout`"
  two lines above the sentence explaining that reverting in the live tree ate
  real edits twice — contradictory advice, and the dangerous half was the
  actionable one.
- `git status --short` in the live tree must be empty when you finish, and your
  report must show it. Never commit, never push.
- **The harness is in scope.** `run-mutations.sh` and its controls, the
  registry, `CHECK-IDS.txt`, the ratchet in `HIGH-WATER.txt` and
  `tables/render.*` are all fair targets — the last two audits found their new
  classes there, not in the pipeline.
- **Verdicts are lane-dependent by construction.** The harness assigns worker
  slots by position in the filtered list modulo `JOBS` (default 8), so
  filtering or renaming a mutation reshuffles every lane. Run anything you
  suspect of cross-mutation interference at `JOBS=1` as well.

## Report

VERDICT, then numbered findings. For each: the exact mutation, the output
before and after, `file:line`, and **which class it belongs to** — including
"new class: <name>" when that is your claim. Rank by class, not by severity:
a new class with one instance matters more than five instances of a known one.

Say explicitly which checks you attacked and could not break. A clean result on
a target is information, and it is the only way this ever ends.
