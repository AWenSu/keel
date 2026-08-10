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
# One full check run costs ~14s, so the full suite serially would be ~15 minutes. Each
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
BASE_HOME="$WORK/home"
mkdir -p "$BASE_HOME/.claude/skills" "$BASE_HOME/.claude/agents"
cp -R skills/. "$BASE_HOME/.claude/skills/"
cp -R agents/. "$BASE_HOME/.claude/agents/"
export HOME="$BASE_HOME"

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
# The denominator is the registry, not what this run happened to print. A
# check behind an environment guard (install-drift) disappears from a printed
# baseline on a machine where the guard is false — and its coverage
# requirement disappeared with it.
ALL_IDS=$(sort "$REPO/eval-fixtures/CHECK-IDS.txt")
N_IDS=$(printf '%s\n' "$ALL_IDS" | grep -c .)
printed=$(printf '%s\n' "$baseline" | grep -oE '^  PASS  \[[a-z0-9-]+\]' | sed 's/.*\[//; s/\]//' | sort -u)
if [ "$ALL_IDS" != "$printed" ]; then
  echo "FATAL: the baseline did not print every registered check id —"
  diff <(echo "$ALL_IDS") <(echo "$printed") | sed 's/^/  /'
  exit 2
fi

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
  case "$expect" in none|refused) : ;; *) COVERED="$COVERED $expect" ;; esac
  if [ -n "$FILTER" ]; then
    case "$name$expect$class" in *"$FILTER"*) : ;; *) continue ;; esac
  fi
  MUTS="$MUTS $name"
done
NMUT=$(echo $MUTS | wc -w | tr -d ' ')
if [ "$NMUT" -eq 0 ]; then
  echo "FATAL: no mutation matched '${FILTER}' — a run that executes nothing used to report PASS and exit 0"
  exit 2
fi

# A filename registry. Coverage is denominated in check ids, and one id can
# stand for many properties: after the table refactor, fourteen mutations
# expected `tables-generated`, so deleting thirteen of them left coverage PASS
# and exit 0 — the thirteen the refactor offers as its evidence.
ondisk=$(ls "$MUT_DIR"/*.sh | xargs -n1 basename | sort)
regd=$(grep -v '^#' "$MUT_DIR/REGISTRY.txt" | grep -v '^[[:space:]]*$' | sort)
if [ "$ondisk" != "$regd" ]; then
  echo "FATAL: mutations/ does not match its registry —"
  diff <(echo "$regd") <(echo "$ondisk") | sed 's/^/  /'
  exit 2
fi

worker() {   # worker <slot>: its own copy, its own slice, its own result file
  slot=$1
  dir="$WORK/w$slot"
  cp -R "$WORK/keel" "$dir" || return 2
  # one HOME per worker: eight workers used to share a single install, so one
  # mutation's contamination was visible to the other seven
  MYHOME="$WORK/h$slot"; cp -R "$BASE_HOME" "$MYHOME" || return 2
  export HOME="$MYHOME"
  cd "$dir" || return 2
  BASE_COMMIT=$(git rev-parse HEAD)
  n=0
  for name in $MUTS; do
    n=$((n + 1))
    [ $(( (n - 1) % JOBS )) -eq "$slot" ] || continue
    exp0=$(sed -n 's/^# expect: *//p' "$MUT_DIR/$name.sh" | head -1)
    ( /bin/bash "$MUT_DIR/$name.sh" ) >/dev/null 2>&1
    # A mutation that edits the checker proves nothing: "I broke the check" is
    # not "the check enforces the rule". Opt in per file when the apparatus
    # itself is the subject (mutation 14 disarms the exemption list on purpose).
    # `git status` alone is an observation surface the mutation can rewrite:
    # one `git commit` moved the edit out of the porcelain output and the
    # checker edit was graded as proof. Compare against the baseline commit.
    touched=$( { git status --porcelain | awk '{print $NF}'
                 git diff --name-only "$BASE_COMMIT" 2>/dev/null; } | sort -u )
    selfedit=""
    # first token only: the header carries a justification after the id
    optin=$(sed -n 's/^# touches-checker: *//p' "$MUT_DIR/$name.sh" | head -1 | awk '{print $1}')
    # the opt-in must name the check it is the subject of, and that must be the
    # check it expects: `# touches-checker: yes` let any mutation launder any
    # red — 23 of them could have "covered" all 23 ids without touching the repo
    if [ -n "$optin" ] && [ "$optin" != "$exp0" ]; then
      selfedit="opt-in names '$optin' but expects '$exp0'"
    elif [ -z "$optin" ]; then
      selfedit=$(printf '%s\n' "$touched" | grep -E '^(eval-fixtures/(check-structure|run-mutations)\.sh|eval-fixtures/CHECK-IDS\.txt|eval-fixtures/mutations/|tables/render\.)' || true)
    fi
    out=$(run_checks)
    exp="$exp0"
    if [ "$exp" = "refused" ]; then
      # a negative control: the harness itself is on trial, and passing means
      # this mutation was rejected rather than graded
      v=$([ -n "$selfedit" ] && echo REFUSED_OK || echo REFUSED_MISS)
    elif [ "$exp" = "none" ]; then
      # a control: this one must leave the board exactly as it found it
      nf=$(printf '%s\n' "$out" | grep -c '^  FAIL')
      v=$([ "$nf" -eq 0 ] && echo CONTROL_OK || echo CONTROL_DIRTY)
    else
      v=$(verdict_of "$exp" "$out")
    fi
    [ -n "$selfedit" ] && [ "$exp" != "refused" ] && v="SELFEDIT"
    git checkout -- . >/dev/null 2>&1
    # -x too: .gitignore lists progress.md, findings.md and .keel/, all present
    # in the copy, all previously outside the revert
    git clean -fdxq >/dev/null 2>&1
    # and the fake install, which lives outside the git copy entirely: mutation
    # 55 appends to it, the append survived every later mutation in the run,
    # and a no-op mutation then inherited the red it caused
    git reset -q --hard "$BASE_COMMIT" >/dev/null 2>&1
    rm -rf "$MYHOME/.claude"
    mkdir -p "$MYHOME/.claude/skills" "$MYHOME/.claude/agents"
    cp -R skills/. "$MYHOME/.claude/skills/"
    cp -R agents/. "$MYHOME/.claude/agents/"
    # per-mutation integrity, not one sampled control: a mutation that
    # committed survived checkout+clean and every later mutation in the same
    # worker lane inherited its red, while a different JOBS value put the
    # control in another lane and reported the board clean
    resid=$( { git status --porcelain; git log -1 --format=%H | grep -v "^$BASE_COMMIT$"; } | head -3 )
    [ -z "$resid" ] || v="RESIDUE"
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
    REFUSED_OK)    printf '  \033[32mrefused\033[0m  %-42s → harness declined to grade a checker edit\n' "$name"; GREEN=$((GREEN+1)) ;;
    REFUSED_MISS)  printf '  \033[31mGRADED IT  \033[0m  %-34s → a mutation that edits the checker was accepted as proof\n' "$name"; RED=$((RED+1)) ;;
    CONTROL_OK)    printf '  \033[32mcontrol\033[0m  %-42s → board unchanged\n' "$name"; GREEN=$((GREEN+1)) ;;
    CONTROL_DIRTY) printf '  \033[31mDIRTY BOARD\033[0m  %-34s → a previous mutation was not fully reverted\n' "$name"; RED=$((RED+1)) ;;
    FAIL)   printf '  \033[32m red \033[0m  %-42s → [%s]\n' "$name" "$exp"; GREEN=$((GREEN+1)) ;;
    PASS)   printf '  \033[31mSTILL GREEN\033[0m  %-34s → [%s] did not fire\n' "$name" "$exp"; RED=$((RED+1)) ;;
    RESIDUE)  printf '  \033[31mRESIDUE    \033[0m  %-34s → state survived the revert; every later mutation in this lane is tainted\n' "$name"; RED=$((RED+1)) ;;
    SELFEDIT) printf '  \033[31mSELF-EDIT  \033[0m  %-34s → edits the checker; add `# touches-checker: yes` if that is the point\n' "$name"; RED=$((RED+1)) ;;
    *)      printf '  \033[31mNO SUCH ID \033[0m  %-34s → [%s] never printed\n' "$name" "$exp"; RED=$((RED+1)) ;;
  esac
done < <(sort -n "$WORK/res")

SKIP=0
got=$(grep -c . "$WORK/res")
if [ "$got" -ne "$NMUT" ]; then
  printf '  \033[31mFAIL\033[0m  %s mutations selected but %s results came back — a worker died silently\n' "$NMUT" "$got"
  RED=$((RED+1))
fi

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
