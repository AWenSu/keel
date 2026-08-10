#!/usr/bin/env bash
# run-mutations.sh — prove that every check in check-structure.sh can fail
#
# Five independent audits found the same thing repeatedly: a check that is
# green but cannot go red. Each audit found it by hand, one mutation at a
# time, and every one of those mutations was then thrown away — so the next
# audit re-found the same class in a different check, and a check that rotted
# between audits stayed green until someone happened to attack it again.
#
# This turns that artisanal activity into a suite. Each file in mutations/
# injects one real defect and names the check id that must go red. The runner
# also asserts COVERAGE: every check id the script emits must be the expected
# failure of at least one mutation. A check with no mutation is a build
# failure — that is the "declared but not wired" rule applied to the checker
# itself, which is the only place it was never applied.
#
#   bash eval-fixtures/run-mutations.sh            # all mutations
#   bash eval-fixtures/run-mutations.sh route      # only ids matching 'route'
#   JOBS=4 bash eval-fixtures/run-mutations.sh     # fewer parallel copies
#
# One full check run costs ~14s, so 54 mutations serially is ~13 minutes. Each
# worker gets its own throwaway copy and runs a slice.
#
# Exit 0 = every mutation went red and every check id is covered.

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
REPO=$(pwd)
FILTER="${1:-}"

command -v git >/dev/null || { echo "FATAL: git required"; exit 2; }
[ -d mutations ] || [ -d eval-fixtures/mutations ] || true
MUT_DIR="eval-fixtures/mutations"
[ -d "$MUT_DIR" ] || { echo "FATAL: no $MUT_DIR"; exit 2; }

# Mutations damage the repo on purpose. They run in a throwaway copy, never in
# the working tree: reverting with `git checkout -- .` in the live tree ate
# real edits twice while this was being built by hand.
WORK=$(mktemp -d "${TMPDIR:-/tmp}/keel-mut.XXXXXX") || exit 2
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT INT TERM
cp -R "$REPO/." "$WORK/keel" || exit 2
cd "$WORK/keel" || exit 2
git rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "FATAL: the copy is not a git repo — cannot revert between mutations"; exit 2; }

# Commit the copy's working state first. Reverting with `git clean -fd` and
# nothing committed deleted mutations/ itself after the first mutation, so the
# loop ran once and reported 25 uncovered checks.
git -c user.email=harness@local -c user.name=harness add -A >/dev/null 2>&1
git -c user.email=harness@local -c user.name=harness commit -q -m "mutation-harness baseline" >/dev/null 2>&1

# The installed-copy check compares against $HOME/.claude. Pointing HOME at an
# empty directory made that check skip itself — and a skipped check never
# appears in the baseline, so the coverage assertion could not see that it had
# no mutation. Give the copy a real install instead.
export HOME="$WORK/home"
mkdir -p "$HOME/.claude/skills" "$HOME/.claude/agents"
cp -R skills/. "$HOME/.claude/skills/"
cp -R agents/. "$HOME/.claude/agents/"

run_checks() { /bin/bash eval-fixtures/check-structure.sh 2>&1 | sed 's/\x1b\[[0-9;]*m//g'; }

verdict_of() {   # verdict_of <id> <output>  ->  PASS | FAIL | ABSENT
  printf '%s\n' "$2" | awk -v id="[$1]" '
    index($0, id) { if ($1 == "PASS" || $1 == "FAIL") { print $1; found = 1; exit } }
    END { if (!found) print "ABSENT" }'
}

baseline=$(run_checks)
base_fail=$(printf '%s\n' "$baseline" | grep -c '^  FAIL')
if [ "$base_fail" -ne 0 ]; then
  echo "FATAL: the unmutated copy already fails $base_fail check(s); fix that first"
  printf '%s\n' "$baseline" | grep '^  FAIL'
  exit 2
fi
ALL_IDS=$(printf '%s\n' "$baseline" | grep -oE '^  PASS  \[[a-z0-9-]+\]' \
          | sed 's/.*\[//; s/\]//' | sort -u)
N_IDS=$(printf '%s\n' "$ALL_IDS" | grep -c .)

printf '\033[1mkeel mutation harness\033[0m  (%s checks, %s mutations)\n\n' \
  "$N_IDS" "$(ls "$MUT_DIR"/*.sh 2>/dev/null | wc -l | tr -d ' ')"

JOBS="${JOBS:-8}"
COVERED=""
MUTS=""
for m in "$MUT_DIR"/*.sh; do
  [ -f "$m" ] || continue
  name=$(basename "$m" .sh)
  expect=$(sed -n 's/^# expect: *//p' "$m" | head -1)
  class=$(sed -n 's/^# class: *//p' "$m" | head -1)
  [ -n "$expect" ] || { echo "FATAL: $name has no \`# expect:\` header"; exit 2; }
  COVERED="$COVERED $expect"
  if [ -n "$FILTER" ]; then
    case "$name$expect$class" in *"$FILTER"*) : ;; *) continue ;; esac
  fi
  MUTS="$MUTS $name"
done
NMUT=$(echo $MUTS | wc -w | tr -d ' ')

worker() {   # worker <slot>: its own copy, its own slice, its own result file
  slot=$1
  dir="$WORK/w$slot"
  cp -R "$WORK/keel" "$dir" || return 2
  cd "$dir" || return 2
  n=0
  for name in $MUTS; do
    n=$((n + 1))
    [ $(( (n - 1) % JOBS )) -eq "$slot" ] || continue
    ( /bin/bash "$MUT_DIR/$name.sh" ) >/dev/null 2>&1
    out=$(run_checks)
    v=$(verdict_of "$(sed -n 's/^# expect: *//p' "$MUT_DIR/$name.sh" | head -1)" "$out")
    git checkout -- . >/dev/null 2>&1
    git clean -fdq >/dev/null 2>&1
    printf '%s\t%s\t%s\n' "$n" "$v" "$name" >> "$WORK/res"
  done
}

printf '  running %s mutations across %s workers…\n\n' "$NMUT" "$JOBS"
: > "$WORK/res"
slot=0
while [ "$slot" -lt "$JOBS" ]; do
  worker "$slot" &
  slot=$((slot + 1))
done
wait

RED=0; GREEN=0
while IFS="$(printf '\t')" read -r idx v name; do
  exp=$(sed -n 's/^# expect: *//p' "$REPO/$MUT_DIR/$name.sh" | head -1)
  case "$v" in
    FAIL)   printf '  \033[32m red \033[0m  %-42s → [%s]\n' "$name" "$exp"; GREEN=$((GREEN+1)) ;;
    PASS)   printf '  \033[31mSTILL GREEN\033[0m  %-34s → [%s] did not fire\n' "$name" "$exp"; RED=$((RED+1)) ;;
    *)      printf '  \033[31mNO SUCH ID \033[0m  %-34s → [%s] never printed\n' "$name" "$exp"; RED=$((RED+1)) ;;
  esac
done < <(sort -n "$WORK/res")

SKIP=0

# COVERAGE — the assertion that makes this more than a pile of tests
printf '\n\033[1mcoverage\033[0m\n'
uncovered=""
for id in $ALL_IDS; do
  case " $COVERED " in *" $id "*) : ;; *) uncovered="$uncovered $id" ;; esac
done
if [ -z "$uncovered" ]; then
  printf '  \033[32mPASS\033[0m  all %s checks have at least one mutation proving they can fail\n' "$N_IDS"
else
  printf '  \033[31mFAIL\033[0m  checks with no mutation (a green light nothing has ever tested):\n'
  for u in $uncovered; do printf '           %s\n' "$u"; done
  RED=$((RED+1))
fi

printf '\n\033[1m%d mutations went red, %d failed to, %d skipped\033[0m\n' "$GREEN" "$RED" "$SKIP"
[ "$RED" -eq 0 ] || exit 1
