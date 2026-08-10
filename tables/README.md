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

The **prose**. No description is shared between the three documents:
`keel-workflow`'s roster is terse because a router reads it under a context
budget, the READMEs' is written for a person deciding whether to install this,
and the Chinese one is not a translation of either. Moving three sets of prose
into a TSV would be worse writing to no purpose — nothing ever verified those
descriptions and nothing should. `render.sh` reads the existing prose back out
of each document and re-emits it unchanged.

## Editing

| change | do this |
|---|---|
| an agent's model | edit `agents/<name>.md` frontmatter, run `render.sh` |
| a new agent | write `agents/<name>.md`, add a row to `agents.tsv`, run `render.sh`, then replace the `TODO:` cells with real prose in each document |
| a new gate or route | add the row to `gates.tsv` / `routes.tsv` **and** to `RULE-INVENTORY.md` section A or B — `render.sh` refuses to run if those disagree — then fill the `TODO:` cells |
| any table's wording | edit the document; prose is yours, structure is not |

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

Mutations `07`, `42`–`52`, `56` and `57` in `eval-fixtures/mutations/` are the
red tests for all of the above.
