#!/usr/bin/env bash
# check-structure.sh — mechanical verification of keel's structural guarantees
#
# The F-series rules in RULE-INVENTORY.md are facts about files, not scenarios
# about behavior. Writing them as prose walkthrough fixtures would be worse
# than useless: nobody runs a walkthrough, and the two real defects found in
# the 2026-08-09 audit (three write-capable agents with no `tools:` pin at all,
# and every "read-only" agent holding Bash) were both caught by grep in
# seconds, not by reading documents.
#
# Run from anywhere:  bash eval-fixtures/check-structure.sh
# Exit 0 = all pass. Exit 1 = at least one FAIL.

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2

PASS=0; FAIL=0
ok()   { printf '  \033[32mPASS\033[0m  %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; FAIL=$((FAIL+1)); }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

AGENTS=(agents/*.md)
N_AGENTS=${#AGENTS[@]}

# Agents allowed to hold write tools. Everything else is read-only by grant.
WRITERS="keel-exec-implementer keel-exec-fixer keel-exec-fixer-critical"
# Agents allowed to hold Bash: the writers, plus the three diff reviewers that
# cannot review a diff without `git diff`.
BASH_OK="$WRITERS keel-exec-reviewer-spec keel-exec-reviewer-quality keel-exec-reviewer-security"

in_list() { case " $2 " in *" $1 "*) return 0;; *) return 1;; esac; }
fm() { sed -n '/^---$/,/^---$/p' "$1"; }   # frontmatter only

printf '\033[1mkeel structural checks\033[0m  (%s agents, %s skills)\n' \
  "$N_AGENTS" "$(ls -d skills/*/ | wc -l | tr -d ' ')"

# ── F1: every agent pins its own model ──────────────────────────────────────
head_ "F1  every agent pins model:"
miss=""
for a in "${AGENTS[@]}"; do fm "$a" | grep -q '^model:' || miss="$miss $(basename "$a")"; done
[ -z "$miss" ] && ok "all $N_AGENTS agents pin a model" || bad "no model: pin →$miss"

# ── F2: every agent pins its own tools ──────────────────────────────────────
head_ "F2  every agent pins tools:"
miss=""
for a in "${AGENTS[@]}"; do fm "$a" | grep -q '^tools:' || miss="$miss $(basename "$a")"; done
[ -z "$miss" ] && ok "all $N_AGENTS agents pin a tool list" \
  || bad "no tools: pin (inherits the ambient set) →$miss"

# ── F3: read-only is a grant, not a promise ─────────────────────────────────
head_ "F3  read-only enforced by tool list"
badw=""; badb=""
for a in "${AGENTS[@]}"; do
  n=$(basename "$a" .md); t=$(fm "$a" | grep '^tools:' || true)
  if echo "$t" | grep -qE '\b(Edit|Write|NotebookEdit)\b'; then
    in_list "$n" "$WRITERS" || badw="$badw $n"
  fi
  if echo "$t" | grep -q '\bBash\b'; then
    in_list "$n" "$BASH_OK" || badb="$badb $n"
  fi
done
[ -z "$badw" ] && ok "write tools confined to the 3 implementer/fixer agents" \
  || bad "unexpected Edit/Write grant →$badw"
[ -z "$badb" ] && ok "Bash confined to writers + the 3 diff reviewers" \
  || bad "unexpected Bash grant →$badb"

# The 3 reviewers keep Bash, so their restriction lives in prose — verify it exists.
missr=""
for n in keel-exec-reviewer-spec keel-exec-reviewer-quality keel-exec-reviewer-security; do
  grep -q 'read-only inspection only' "agents/$n.md" || missr="$missr $n"
done
[ -z "$missr" ] && ok "each Bash-holding reviewer states its read-only shell restriction" \
  || bad "Bash granted with no stated restriction →$missr"

# The READMEs are declaration sites for F3 (RULE-INVENTORY says so), and the
# "reviewer described as plain read-only while holding Bash" defect recurred
# in the untranslated half because this check only ever read agents/*.md.
missd=""
for f in README.md README.zh-TW.md; do
  for n in spec quality security; do
    grep -E "keel-exec-reviewer-$n\`" "$f" | grep -qiE 'shell|Bash' || missd="$missd $f:$n"
  done
done
[ -z "$missd" ] && ok "both READMEs describe the 3 reviewers' shell grant" \
  || bad "README calls a Bash-holding reviewer plain read-only →$missd"

# ── F4/F5: dispatch names resolve to a roster row ───────────────────────────
head_ "F4/F5  dispatched subagent_types exist and are rostered"
ROSTER=$(grep -oE '^\| `keel-[a-z-]+`' skills/keel-workflow/SKILL.md | tr -d '|` ')
EXTERNAL="planner code-reviewer security-auditor test-engineer silent-failure-hunter build-error-resolver"
missing=""
for a in "${AGENTS[@]}"; do
  n=$(basename "$a" .md)
  in_list "$n" "$(echo $ROSTER)" || missing="$missing $n"
done
[ -z "$missing" ] && ok "all $N_AGENTS shipped agents appear in the keel-workflow roster" \
  || bad "shipped but not rostered →$missing"

# every keel-* name mentioned as a dispatch target must have a file.
# Skill names share the prefix (keel-plan-review is a skill, not an agent), so
# subtract the skills/ directory listing before deciding a name is a ghost.
SKILL_NAMES=$(basename -a skills/*/)
ghosts=""
for n in $(grep -rhoE '`keel-(exec|plan|discover|wayfind)-[a-z-]+`' skills/*/SKILL.md \
           | tr -d '`' | sort -u); do
  in_list "$n" "$(echo $SKILL_NAMES)" && continue
  [ -f "agents/$n.md" ] || ghosts="$ghosts $n"
done
[ -z "$ghosts" ] && ok "every agent named in a skill has a definition file" \
  || bad "named but missing from agents/ →$ghosts"

# external agents referenced must be declared as external, not silently assumed
undecl=""
for n in $EXTERNAL; do
  if grep -rqE "\`$n\`" skills/*/SKILL.md; then
    grep -q "\`$n\`" skills/keel-workflow/SKILL.md || undecl="$undecl $n"
  fi
done
[ -z "$undecl" ] && ok "external agents used are declared in the roster" \
  || bad "dispatched but absent from roster →$undecl"

# ── F6: no model override at any dispatch site ──────────────────────────────
head_ "F6  no model override at dispatch sites"
if hits=$(grep -rnE 'model[:=] *(opus|sonnet|haiku)' skills/*/SKILL.md \
          | grep -viE 'do not|never|pins|pinned|matrix|\| *(opus|sonnet)' || true); [ -z "$hits" ]; then
  ok "no dispatch instruction tells a caller to pass a model"
else
  bad "possible model override instruction:"; echo "$hits" | sed 's/^/         /'
fi

# ── F7: fan-out ceiling — one scope, stated the same way everywhere ─────────
# The previous version of this check asserted that one literal 8-word string was
# ABSENT from one file. That is true of almost any file, including files stating
# the contradiction in different words — and it reported PASS while the defect
# was live in both READMEs. A green light certifying a live defect is worse than
# no check, so this now sweeps every file that states a total.
head_ "F7  fan-out ceiling consistent repo-wide"
if hits=$(grep -rnE '≤ ?16|16 total|總量.{0,4}16' --include='*.md' . \
          | grep -v '^./docs/plans/' \
          | grep -viE 'task loop|每個 task|per round|skeptics per' || true); [ -z "$hits" ]; then
  ok "every stated 16-agent budget is scoped to a task loop or a round"
else
  bad "16-agent budget stated with a non-task-loop scope:"; echo "$hits" | sed 's/^/         /'
fi

# ── bonus: prefix hygiene — no pre-rename names survive ─────────────────────
head_ "naming  no pre-rename identifiers survive"
# This script necessarily contains the pattern it searches for, so exclude it.
STALE='dev-(discover|plan|execute|finish|debug|wayfind|workflow|exec)|unified-dev-skills'
if leftover=$(git ls-files -z | xargs -0 grep -lE "\b($STALE)" 2>/dev/null \
              | grep -v '^eval-fixtures/check-structure.sh$' || true); [ -z "$leftover" ]; then
  ok "no dev-* or unified-dev-skills references in tracked files"
else
  bad "stale identifiers in:"; echo "$leftover" | sed 's/^/         /'
fi

# ── fixtures cite stable anchors, not line numbers ──────────────────────────
# Four fixtures once cited line ranges that had drifted onto unrelated text —
# one of them drifted inside the very commit that was auditing it. A grader
# following eval-fixtures/README.md ("open the cited Rule source file:line")
# then walks the wrong rule and grades PASS on text unrelated to the fixture.
head_ "fixtures  Rule source cites an anchor, not a line number"
if cites=$(grep -nE '^\*\*Rule source:\*\*|^\*\*Rule source' eval-fixtures/[0-9]*.md \
           | grep -E 'SKILL\.md:[0-9]|\.md:[0-9]+-[0-9]' || true); [ -z "$cites" ]; then
  ok "no fixture pins a rule to a line number"
else
  bad "line-number citation will drift:"; echo "$cites" | sed 's/^/         /'
fi

# ── maintainer-only: repo vs. installed copy ────────────────────────────────
# Skips entirely when no keel install is present, so it is a no-op for anyone
# who just cloned this. For the maintainer, who edits both sides, silent drift
# between them means the pipeline you actually run is not the one you commit.
if [ -d "$HOME/.claude/skills/keel-workflow" ]; then
  head_ "install  repo matches the installed copy"
  drift=""
  for f in skills/*/SKILL.md; do
    n=$(basename "$(dirname "$f")")
    d="$HOME/.claude/skills/$n/SKILL.md"
    [ -f "$d" ] || { drift="$drift $n(missing)"; continue; }
    cmp -s "$f" "$d" || drift="$drift $n"
  done
  for f in agents/*.md; do
    d="$HOME/.claude/agents/$(basename "$f")"
    [ -f "$d" ] || { drift="$drift $(basename "$f" .md)(missing)"; continue; }
    cmp -s "$f" "$d" || drift="$drift $(basename "$f" .md)"
  done
  [ -z "$drift" ] && ok "all skills and agents byte-identical to ~/.claude" \
    || bad "installed copy has drifted →$drift"
fi

# ── summary ─────────────────────────────────────────────────────────────────
printf '\n\033[1m%d passed, %d failed\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
