#!/usr/bin/env bash
# render.sh — regenerate the structural columns of the three duplicated tables
#
# The agent roster, the gate list and the backward routes each appear in three
# documents. Five audits produced six separate defects in the checks that tried
# to keep those copies honest: a sorted multiset that missed a swap, a `<prose>`
# slot that absorbed any number of rows, a gate deleted from all three at once,
# a model column read from the wrong cell. Verification kept losing to
# duplication, so the duplication is what changed.
#
# What is generated: the KEY and STRUCTURAL columns — which rows exist, in what
# order, the agent name, the gate id, the stage each belongs to, the route's
# from/to, and the model (read from the agent's own frontmatter, never typed).
#
# What is NOT generated: the prose. No description in the three documents is
# the same — keel-workflow's roster is terse because a router reads it, the
# READMEs' is written for a person, and the Chinese one is not a translation.
# Generating those would mean moving three sets of prose into a TSV, which is
# worse writing for no gain: nothing ever checked them and nothing should.
# Existing prose is read back out of the document and re-emitted unchanged.
#
#   bash tables/render.sh           # rewrite the generated blocks in place
#   bash tables/render.sh --check   # exit 1 if any block is out of date
#
# Editing: change tables/*.tsv (or an agent's frontmatter), run this, commit
# both. Adding a row also needs its prose written into each document by hand —
# render leaves a TODO cell so the omission is loud.

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2

MODE="${1:-write}"
AWK="$(dirname "${BASH_SOURCE[0]}")/render.awk"
[ -f "$AWK" ] || { echo "FATAL: missing $AWK"; exit 2; }

# doc-key must match the column suffixes in the tsv headers
BLOCKS="
skills/keel-workflow/SKILL.md:roster:workflow
README.md:roster:readme_en
README.zh-TW.md:roster:readme_zh
skills/keel-workflow/SKILL.md:gates:workflow
README.md:gates:readme_en
README.zh-TW.md:gates:readme_zh
skills/keel-workflow/SKILL.md:routes:workflow
README.md:routes:readme_en
README.zh-TW.md:routes:readme_zh
"

# model pins, read from the agents themselves
models=$(for a in agents/*.md; do
  n=$(basename "$a" .md)
  m=$(awk 'NR==1 { if ($0 != "---") exit; next } /^---$/ { exit } /^model:/ { sub(/^model: */, ""); print; exit }' "$a")
  printf '%s\t%s\n' "$n" "$m"
done)

# Preconditions. Without these the generator is its own blind spot: a new
# agent that nobody added to agents.tsv would render a roster missing it, and
# the roster would match its source exactly.
fatal=""
have=$(ls agents/*.md | xargs -n1 basename | sed 's/\.md$//' | sort)
want=$(grep -v '^#' tables/agents.tsv | grep -v '^[[:space:]]*$' | cut -f1 | sort)
[ "$have" = "$want" ] || fatal="$fatal agents.tsv-vs-agents/($(diff <(echo "$want") <(echo "$have") | tr -d '\n' | cut -c1-80))"
# gates and routes have no directory to compare against; RULE-INVENTORY's A and
# B sections are their independent record, and were already the cross-check
# before these tables were generated
inv_a=$(grep -cE '^\| A[0-9]+ \|' eval-fixtures/RULE-INVENTORY.md)
inv_b=$(grep -cE '^\| B[0-9]+ \|' eval-fixtures/RULE-INVENTORY.md)
n_routes=$(grep -cv '^#' tables/routes.tsv)
n_gates=$(grep -cv '^#' tables/gates.tsv)
[ "$n_routes" = "$inv_a" ] || fatal="$fatal routes.tsv=$n_routes-vs-RULE-INVENTORY-A=$inv_a"
[ "$n_gates" = "$inv_b" ] || fatal="$fatal gates.tsv=$n_gates-vs-RULE-INVENTORY-B=$inv_b"
if [ -n "$fatal" ]; then
  echo "FATAL: table source is out of step with the repo →$fatal"
  exit 2
fi

rc=0
stale=""
rendered=0
declared=$(printf '%s\n' "$BLOCKS" | grep -c .)
for spec in $BLOCKS; do
  doc=${spec%%:*}; rest=${spec#*:}; table=${rest%%:*}; key=${rest#*:}
  case "$table" in
    roster) tsv=tables/agents.tsv ;;
    gates)  tsv=tables/gates.tsv ;;
    routes) tsv=tables/routes.tsv ;;
  esac
  out=$(printf '%s\n' "$models" \
        | awk -v TABLE="$table" -v DOCKEY="$key" -v TSV="$tsv" -v DOC="$doc" -f "$AWK" "$doc")
  arc=$?
  if [ "$arc" -ne 0 ] || [ -z "$out" ]; then
    echo "FATAL: render failed for $doc:$table (awk exit $arc)"; exit 2
  fi
  rendered=$((rendered + 1))
  if [ "$MODE" = "--check" ]; then
    printf '%s\n' "$out" | cmp -s - "$doc" || { stale="$stale $doc:$table"; rc=1; }
  else
    printf '%s\n' "$out" > "$doc.tmp" && mv "$doc.tmp" "$doc"
  fi
done

# The success line used to say "9" as a string literal while the loop could
# have located zero blocks: one space in front of a marker made render an
# identity function and cmp reported the document up to date.
if [ "$rendered" -ne "$declared" ]; then
  echo "FATAL: rendered $rendered of $declared declared blocks"; exit 2
fi

if [ "$MODE" = "--check" ]; then
  if [ "$rc" -eq 0 ]; then
    echo "all $rendered generated blocks are up to date"
  else
    echo "stale generated blocks →$stale"
    echo "run: bash tables/render.sh"
  fi
else
  echo "rendered $rendered blocks from tables/*.tsv"
fi
exit "$rc"
