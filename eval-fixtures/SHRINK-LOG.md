# Deliberate removals

The ratchet in `check-structure.sh` compares every countable dimension of this
repo against **the previous commit**, as a set. Anything present at `HEAD` and
absent now must be named here, or the check fails.

Format, one per line:

```
shrink: <dimension> <member> <why> <YYYY-MM-DD>
```

`<dimension>` is one of: check-ids, rule-ids, mutations, rule-files, manifest,
anti-patterns, routes, gates, agents, fixtures, skills.

An entry authorises exactly one member of one dimension. It stops being load
bearing the moment the removal is committed — after that the member is absent
from `HEAD` too, and the ratchet no longer looks for it. Old entries stay as
the record of what was deliberately dropped and why.

## Why the previous design failed

The first version was `eval-fixtures/HIGH-WATER.txt`: hand-written floors,
compared as totals. The eighth audit found it was **born one below the real
check count** and had never been reconciled; that a whole check could leave
the repo with the board green; that swapping a real row for a placeholder kept
the total intact; that three countable dimensions had no floor at all; and
that the `shrink:` line it asked for was validated for nothing — a line
reading `shrink: banana because Tuesday 1999-01-01` satisfied it while two
floors were lowered and two fixtures deleted.

The defect class is `unreconciled-floor`: a guard expressed as an inequality
against a hand-written reference that nothing compares to the quantity it
bounds. The fix is not a bigger table — it is taking the reference out of the
working tree, where the edit under audit cannot reach it.

## Entries
