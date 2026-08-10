# Audit brief — for the next adversarial review of this repo

Paste this to an independent agent. It is written to be handed over unchanged.

## Why this brief exists

Five audits of this repo returned 4, 15, 14, 15 and 15 findings. That looks
like a defect count and is not: it is roughly what one agent produces in an
hour of mutation testing. Reading a work rate as a defect rate kept the work
open indefinitely.

The number that does converge is **defect classes**. Five audits produced six,
and the fifth produced no new one. So the brief changed: your job is to find a
class nobody has encoded, not to re-find instances of the six below. Instances
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

## The six known classes

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

## What counts as a new class

A finding is a **new class** only if fixing it requires a different *kind* of
countermeasure than the six above — not a wider regex, not another derivation
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

Both belong to the scenario fixtures (`NN-*.md`, graded by walkthrough) and to
audits like yours. Reporting that they are uncovered is not a finding. Reporting
that a document *claims* they are covered is.

## Method

Mutation only. Injecting a defect and seeing the board stay green is evidence;
reading code and reasoning about it is a hypothesis. Mark anything you could
not execute as UNVERIFIED and say so plainly.

- run `check-structure.sh` under `/bin/bash` (macOS stock bash 3.2) at least
  once — three earlier defects only appeared there
- the install-drift line fires on any edit under `skills/` or `agents/`; ignore
  it when judging whether your mutation fired
- revert with `git checkout`, and confirm `git status --short` is empty before
  you finish. Never commit, never push, never leave the tree dirty.
- `eval-fixtures/run-mutations.sh` is the safe way to run many mutations: it
  works in a throwaway copy. Reverting in the live tree ate real edits twice
  while this repo was being built.

## Report

VERDICT, then numbered findings. For each: the exact mutation, the output
before and after, `file:line`, and **which class it belongs to** — including
"new class: <name>" when that is your claim. Rank by class, not by severity:
a new class with one instance matters more than five instances of a known one.

Say explicitly which checks you attacked and could not break. A clean result on
a target is information, and it is the only way this ever ends.
