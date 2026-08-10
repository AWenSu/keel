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

## The eight defect classes

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

## Adding a check

Add its mutation in the same change. The coverage assertion fails otherwise —
that is the point: it is the "declared but not wired" rule applied to the
checker itself, the one place it was never applied.
