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

# Half this repo is Traditional Chinese. Under a C locale, BSD sed rejects it
# ("RE error: illegal byte sequence") and the zh checks degrade quietly.
if [ "${LC_ALL:-}" = "" ] && [ "${LANG:-}" = "" ]; then
  for L in en_US.UTF-8 C.UTF-8 UTF-8; do
    if locale -a 2>/dev/null | grep -qix "$(echo "$L" | tr 'A-Z' 'a-z')" \
       || [ "$L" = "UTF-8" ]; then export LC_ALL="$L"; break; fi
  done
fi
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

# Written without `case` inside the pipeline — bash 3.2, which is what
# /bin/bash is on macOS, aborts the whole script there with a syntax error.
#
# Candidate agent names come from the SKILLS, never from the roster. Deriving
# them from the roster and then asserting they are in the roster is `X ∈ S ⇒
# X ∈ S`: the previous two versions were a proximity regex that found 2 of 6,
# and then a roster derivation that found 6 of 6 and could not fail. Deleting
# `test-engineer`'s roster row while keel-plan-review still dispatched it
# passed both.
#
# Hyphenated backticked tokens are agent-shaped; these are the ones that are
# not agents. Anything new that lands here needs a deliberate line, which is
# the point — an unrecognised agent-shaped name should stop the build.
NONAGENT="general-purpose plan-global doubt-driven-development frontend-workflow planning-with-files model subagent_type inherit opus sonnet haiku"
# skills/*/*.md, not skills/*/SKILL.md: the ghost check next to this one
# already scanned the wider set, and a dispatch written in smells.md was
# invisible to this one. Unbackticked prose forms count too — "dispatch the
# docs-writer agent" is a dispatch.
CANDIDATES=$( {
  grep -rhoE '`[a-z][a-z0-9]*(-[a-z0-9]+)+`' skills/*/*.md | tr -d '`'
  # single-word and unbackticked names are only recognisable by their context
  grep -rhoE '`[a-z][a-z0-9]+` +agent|(dispatch|Dispatch|dispatches|subagent_type)[^.`]{0,30}`[a-z][a-z0-9]+`' skills/*/*.md \
    | grep -oE '`[a-z][a-z0-9]+`' | tr -d '`'
  grep -rhoE '(dispatch|Dispatch|dispatches|dispatching) +(the +|a +|an +)?[a-z][a-z0-9]*(-[a-z0-9]+)* +agent' skills/*/*.md \
    | sed -E 's/^(dispatch|Dispatch|dispatches|dispatching) +(the +|a +|an +)?//; s/ +agent$//'
} | sort -u )

# The exemption list is itself unguarded input: adding a real agent's name to
# it silently exempted that agent from ever needing a roster row.
badexempt=""
for n in $NONAGENT; do
  [ -f "agents/$n.md" ] && badexempt="$badexempt $n(is a shipped agent)"
  grep -qE "^\| \`$n\`" skills/keel-workflow/SKILL.md && badexempt="$badexempt $n(is rostered)"
done
[ -z "$badexempt" ] && ok "the non-agent exemption list contains no real agents" \
  || bad "exemption list hides a real agent →$badexempt"

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

# every agent-shaped name a skill uses must be rostered — shipped ones by
# having a file (checked above) and a roster row, external ones by the row alone
undecl=""
for n in $CANDIDATES; do
  in_list "$n" "$NONAGENT" && continue
  in_list "$n" "$(echo $SKILL_NAMES)" && continue
  echo "$n" | grep -q '^keel-' && continue      # shipped: covered by the two checks above
  grep -qE "^\| \`$n\`" skills/keel-workflow/SKILL.md || undecl="$undecl $n"
done
[ -z "$undecl" ] && ok "external agents used are declared in the roster" \
  || bad "dispatched but absent from roster →$undecl"

# ── F4/F6/F16: canonical rule text, compared as bytes ───────────────────────
# Four audits found the same defect class, and every instance lived in a check
# that read prose with a regex. There is no correct regex for "is this
# sentence forbidding or recommending?" — allow a comma in the window and an
# endorsement reads as a prohibition; forbid it and a prohibition reads as an
# endorsement. So the rule text is a constant now, not a pattern: rules/*.txt
# holds it once, the files that owe it carry it verbatim, and this compares
# bytes. See rules/README.md for what that does and does not buy.
head_ "rules  canonical rule text present verbatim where it is owed"
# The rule files themselves are checked first. An empty one makes `grep -F ""`
# match everything, and a two-line one makes `grep -F` an OR of the lines —
# both turn every copy of that rule green while it is absent. A rule nobody
# lists in the manifest is enforced nowhere and would sit here looking
# authoritative.
badrule=""
for rf in rules/*.txt; do
  base=$(basename "$rf")
  [ "$base" = "anti-patterns.txt" ] && continue
  n=$(grep -c . "$rf")
  [ "$n" -eq 1 ] || badrule="$badrule $base(must be exactly one non-empty line, has $n)"
  grep -qF "$base" rules/manifest.tsv \
    || badrule="$badrule $base(orphan — no manifest entry, enforced nowhere)"
done
[ -z "$badrule" ] && ok "every canonical rule file is one line and is claimed by the manifest" \
  || { bad "canonical rule file unusable:"; for b in $badrule; do echo "         $b"; done; }

missing_rule=""
while IFS="$(printf '\t')" read -r rule target deriv; do
  echo "$rule" | grep -q '^#' && continue
  [ -n "${rule:-}" ] || continue
  case "$rule" in
    *" "*) missing_rule="$missing_rule manifest-row(columns must be tab-separated, found spaces: $rule)"; continue ;;
  esac
  [ -f "rules/$rule" ] || { missing_rule="$missing_rule rules/$rule(no such rule file)"; continue; }
  [ -n "$target" ] || { missing_rule="$missing_rule $rule(manifest row has no target — tab-separated, not spaces)"; continue; }
  [ -f "$target" ] || { missing_rule="$missing_rule $target(no such file)"; continue; }
  text=$(cat "rules/$rule")
  [ -n "$text" ] || { missing_rule="$missing_rule $rule(empty rule file)"; continue; }
  grep -qF "$text" "$target" \
    || missing_rule="$missing_rule $target(missing $rule)"
done < rules/manifest.tsv
[ -z "$missing_rule" ] && ok "every file owing a canonical rule carries it verbatim" \
  || { bad "canonical rule text missing or paraphrased:"; \
       for m in $missing_rule; do echo "         $m"; done; }

# The manifest is a declaration, so it is cross-checked against a derivation —
# otherwise a new dispatching stage is exempt by omission, which is exactly
# how the hardcoded-six external agent list stayed wrong for a month.
declared_for() { awk -F"$(printf '\t')" -v d="$1" '$3==d && $0 !~ /^#/ {print $2}' rules/manifest.tsv | sort -u; }

derived_dispatchers=$(grep -rlE '`keel-(exec|plan-lens|plan-skeptic|discover-designer|wayfind-researcher)[a-z-]*`|\b(dispatch|Dispatch|dispatches|dispatching)\b' \
                      skills/*/SKILL.md | sort -u)
declared_dispatchers=$(declared_for dispatching-stage)
if [ "$derived_dispatchers" = "$declared_dispatchers" ]; then
  ok "the manifest lists every dispatching stage ($(echo "$declared_dispatchers" | wc -l | tr -d ' '))"
else
  bad "dispatching stages differ from the manifest:"
  diff <(echo "$declared_dispatchers") <(echo "$derived_dispatchers") | sed 's/^/         /'
fi

derived_fanout=$( { git ls-files '*.md'; git ls-files -o --exclude-standard '*.md'; } \
  | sort -u | grep -v '^docs/plans/' | grep -v '^eval-fixtures/' | grep -v '^rules/' \
  | while IFS= read -r f; do
      [ -f "$f" ] && grep -qiE '^#+ .*([Ff]an-out|扇出)|\*\*[Ff]an-out' "$f" && echo "$f"
      true
    done | sort -u )
declared_fanout=$(declared_for fanout-section)
if [ "$derived_fanout" = "$declared_fanout" ]; then
  ok "the manifest lists every fan-out section ($(echo "$declared_fanout" | wc -l | tr -d ' '))"
else
  bad "fan-out sections differ from the manifest:"
  diff <(echo "$declared_fanout") <(echo "$derived_fanout") | sed 's/^/         /'
fi

# Known contradictions, matched literally and case-insensitively — the first
# version was case-sensitive and "You may pass..." walked past a blocklist
# entry that began with a lowercase y. This is a blocklist: it catches
# what has been written before, not what could be written next — a limit
# stated in rules/README.md and in RULE-INVENTORY rather than papered over.
head_ "rules  no file contradicts a canonical rule (literal blocklist)"
hits=$( { git ls-files '*.md'; git ls-files -o --exclude-standard '*.md'; } \
  | sort -u | grep -v '^rules/' | grep -v '^docs/plans/' \
  | while IFS= read -r f; do
      [ -f "$f" ] && grep -inFf rules/anti-patterns.txt "$f" | sed "s|^|$f:|"
      true
    done )
[ -z "$hits" ] && ok "no known anti-pattern appears in any tracked file" \
  || { bad "anti-pattern found:"; echo "$hits" | sed 's/^/         /'; }

# ── F7: fan-out ceiling — one scope, stated the same way everywhere ─────────
# The previous version of this check asserted that one literal 8-word string was
# ABSENT from one file. That is true of almost any file, including files stating
# the contradiction in different words — and it reported PASS while the defect
# was live in both READMEs. A green light certifying a live defect is worse than
# no check, so this now sweeps every file that states a total.
head_ "F7  fan-out ceiling consistent repo-wide"
# Rewritten five times. v3 scanned only forward from the number and so
# discarded "…number of agents. The cap is ≤8 concurrent, ≤16 total per
# stage" — the noun precedes the digits. v4 added a `.{0,60}` prefix and
# backtracked catastrophically: grep hung, returned nothing, and the check
# passed forever. v5 does the windowing in awk, which cannot blow up.
noscope=$( { git ls-files '*.md'; git ls-files -o --exclude-standard '*.md'; } \
             | sort -u | grep -v '^docs/plans/' | while IFS= read -r f; do
  [ -f "$f" ] || continue
  awk -v F="$f" '
    { L[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) {
        if (L[i] !~ /總量|總計|[0-9]+ +total|in total/) continue
        ctx = (i>1 ? L[i-1] : "") " " L[i] " " (i<NR ? L[i+1] : "")
        clause = L[i]
        if (match(clause, /總量|總計|[0-9]+ +total|in total/)) clause = substr(clause, RSTART)
        if (match(clause, /[。.，,；;（(]/)) clause = substr(clause, 1, RSTART - 1)
        if (ctx ~ /agent|隻|個|skeptic/ &&
            clause !~ /task loop|每個 ?task|per round|每輪|skeptics per/)
          printf "%s:%d: %s\n", F, i, substr(L[i],1,90)
      }
    }
  ' "$f"
done )
nb=$(grep -rocE '總量|總計|[0-9]+ +total|in total' --include='*.md' . 2>/dev/null \
     | grep -v '^\./docs/plans/' | awk -F: '{t+=$2} END{print t+0}')
# A silently shrinking count reads the same as a clean board: rephrasing one
# ceiling out of the detector's reach dropped nb from 3 to 2 and still said
# PASS. Every statement of the concurrency half must have a total half in the
# same file, so losing one is a mismatch rather than a smaller green number.
# Pairing alone could not see a ceiling deleted in matched pairs: removing
# both halves from a README kept c == t and the board green, which is the
# "silently shrinking count" failure this was written to stop. So the set of
# files REQUIRED to state a ceiling is derived first, from the fan-out
# sections themselves, and each required file must state both halves.
#
# The delegation exemption is keel-workflow's alone. As a general escape
# hatch it was a per-file kill switch: prepending "Total-agent budgets belong
# to the stages." to any file let its total half be deleted.
# (the ceiling text itself is now a canonical rule, checked above by bytes;
#  what remains here is the scope requirement: a total with no stated scope)
if [ "${nb:-0}" -eq 0 ]; then
  bad "no fan-out ceiling stated anywhere — the rule has been deleted, not satisfied"
elif [ -z "$noscope" ]; then
  ok "all $nb stated total-agent budgets are scoped to a task loop or a round"
else
  bad "total-agent budget with no task-loop/round scope:"; echo "$noscope" | sed 's/^/         /'
fi

# ── bonus: prefix hygiene — no pre-rename names survive ─────────────────────
head_ "naming  no pre-rename identifiers survive"
# This script necessarily contains the pattern it searches for, so exclude it.
# `dev pipeline` (unhyphenated) survived the rename in 22 descriptions —
# the field that decides whether a skill is selected at all — because this
# pattern only matched the hyphenated form.
STALE='dev-(discover|plan|execute|finish|debug|wayfind|workflow|exec)|unified-dev-skills|(unified )?dev pipeline'
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
# A filename containing a space used to word-split into three nonexistent
# paths, three awk fatals, and every section reported undefined — a check
# that degrades to all-false-positive is a check nobody will read.
allmd=$( { git ls-files '*.md'; git ls-files -o --exclude-standard '*.md'; } | sort -u )
grep_md() { echo "$allmd" | while IFS= read -r m; do [ -f "$m" ] && grep "$@" "$m"; true; done; }
missing_sec=""
for sec in $(grep_md -hoE '`## [A-Z][A-Za-z0-9 -]{1,30}`' 2>/dev/null \
             | sed 's/^`## //; s/`$//' | sort -u | tr ' ' '\001'); do
  name=$(echo "$sec" | tr '\001' ' ')
  # `## Task N` is a finding tag, not a section; artifact sections are exempt
  # bash 3.2 rejects `case` inside these subshell pipelines
  expr "$name" : 'Task ' >/dev/null && continue
  # sections a stage tells a *plan or spec file* to create live in those
  # artifacts, not here — recognised by the instruction verb near the mention
  # The exemption must name the artifact AND carry the template, in the SAME
  # file. Three earlier versions of this leg each moved the loophole rather
  # than closing it: a bare verb list was a repo-global kill switch; adding
  # the artifact word still let the claim sit in one file and the template in
  # another; and the template scan forgot to exclude docs/plans/, so an
  # generated plan document could re-exempt a section no shipped skill
  # defines. The producer is one file: it says it writes the section, and it
  # shows the section.
  producer=$(
  while IFS= read -r cand; do
    [ -f "$cand" ] || continue
    grep -qE "^## ${name}([[:space:]]|$)" "$cand" || continue
    tr '\n' ' ' < "$cand" \
      | grep -qE "(save it under|write it under|goes in|go into|writes|written into|create|add|produce)( a new| the)? \`?## ${name}\`?[^.]{0,60}(plan|spec|計畫|規格)|(plan|spec|計畫|規格)[^.]{0,80}(save it under|write it under|goes in|go into|writes|written into|create|add|produce)( a new| the)? \`?## ${name}\`?" \
      && { echo "$cand"; break; }
  done <<PRODUCER_LIST
$(echo "$allmd" | grep -v '^docs/plans/' | grep -v '^eval-fixtures/[0-9]')
PRODUCER_LIST
)
  [ -n "$producer" ] && continue
  # captured, not piped: with `set -o pipefail` a per-file grep that misses
  # makes the whole pipeline non-zero, which reported every section undefined
  defined=$(echo "$allmd" | grep -v '^docs/plans/' | grep -v '^eval-fixtures/[0-9]' \
    | while IFS= read -r m; do
        [ -f "$m" ] && grep -lE "^## ${name}([[:space:]]|\(|$)" "$m" 2>/dev/null
        true
      done)
  [ -n "$defined" ] || missing_sec="$missing_sec [$name]"
done
[ -z "$missing_sec" ] && ok "every referenced ## section has a definition" \
  || bad "referenced but never defined →$missing_sec"

head_ "fixtures  quoted rule text appears in the cited file"
badq=$(for fx in eval-fixtures/[0-9]*.md; do
  srcs=$(grep -iE '^\**Rule source' "$fx" \
         | grep -oE '`?[A-Za-z0-9_./-]+\.md`?' | tr -d '`' | sort -u)
  [ -n "$srcs" ] || continue
  flat=""
  for sf in $srcs; do
    [ -f "$sf" ] && flat="$flat $(tr '\n' ' ' < "$sf" | sed 's/[*`]//g; s/  */ /g')"
  done
  [ -n "$flat" ] || continue
  awk '/^>/{sub(/^> ?/,""); gsub(/[*`]/,""); if (length($0)>12) print}' "$fx" \
  | while read -r q; do
      frag=$(echo "$q" | sed 's/  */ /g; s/^ *//; s/ *$//')
      # Elisions are deliberate, but skipping the whole quote made three
      # characters a bypass: a blockquote of pure invention passed by
      # containing "...". Each segment either side of an elision must still
      # appear verbatim in the source.
      if echo "$frag" | grep -q '\.\.\.\|…'; then
        echo "$frag" | sed 's/\.\.\./\n/g; s/…/\n/g' | while read -r seg; do
          seg=$(echo "$seg" | sed 's/^ *//; s/ *$//')
          # 12 was the whole-quote threshold reused per segment, so chunking a
          # fabrication into sub-12-character pieces bought a free pass. Only
          # fragments too short to be distinctive are skipped now.
          [ "${#seg}" -ge 5 ] || continue
          echo "$flat" | grep -qF "$seg" \
            || echo "$fx → ${srcs%% *}: \"$(echo "$seg"|cut -c1-50)\""
        done
        continue
      fi
      echo "$flat" | grep -qF "$frag" \
        || echo "$fx → ${srcs%% *}: \"$(echo "$frag"|cut -c1-50)\""
    done
done)
[ -z "$badq" ] && ok "every fixture blockquote is verbatim from its cited source" \
  || { bad "fixture quotes text absent from its source:"; echo "$badq" | sed 's/^/         /'; }

# ── F11: the backward-route table is the same length in all three documents ──
# The A7 route (post-merge Signals → keel-discover) was added to keel-workflow
# and to neither README for a week: the source of truth grew a route and the
# two documents users actually read did not. Counting rows catches that without
# needing to match wording across two languages.
head_ "F11  backward routes documented everywhere"
rows_after() {   # rows of the first table following the given heading match
  awk -v pat="$2" '$0 ~ pat {f=1; next} f && /^\|/ {if ($0 !~ /^\|[- :|]+\|$/ && $0 !~ /Trigger|發生什麼/) n++; next} f && n {exit} END {print n+0}' "$1"
}
# Row counts are the weak form; the destinations are the content. A route
# whose text was replaced wholesale kept the count intact, so the `back to`
# column is compared as a multiset too.
routes_of() {
  awk -v pat="$2" '$0 ~ pat {f=1; next}
       f && /^\|/ {if ($0 !~ /^\|[- :|]+\|$/ && $0 !~ /Trigger|發生什麼/) {print; n++} next}
       f && n {exit}' "$1" \
    | awk -F'|' '{ d=$(NF-1); gsub(/[` ]/,"",d)
                   # one destination is prose in both languages ("the stage
                   # that owes the missing artifact"); compare it as a slot,
                   # not as text, or the zh table can never match
                   print (d ~ /keel-/ ? d : "<prose>") }'
}
wf=$(rows_after skills/keel-workflow/SKILL.md 'Backward routes')
en=$(rows_after README.md 'Backward routes')
zh=$(rows_after README.zh-TW.md '回退路由')
[ "$wf" = "$en" ] && [ "$wf" = "$zh" ] && [ "$wf" -gt 0 ] \
  && ok "all three backward-route tables list $wf routes" \
  || bad "backward-route count differs → keel-workflow=$wf README=$en README.zh-TW=$zh"

# Compared in order, not sorted: swapping two destinations left the sorted
# multiset identical while both rows pointed at the wrong stage.
rt_wf=$(routes_of skills/keel-workflow/SKILL.md 'Backward routes')
rt_en=$(routes_of README.md 'Backward routes')
rt_zh=$(routes_of README.zh-TW.md '回退路由')
# `<prose>` is a slot for the one route whose destination is a role rather
# than a stage ("the stage that owes the missing artifact") — as a wildcard it
# absorbed any number of rows, so replacing `keel-debug` with "wherever feels
# right" in all three tables passed.
nprose=$(echo "$rt_wf" | grep -c '<prose>')
[ "${nprose:-0}" -le 1 ] \
  || bad "more than one backward route has a prose destination ($nprose) — a stage name was laundered into the slot"
[ "${nprose:-0}" -le 1 ] && PASS=$((PASS+0))
if [ "$rt_wf" = "$rt_en" ] && [ "$rt_wf" = "$rt_zh" ] && [ "${nprose:-0}" -le 1 ]; then
  ok "every route's destination matches across all three tables"
else
  bad "route destinations differ:"
  diff <(echo "$rt_wf") <(echo "$rt_en") | sed 's/^/         en: /'
  diff <(echo "$rt_wf") <(echo "$rt_zh") | sed 's/^/         zh: /'
fi

# ── F12: the gate table is enumerated in three documents ────────────────────
# keel-workflow calls it "a closed list" that forbids everything not on it, so
# a gate present in one document and absent from two is actively countermanded
# by the other two — a worse shape than the A7 route drift F11 was written for.
head_ "F12  gate list identical in all three documents"
# ID plus the stage each gate belongs to. Semantics stay out of reach of a
# grep — a gate row can be rewritten to say the opposite and this will not
# see it; RULE-INVENTORY states that boundary rather than implying coverage
# this does not have.
gates_of() {
  awk -F'|' '/^\| *\*{0,2}G[0-9]+\*{0,2} *\|/ {
    id = $2; stage = $3
    gsub(/[ *`]/, "", id); gsub(/[ *`]/, "", stage)
    # G9 belongs to "any stage", which is prose and differs by language;
    # every other gate names a keel-* stage
    sub(/[,，].*|Step.*|pre-flight.*|Part.*|per-task.*|每個.*/, "", stage)
    print id "/" (stage ~ /^keel-/ ? stage : "<any>")
  }' "$1" | sort -u
}
g_wf=$(gates_of skills/keel-workflow/SKILL.md)
g_en=$(gates_of README.md)
g_zh=$(gates_of README.zh-TW.md)
if [ -n "$g_wf" ] && [ "$g_wf" = "$g_en" ] && [ "$g_wf" = "$g_zh" ]; then
  ok "all three documents list the same $(echo "$g_wf" | wc -l | tr -d ' ') gates"
else
  bad "gate list differs:"
  diff <(echo "$g_wf") <(echo "$g_en") | sed 's/^/         en: /'
  diff <(echo "$g_wf") <(echo "$g_zh") | sed 's/^/         zh: /'
fi

# ── F13: the READMEs' agent rosters match agents/ ───────────────────────────
# F5 compares agents/ to keel-workflow only, and the ghost check reads
# skills/ only, so both READMEs could lose a shipped agent or advertise one
# that does not exist.
head_ "F13  README rosters match the shipped agents"
shipped=$(for a in "${AGENTS[@]}"; do basename "$a" .md; done | sort)
roster_of() {   # agent rows in the roster section only
  awk '/^## Subagent (roster|名冊)/ {f=1; next} f && /^## / {exit} f' "$1" \
    | grep -oE '^\| `keel-[a-z-]+`' | tr -d '|` ' | sort -u
}
bad_roster=""
for f in README.md README.zh-TW.md; do
  [ "$(roster_of "$f")" = "$shipped" ] || bad_roster="$bad_roster $f"
done

# The name column matching is the weak form: a roster row could advertise
# `opus` for an agent whose frontmatter pins `haiku`, in either direction,
# and the model is the whole reason the roster exists. F1 only asserts that a
# pin exists, never that the documented pin is the real one.
badmodel=""
for f in README.md README.zh-TW.md skills/keel-workflow/SKILL.md; do
  awk '/^## Subagent (roster|名冊)|^## .*[Rr]oster/ {f=1} f && /^## / && seen {exit}
       f && /^\| `keel-[a-z-]+`/ {print; seen=1}' "$f" \
  | while IFS= read -r row; do
      n=$(echo "$row" | grep -oE '^\| `keel-[a-z-]+`' | tr -d '|` ')
      [ -f "agents/$n.md" ] || continue
      real=$(sed -n '/^---$/,/^---$/p' "agents/$n.md" | sed -n 's/^model: *//p' | head -1)
      shown=$(echo "$row" | grep -oiE '\b(opus|sonnet|haiku|inherit)\b' | head -1 | tr 'A-Z' 'a-z')
      [ -n "$shown" ] || continue
      [ "$shown" = "$real" ] || echo "$f:$n(doc=$shown,file=$real)"
    done
done > /tmp/keel-model-drift.$$ 2>/dev/null
badmodel=$(cat /tmp/keel-model-drift.$$; rm -f /tmp/keel-model-drift.$$)
[ -z "$badmodel" ] && ok "every documented model pin matches the agent file" \
  || { bad "documented model differs from the agent's frontmatter:"; echo "$badmodel" | sed 's/^/         /'; }
if [ -z "$bad_roster" ]; then
  ok "both READMEs list exactly the $N_AGENTS shipped agents"
else
  bad "README roster does not match agents/ →$bad_roster"
  for f in $bad_roster; do diff <(echo "$shipped") <(roster_of "$f") | sed "s|^|         $f: |"; done
fi

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
