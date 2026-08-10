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

# `|| true` at the end of a pipeline makes a broken path indistinguishable
# from "no hits", so the inputs every check depends on are asserted up front
# rather than discovered as a silent pass.
for req in agents skills eval-fixtures README.md README.zh-TW.md \
           skills/keel-workflow/SKILL.md eval-fixtures/RULE-INVENTORY.md \
           eval-fixtures/README.md; do
  [ -e "$req" ] || { printf '\033[31mFATAL\033[0m  missing %s — checks would pass vacuously\n' "$req"; exit 2; }
done
[ "$N_AGENTS" -ge 1 ] && [ -e "${AGENTS[0]}" ] \
  || { printf '\033[31mFATAL\033[0m  agents/ is empty\n'; exit 2; }
git rev-parse --git-dir >/dev/null 2>&1 \
  || { printf '\033[31mFATAL\033[0m  not a git repo — the naming check needs git ls-files\n'; exit 2; }

# Agents allowed to hold write tools. Everything else is read-only by grant.
WRITERS="keel-exec-implementer keel-exec-fixer keel-exec-fixer-critical"
# Agents allowed to hold Bash: the writers, plus the three diff reviewers that
# cannot review a diff without `git diff`.
BASH_OK="$WRITERS keel-exec-reviewer-spec keel-exec-reviewer-quality keel-exec-reviewer-security"

in_list() { case " $2 " in *" $1 "*) return 0;; *) return 1;; esac; }
fm() { sed -n '/^---$/,/^---$/p' "$1"; }   # frontmatter only

# Every tool an agent is granted, one per line. Handles both the inline
# comma form and the YAML block form — reading only the `tools:` LINE let a
# block-list grant Edit, Write and Bash to a read-only agent with all three
# assertions still reporting green.
tools_of() {
  fm "$1" | awk '
    /^tools:/ { inline=$0; sub(/^tools: */,"",inline); if (inline!="") {print inline; next} blk=1; next }
    blk && /^[[:space:]]*-[[:space:]]*/ { sub(/^[[:space:]]*-[[:space:]]*/,""); print; next }
    blk && /^[^[:space:]]/ { blk=0 }
  ' | tr ',' '\n' | tr -d '[]' | sed 's/^ *//; s/ *$//' | grep -v '^$'
}

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
for a in "${AGENTS[@]}"; do
  { fm "$a" | grep -q '^tools:' && [ -n "$(tools_of "$a")" ]; } \
    || miss="$miss $(basename "$a")"
done
[ -z "$miss" ] && ok "all $N_AGENTS agents pin a non-empty tool list" \
  || bad "no tools: pin (inherits the ambient set) →$miss"

# ── F3: read-only is a grant, not a promise ─────────────────────────────────
head_ "F3  read-only enforced by tool list"
badw=""; badb=""
for a in "${AGENTS[@]}"; do
  n=$(basename "$a" .md); t=$(tools_of "$a")
  if echo "$t" | grep -qxE '(Edit|Write|NotebookEdit)'; then
    in_list "$n" "$WRITERS" || badw="$badw $n"
  fi
  if echo "$t" | grep -qx 'Bash'; then
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
  body=$(tr '\n' ' ' < "agents/$n.md")
  case "$body" in
    *"read-only inspection only"*) : ;;
    *) missr="$missr $n"; continue ;;
  esac
  case "$body" in
    *"Never write, delete, move, install, push"*) : ;;
    *) missr="$missr $n(no command restriction)" ;;
  esac
done
[ -z "$missr" ] && ok "each Bash-holding reviewer states its read-only shell restriction" \
  || bad "Bash granted with no stated restriction →$missr"

# The READMEs are declaration sites for F3 (RULE-INVENTORY says so), and the
# "reviewer described as plain read-only while holding Bash" defect recurred
# in the untranslated half because this check only ever read agents/*.md.
missd=""
for f in README.md README.zh-TW.md; do
  for n in spec quality security; do
    row=$(grep -E "keel-exec-reviewer-$n\`" "$f" | head -1)
    # must positively describe a restricted shell, and must not deny holding one
    echo "$row" | grep -qiE 'restricted|僅限|受限' &&
      echo "$row" | grep -qiE 'shell|bash' &&
      ! echo "$row" | grep -qiE 'no shell|without shell|沒有 ?shell|不含 ?shell' \
      || missd="$missd $f:$n"
  done
done
[ -z "$missd" ] && ok "both READMEs describe the 3 reviewers' shell grant" \
  || bad "README calls a Bash-holding reviewer plain read-only →$missd"

# ── F4/F5: dispatch names resolve to a roster row ───────────────────────────
head_ "F4/F5  dispatched subagent_types exist and are rostered"
ROSTER=$(grep -oE '^\| `keel-[a-z-]+`' skills/keel-workflow/SKILL.md | tr -d '|` ')
# Derived, not listed: a hardcoded six meant any external agent added later
# (Explore, Plan, claude-code-guide…) was silently exempt from the
# declared-in-the-roster requirement.
EXTERNAL=$(grep -rhoE '`[A-Za-z][A-Za-z0-9_-]{3,}`' skills/*/*.md | tr -d '`' | sort -u \
  | while read -r n; do
      [ -f "agents/$n.md" ] && continue
      case "$n" in
        keel-*|*.md|*.sh|model|general-purpose|subagent_type|Delivers|Files|Skills|Interfaces) continue;;
      esac
      grep -rqE "(dispatch|Dispatch|派工|派出).{0,80}\`$n\`|\`$n\` (agent|subagent)" skills/*/*.md \
        && echo "$n"
    done)

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
for n in $(grep -rhoE '`keel-[a-z-]+`' skills/*/*.md \
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

# F4 proper: the rule is "no general-purpose dispatch inside the pipeline", and
# until now nothing checked it — the section header claimed F4/F5 while only F5
# had code behind it, and RULE-INVENTORY credited this script for the coverage.
# Judged over a 2-line window: the prohibition often wraps onto the next line
# ("a `general-purpose` agent inside\n this pipeline is a bug").
gp=$(for f in $( { git ls-files 'skills/**/*.md' 'agents/*.md'; git ls-files -o --exclude-standard 'skills/**/*.md' 'agents/*.md'; } | sort -u); do
  awk -v F="$f" '
    { win = prev "\n" $0 "\n" nextline }
    /general-purpose/ {
      ctx = prev " " $0 " " getline_next
      hits[NR]=$0; ctxs[NR]=prev " " $0
    }
    { prev=$0 }
    END{}
  ' "$f" >/dev/null 2>&1
  grep -n 'general-purpose' "$f" | while IFS=: read -r ln rest; do
    ctx=$(sed -n "$((ln>1?ln-1:1)),$((ln+1))p" "$f")
    echo "$ctx" | grep -qiE 'never|not |no |avoid|instead of|rather than|falls back|fallback|is a bug|forbidden|silently|絕不|不要' \
      || echo "$f:$ln:$rest"
  done
done)
[ -z "$gp" ] && ok "no file endorses a general-purpose dispatch" \
  || { bad "general-purpose named without a prohibition:"; echo "$gp" | sed 's/^/         /'; }

# ── F6: no model override at any dispatch site ──────────────────────────────
# The previous version grepped a pattern with zero pre-filter matches, so its
# whole exclusion list was dead code guarding nothing — and, worse, deleting
# the no-override rule outright would not have failed it. Two checks now: the
# rule must still be stated, and no override syntax may appear at a call site.
head_ "F6  no model override at dispatch sites"
norule=""
# every stage that dispatches, not the three that happened to be listed
DISPATCHERS=$(grep -rl 'general-purpose' skills/*/SKILL.md | xargs -n1 dirname | xargs -n1 basename)
for f in $DISPATCHERS; do
  # tolerate emphasis markup and wording variants; require a real prohibition
  tr '\n' ' ' < "skills/$f/SKILL.md" \
    | grep -qiE '(do \*{0,2}not\*{0,2}|never|no) [^.]{0,40}`?model`?( +override| +parameter|\b)' \
    || norule="$norule $f"
done
ndisp=$(echo "$DISPATCHERS" | grep -c . || true)
if [ "${ndisp:-0}" -eq 0 ]; then
  bad "no dispatching stage found — the rule check would pass over an empty set"
elif [ -z "$norule" ]; then
  ok "the no-override rule is still stated in all $ndisp dispatching stages"
else
  bad "no-override rule weakened or deleted in →$norule"
fi

# Override *syntax* at a call site. Roster/matrix table cells legitimately name
# models, so exclude table rows; frontmatter legitimately pins one, so exclude
# lines starting `model:`.
# Any model name, not an enumerated three; `"model":` JSON form included; the
# frontmatter exemption is resolved per file by line number rather than by the
# substring `:model:`, which a body line beginning `model:` also satisfies.
override_hits() {
  for f in $( { git ls-files 'skills/**/*.md' 'agents/*.md'; git ls-files -o --exclude-standard 'skills/**/*.md' 'agents/*.md'; } | sort -u); do
    fmend=$(awk 'NR>1 && /^---$/{print NR; exit}' "$f"); : "${fmend:=0}"
    grep -nE '["`]?model["`]? *[:=] *["`]?[a-z][a-z0-9.-]+' "$f" \
      | awk -F: -v e="$fmend" '$1 > e' \
      | grep -vE '^[0-9]+:\|' \
      | grep -viE 'do not|never|instead of|rather than|not by passing|pins its own|model matrix' \
      | sed "s|^|$f:|"
  done
}
if hits=$(override_hits || true); [ -z "$hits" ]; then
  ok "no dispatch site carries model-override syntax"
else
  bad "model-override syntax at a call site:"; echo "$hits" | sed 's/^/         /'
fi

# ── F7: fan-out ceiling — one scope, stated the same way everywhere ─────────
# The previous version of this check asserted that one literal 8-word string was
# ABSENT from one file. That is true of almost any file, including files stating
# the contradiction in different words — and it reported PASS while the defect
# was live in both READMEs. A green light certifying a live defect is worse than
# no check, so this now sweeps every file that states a total.
head_ "F7  fan-out ceiling consistent repo-wide"
# Rewritten twice. v1 asserted one literal string was ABSENT from one file and
# passed while the defect was live elsewhere. v2 hardcoded the number 16 in
# three patterns (renumbering the ceiling silently disarmed it), missed
# README.zh-TW entirely because its Chinese pattern assumed <5 chars between
# 總量 and the digits, and treated four literal phrases as a scope whitelist.
# v3 finds any total-agent budget by shape, then requires a scope word near it.
# Only counts that are explicitly about agents — `confidence ≤5` and
# `≤15 lines` are not fan-out budgets.
# Judged per *clause*, not per line: a line can legitimately state a
# concurrency cap and a total in the same sentence, and matching scope words
# anywhere on the line let the concurrency word rescue a mis-scoped total.
# Window ends at the budget's own quantifier — a 40-char window swallowed the
# NEXT clause, and its scope word ("每輪") then rescued the mis-scoped total.
noscope=$(grep -rnoE '(總量|[0-9]+ +total)[^.。，,；;（(]{0,28}' --include='*.md' . 2>/dev/null \
          | grep -v '^\./docs/plans/' \
          | grep -iE 'agent|隻|個' \
          | grep -viE 'task loop|每個 ?task|per round|每輪|skeptics per' || true)
if [ -z "$noscope" ]; then
  n=$(grep -rocE '總量|[0-9]+ +total agents' --include='*.md' . 2>/dev/null \
      | grep -v '^\./docs/plans/' | awk -F: '{t+=$2} END{print t+0}')
  if [ "${n:-0}" -eq 0 ]; then
    bad "no fan-out ceiling stated anywhere — the rule has been deleted, not satisfied"
  else
    ok "all $n stated total-agent budgets are scoped to a task loop or a round"
  fi
else
  bad "total-agent budget with no task-loop/round scope:"; echo "$noscope" | sed 's/^/         /'
fi

# ── bonus: prefix hygiene — no pre-rename names survive ─────────────────────
head_ "naming  no pre-rename identifiers survive"
# This script necessarily contains the pattern it searches for, so exclude it.
STALE='dev-(discover|plan|execute|finish|debug|wayfind|workflow|exec)|unified-dev-skills'
if leftover=$( { git ls-files -z; git ls-files -zo --exclude-standard; } | xargs -0 grep -lE "\b($STALE)" 2>/dev/null \
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
head_ "fixtures  Rule source cites a resolvable anchor"
nfix=$(ls eval-fixtures/[0-9]*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$nfix" -eq 0 ]; then
  bad "no fixture files found — check ran against nothing"
else
  # any Rule-source line, bolded or not, citing any .md with a line number
  cites=$(grep -hniE '^\**Rule source' eval-fixtures/[0-9]*.md \
          | grep -E '\.md:[0-9]+' || true)
  [ -z "$cites" ] && ok "none of the $nfix fixtures pins a rule to a line number" \
    || { bad "line-number citation will drift:"; echo "$cites" | sed 's/^/         /'; }

  # every file named in a Rule source must exist — a dangling path sends the
  # grader somewhere that is not merely stale but absent
  missf=""
  for f in $(grep -hoE '`?(skills|agents)/[A-Za-z0-9_./-]+\.md`?' eval-fixtures/[0-9]*.md \
             | tr -d '`' | sort -u); do
    [ -f "$f" ] || missf="$missf $f"
  done
  [ -z "$missf" ] && ok "every file cited by a fixture exists" \
    || bad "fixture cites a nonexistent file →$missf"
fi

# ── every named section that is referenced actually exists ──────────────────
# The `## Signals` defect: six files read a section by that exact name and no
# file defined it, because what got added was a header *field*. Section-vs-
# field is invisible to every other check here and cost one whole commit.
head_ "sections  every referenced ## section is defined somewhere"
allmd=$( { git ls-files '*.md'; git ls-files -o --exclude-standard '*.md'; } | sort -u )
missing_sec=""
for sec in $(echo "$allmd" | xargs grep -hoE '`## [A-Z][A-Za-z ]{2,30}`' 2>/dev/null \
             | sed 's/^`## //; s/`$//' | sort -u | tr ' ' '\001'); do
  name=$(echo "$sec" | tr '\001' ' ')
  # sections a stage tells a *plan or spec file* to create live in those
  # artifacts, not here — recognised by the instruction verb near the mention
  echo "$allmd" | xargs grep -hE "(save it under|write it under|goes in|new) \`## ${name}\`" \
    >/dev/null 2>&1 && continue
  echo "$allmd" | xargs grep -lE "^## ${name}" >/dev/null 2>&1 \
    || missing_sec="$missing_sec [$name]"
done
[ -z "$missing_sec" ] && ok "every referenced ## section has a definition" \
  || bad "referenced but never defined →$missing_sec"

head_ "fixtures  quoted rule text appears in the cited file"
badq=$(for fx in eval-fixtures/[0-9]*.md; do
  src=$(grep -m1 '^\*\*Rule source' "$fx" \
        | grep -oE '`[A-Za-z0-9_./-]+\.md`' | head -1 | tr -d '`')
  [ -n "$src" ] && [ -f "$src" ] || continue
  # compare with newlines and markdown flattened on both sides
  flat=$(tr '\n' ' ' < "$src" | sed 's/[*`]//g; s/  */ /g')
  awk '/^> /{sub(/^> /,""); gsub(/[*`]/,""); if (length($0)>40) print}' "$fx" \
  | while read -r q; do
      frag=$(echo "$q" | sed 's/  */ /g' | cut -c1-46)
      case "$flat" in *"$frag"*) ;; *) echo "$fx → $src: \"$frag\"";; esac
    done
done)
[ -z "$badq" ] && ok "every fixture blockquote is verbatim from its cited source" \
  || { bad "fixture quotes text absent from its source:"; echo "$badq" | sed 's/^/         /'; }

# ── maintainer-only: repo vs. installed copy ────────────────────────────────
# Skips entirely when no keel install is present, so it is a no-op for anyone
# who just cloned this. For the maintainer, who edits both sides, silent drift
# between them means the pipeline you actually run is not the one you commit.
if [ -d "$HOME/.claude/skills/keel-workflow" ]; then
  head_ "install  repo matches the installed copy"
  drift=""
  for f in skills/*/*.md; do
    n="$(basename "$(dirname "$f")")/$(basename "$f")"
    d="$HOME/.claude/skills/$n"
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
