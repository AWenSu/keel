# mutations/ — one real defect per file

Each `*.sh` damages the repo in one specific way and declares, in its header,
the check id that must go red. `run-mutations.sh` applies it in a throwaway
copy, runs `check-structure.sh`, asserts that check reports FAIL, and reverts.

```sh
# expect: <check id, as printed in the [brackets] of a PASS/FAIL line>
# class:  <defect class this belongs to>
# origin: <where it came from — gate-3, self-audit, …>
```

Every mutation here is a defect that was **actually live in this repo**, or
that an audit demonstrated could be made live with the board green. None are
hypothetical.

## The eleven defect classes

| class | what it is |
|---|---|
| `declared-not-wired` | a rule stated in one file with no enforcement point |
| `check-cannot-fail` | a check whose green light certifies nothing |
| `regex-reads-prose` | a pattern asked to judge meaning; fails in both directions |
| `derivation-too-narrow` | a derived set that misses real members, so a declaration looks complete |
| `present-but-inert` | required text present somewhere unreachable — a comment, a fence, a decoy block |
| `self-disarm` | the checking apparatus turned off from inside its own inputs |
| `unattributed-red` | a check goes red and that is taken as proof it enforces the property — without establishing the red was caused by the injected defect. The first class about a **false red**; the other seven are about false greens |
| `round-trip-laundering` | a block carries a whole-block provenance stamp while the generator produces some cells by reading them out of the document and writing them back. For those cells the freshness check is a tautology |
| `co-deletion-blind` | every consistency check is an equality between two sets, and an equality survives deleting the same member from both sides. The apparatus detects divergence and is blind to shrinkage |
| `lane-dependent-verdict` | correctness depends on the execution model — worker lane, `JOBS`, filename order — rather than on the artifact under test |
| `unreconciled-floor` | a guard expressed as an inequality against a hand-written reference, where nothing compares the reference to the quantity it bounds. Created by a correct change, not a defective edit, which is why mutation alone does not surface it |

## Adding a check

Add its mutation in the same change. The coverage assertion fails otherwise —
that is the point: it is the "declared but not wired" rule applied to the
checker itself, the one place it was never applied.
