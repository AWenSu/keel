# tables/ — the source of the three tables that appear in three documents each

The agent roster, the gate list and the backward routes are each written into
`skills/keel-workflow/SKILL.md`, `README.md` and `README.zh-TW.md`. Nine copies
of three tables.

Six checks used to keep those copies honest. Five independent audits found six
separate defects **in those six checks**:

| defect | found by |
|---|---|
| destinations compared as a sorted multiset, so swapping two rows was invisible | gate 4 |
| `<prose>` treated as a wildcard, absorbing any number of rows | gate 4 |
| a route deleted from all three documents at once | gate 5 |
| a gate deleted from all three documents at once | gate 5 |
| the model column read from the first model word anywhere in the row | gate 5 |
| a route added to the source of truth and to neither README | gate 3 |

Every one of those is a duplication problem wearing a verification costume. So
the duplication went away instead.

## What is generated

The **key and structural columns**: which rows exist, in what order, the agent
name, the gate id, the stage each belongs to, a route's from and to, and the
model — read from `agents/<name>.md` frontmatter, never typed anywhere else.

## What is not generated

Nothing inside the markers. Every cell of every generated block comes from a
tsv or from an agent's frontmatter.

The first version left the prose in the documents and read it back out,
joining it to the source rows by position — so inserting a route in the middle
of `routes.tsv`, exactly as the instructions below said to, re-paired five
triggers with the wrong `from`/`to`, wrote that into all three documents, and
`--check` reported them up to date. The block's provenance stamp was wider
than what the generator actually derived.

The objection to putting prose in a tsv was that it makes the text harder to
write. It does not — every cell of a markdown table is one line already. That
aesthetic call cost correctness and is reversed.

Historical note on why the prose is per-document rather than shared:
`keel-workflow`'s roster is terse because a router reads it under a context
budget, the READMEs' is written for a person deciding whether to install this,
and the Chinese one is not a translation of either. All three live in the tsv,
one column per document.

## Editing

| change | do this |
|---|---|
| an agent's model | edit `agents/<name>.md` frontmatter, run `render.sh` |
| a new agent | write `agents/<name>.md`, add a row to `agents.tsv`, fill its role/tools columns in `agents.tsv`, run `render.sh` |
| a new gate or route | add the row to `gates.tsv` / `routes.tsv` **and** to `RULE-INVENTORY.md` section A or B — `render.sh` refuses to run if those disagree |
| any table's wording | edit the tsv column for that document, run `render.sh` |

```bash
bash tables/render.sh           # rewrite the nine generated blocks
bash tables/render.sh --check   # exit 1 if any is stale (this is what CI runs)
```

## The generator's own blind spots, and what covers them

A generator can be complete and still be wrong about its inputs, so
`render.sh` refuses to run when:

- `agents.tsv` and `agents/*.md` name different sets — otherwise a new agent
  nobody added to the tsv renders a roster that is missing it, and that roster
  matches its source exactly
- `routes.tsv` or `gates.tsv` has a different row count from `RULE-INVENTORY`
  sections A and B, which were the independent record before these tables were
  generated and remain so
- a declared block was not found in its document: one space in front of an
  opening marker used to make `render.sh` a byte-exact identity function, and
  `cmp` then reported the untouched document up to date. The success line said
  "9" as a string literal while zero blocks had been located.

Mutations `07`, `42`–`52`, `56`, `57` and `61`–`64` in
`eval-fixtures/mutations/` are the red tests for all of the above.
