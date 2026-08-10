# rules/ — the canonical text of every rule a script can check

Each `*.txt` here is the single source for one rule. Files that must state
that rule carry the sentence **verbatim**, and `check-structure.sh` compares
bytes (`grep -F`), never patterns.

## Why bytes and not patterns

Four independent audits found the same defect class in this repo, and every
instance of it lived in a check that tried to read prose with a regex:

- allow a comma in the window and "When no keel agent fits, just dispatch a
  general-purpose agent" reads as a prohibition;
- forbid the comma and "Do not dispatch, under any circumstances, a
  general-purpose agent" reads as an endorsement.

A checker that fails when the rule is stated *correctly* is worse than no
checker, because it gets switched off. There is no correct regex here — the
question "is this sentence forbidding or recommending?" is not a lexical
question. So the rule text stopped being prose to be parsed and became a
constant to be compared.

## What this buys, exactly

| Change to a rule | Result |
|---|---|
| Sentence deleted from a file that owes it | FAIL |
| Sentence paraphrased in one file | FAIL (that is the point: edit `rules/`, then every copy) |
| A new stage starts dispatching without carrying the rule | FAIL — the derivation below finds the stage, and the manifest does not list it |
| A known anti-pattern added anywhere | FAIL (`anti-patterns.txt`, literal match) |
| **A novel sentence contradicting a rule** | **not detected** — see the boundary below |

## The boundary, stated rather than implied

Two things here are deliberately out of reach:

1. **A contradiction phrased in a way nobody has seen before.**
   `anti-patterns.txt` is a blocklist of literal strings. It catches what has
   been written before, not what could be written next.
2. **A rule row rewritten to mean its opposite** (e.g. a gate table row that
   says the fixer may auto-resolve a plan conflict). Structural checks compare
   identifiers and stages, not meaning.

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
The first two are covered — where they are covered at all — by the scenario fixtures
in `eval-fixtures/`, graded by walkthrough, and by periodic adversarial audit.
The third is covered by nothing mechanical at all: it is a property of whoever
dispatches the agent. None of the three is claimed as mechanical coverage in
`RULE-INVENTORY.md`.

## Files

- `<rule>.txt` — the canonical sentence, exactly as it must appear.
- `manifest.tsv` — which files owe which rule, and which derivation
  cross-checks that list, so the manifest cannot silently go stale.
- `anti-patterns.txt` — literal strings that must appear nowhere.

## Editing a rule

1. Edit `rules/<rule>.txt`.
2. Run `bash eval-fixtures/check-structure.sh` — every file that owes the rule
   now fails.
3. Paste the new sentence into each of them.

Three steps, mechanically enforced. The old failure mode — changing the rule
in one document and discovering the other two a month later — is not
reachable from here.
