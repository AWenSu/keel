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
# Every check carries a stable id. The mutation harness names checks by id, so
# a message that changes wording (or a count inside it) does not silently
# detach a check from the mutation that proves it can fail.
ok()   { printf '  \033[32mPASS\033[0m  [%s] %s\n' "$1" "$2"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31mFAIL\033[0m  [%s] %s\n' "$1" "$2"; FAIL=$((FAIL+1)); }
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

# eval-fixtures/mutations/ holds deliberately-broken text: every mutation file
# contains the defect it injects, so a repo-wide sweep reads them as live
# defects. They are test data, not documents.
not_test_data() { grep -v '^eval-fixtures/mutations/'; }
# Frontmatter is lines 2..first `---`, and only when line 1 is `---`. The old
# sed range re-triggered on any `---`…`---` pair in the body, so an agent could
# drop `model:`/`tools:` from its real frontmatter, paste a decoy block under an
# appendix, and pass F1, F2, F3 and F14 while inheriting the ambient model and
# the full ambient tool set — the exact defect this file's header cites as one
# of the two real findings that started it.
fm() {
  awk 'NR==1 { if ($0 != "---") exit; next }
       /^---$/ { exit }
       { print }' "$1"
}

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
[ -z "$miss" ] && ok "agent-model-pin" "all $N_AGENTS agents pin a model" || bad "agent-model-pin" "no model: pin →$miss"

# ── F2: every agent pins its own tools ──────────────────────────────────────
head_ "F2  every agent pins tools:"
miss=""
for a in "${AGENTS[@]}"; do
  { fm "$a" | grep -q '^tools:' && [ -n "$(tools_of "$a")" ]; } \
    || miss="$miss $(basename "$a")"
done
[ -z "$miss" ] && ok "agent-tools-pin" "all $N_AGENTS agents pin a non-empty tool list" \
  || bad "agent-tools-pin" "no tools: pin (inherits the ambient set) →$miss"

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
[ -z "$badw" ] && ok "write-grant" "write tools confined to the 3 implementer/fixer agents" \
  || bad "write-grant" "unexpected Edit/Write grant →$badw"
[ -z "$badb" ] && ok "bash-grant" "Bash confined to writers + the 3 diff reviewers" \
  || bad "bash-grant" "unexpected Bash grant →$badb"

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
[ -z "$missr" ] && ok "reviewer-shell-prose" "each Bash-holding reviewer states its read-only shell restriction" \
  || bad "reviewer-shell-prose" "Bash granted with no stated restriction →$missr"

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
[ -z "$missd" ] && ok "readme-shell-grant" "both READMEs describe the 3 reviewers' shell grant" \
  || bad "readme-shell-grant" "README calls a Bash-holding reviewer plain read-only →$missd"

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
  grep -rhoE '`[a-z][a-z0-9]+` +agent|(dispatch|Dispatch|dispatches|launch|Launch|spawn|Spawn|fire|Fire|delegate|Delegate|subagent_type)[^.`]{0,30}`[a-z][a-z0-9]+`' skills/*/*.md \
    | grep -oE '`[a-z][a-z0-9]+`' | tr -d '`'
  grep -rhoE '(dispatch|Dispatch|dispatches|dispatching|launch|Launch|spawn|Spawn) +(the +|a +|an +)?[a-z][a-z0-9]*(-[a-z0-9]+)* +agent' skills/*/*.md \
    | sed -E 's/^(dispatch|Dispatch|dispatches|dispatching|launch|Launch|spawn|Spawn) +(the +|a +|an +)?//; s/ +agent$//'
} | sort -u )

# The exemption list is itself unguarded input: adding a real agent's name to
# it silently exempted that agent from ever needing a roster row.
badexempt=""
for n in $NONAGENT; do
  [ -f "agents/$n.md" ] && badexempt="$badexempt $n(is a shipped agent)"
  grep -qE "^\| \`$n\`" skills/keel-workflow/SKILL.md && badexempt="$badexempt $n(is rostered)"
done
[ -z "$badexempt" ] && ok "exemption-guard" "the non-agent exemption list contains no real agents" \
  || bad "exemption-guard" "exemption list hides a real agent →$badexempt"

# shipped-vs-rostered is now structural: tables/agents.tsv is the roster's
# source and render.sh rewrites every copy from it, so an agent missing from a
# roster is a stale generated block, caught above.

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
[ -z "$ghosts" ] && ok "no-ghost-agent" "every agent named in a skill has a definition file" \
  || bad "no-ghost-agent" "named but missing from agents/ →$ghosts"

# every agent-shaped name a skill uses must be rostered — shipped ones by
# having a file (checked above) and a roster row, external ones by the row alone
undecl=""
for n in $CANDIDATES; do
  in_list "$n" "$NONAGENT" && continue
  in_list "$n" "$(echo $SKILL_NAMES)" && continue
  echo "$n" | grep -q '^keel-' && continue      # shipped: covered by the two checks above
  grep -qE "^\| \`$n\`" skills/keel-workflow/SKILL.md || undecl="$undecl $n"
done
[ -z "$undecl" ] && ok "external-rostered" "external agents used are declared in the roster" \
  || bad "external-rostered" "dispatched but absent from roster →$undecl"

# ── F4/F6/F16: canonical rule text, compared as bytes ───────────────────────
# Four audits found the same defect class, and every instance lived in a check
# that read prose with a regex. There is no correct regex for "is this
# sentence forbidding or recommending?" — allow a comma in the window and an
# endorsement reads as a prohibition; forbid it and a prohibition reads as an
# endorsement. So the rule text is a constant now, not a pattern: rules/*.txt
# holds it once, the files that owe it carry it verbatim, and this compares
# bytes. See rules/README.md for what that does and does not buy.
# A copy inside an HTML comment or a fenced block is present and inert: three
# lines later the file can say the opposite. Live text only.
uncommented() {
  awk '/<!--/ { c = 1 } c { if (/-->/) c = 0; next } { print }' "$1"
}
live_text() {
  awk '/^[[:space:]]*```/ { fence = !fence; next }
       fence { next }
       /<!--/ { c = 1 }
       c { if (/-->/) c = 0; next }
       { print }' "$1"
}
head_ "rules  canonical rule text present verbatim where it is owed"
# The rule files themselves are checked first. An empty one makes `grep -F ""`
# match everything, and a two-line one makes `grep -F` an OR of the lines —
# both turn every copy of that rule green while it is absent. A rule nobody
# lists in the manifest is enforced nowhere and would sit here looking
# authoritative.
badrule=""
# The blocklist used to be skipped here — the one file the anti-pattern leg
# depends on was the one file never validated, and `grep -F -f /dev/null`
# matches nothing while exiting 1, indistinguishable from a clean repo.
apn=$(grep -c . rules/anti-patterns.txt)
apblank=$(grep -c '^[[:space:]]*$' rules/anti-patterns.txt)
[ "$apn" -ge 5 ] || badrule="$badrule anti-patterns.txt(only $apn entries — the blocklist is the catchable half of a stated boundary)"
[ "$apblank" -eq 0 ] || badrule="$badrule anti-patterns.txt(blank line makes grep -F match everything)"
while IFS= read -r apline; do
  [ ${#apline} -ge 12 ] || badrule="$badrule anti-patterns.txt(entry too short to be distinctive: '$apline')"
done < rules/anti-patterns.txt

for rf in rules/*.txt; do
  base=$(basename "$rf")
  [ "$base" = "anti-patterns.txt" ] && continue
  # total lines, not non-empty lines: a leading blank line kept `grep -c .` at
  # 1 while `$(cat …)` still produced a multi-line pattern, and `grep -F` reads
  # that as an OR whose first alternative is the empty string
  total=$(wc -l < "$rf" | tr -d ' ')
  nonblank=$(grep -c . "$rf")
  [ "$total" = "1" ] && [ "$nonblank" = "1" ] \
    || badrule="$badrule $base(must be exactly one line with no blanks: $total lines, $nonblank non-empty)"
  # and it has to be a sentence, not a character: one byte in rules/ used to
  # turn all eight copies of a rule green
  len=$(head -1 "$rf" | tr -d '[:space:]' | wc -c | tr -d ' ')
  [ "$len" -ge 20 ] || badrule="$badrule $base(rule text too short to be distinctive: $len non-space chars)"
  # exact field match, and a commented-out row is not a claim: `grep -F` used
  # to match the filename inside the `#` comment that disabled it
  awk -F"$(printf '\t')" -v b="$base" '$1==b {found=1} END{exit !found}' rules/manifest.tsv \
    || badrule="$badrule $base(orphan — no uncommented manifest row, enforced nowhere)"
done

dupes=$(grep -v '^#' rules/manifest.tsv | grep -v '^[[:space:]]*$' | sort | uniq -d)
[ -z "$dupes" ] || badrule="$badrule manifest.tsv(duplicate rows)"

[ -z "$badrule" ] && ok "rule-file-usable" "every canonical rule file is one line and is claimed by the manifest" \
  || { bad "rule-file-usable" "canonical rule file unusable:"; for b in $badrule; do echo "         $b"; done; }

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
  # not `| grep -q`: with `set -o pipefail`, grep -q exits on first match and
  # the upstream awk takes SIGPIPE, so a HIT reads as a pipeline failure
  found=$(live_text "$target" | grep -cF "$text")
  [ "${found:-0}" -ge 1 ] \
    || missing_rule="$missing_rule $target(missing $rule, or present only in a comment/code fence)"
done < rules/manifest.tsv
[ -z "$missing_rule" ] && ok "rule-text-verbatim" "every file owing a canonical rule carries it verbatim" \
  || { bad "rule-text-verbatim" "canonical rule text missing or paraphrased:"; \
       for m in $missing_rule; do echo "         $m"; done; }

# The manifest is a declaration, so it is cross-checked against a derivation —
# otherwise a new dispatching stage is exempt by omission, which is exactly
# how the hardcoded-six external agent list stayed wrong for a month.
declared_for() { awk -F"$(printf '\t')" -v d="$1" '$3==d && $0 !~ /^#/ {print $2}' rules/manifest.tsv | sort -u; }

# skills/*/*.md, and a verb set wider than the literal token `dispatch`: a new
# stage that said "Launch four subagents" in a PLAYBOOK.md was a real
# dispatcher, carried no rule, and left the derived set equal to the declared
# one. F4/F5 already widened their own glob for exactly this and the
# derivation never inherited it.
derived_dispatchers=$(grep -rlE '`keel-(exec|plan-lens|plan-skeptic|discover-designer|wayfind-researcher)[a-z-]*`|\b(dispatch|Dispatch|dispatches|dispatching|launch|Launch|spawn|Spawn|delegate|Delegate|fire|Fire)\b|subagent_type' \
                      skills/*/*.md | xargs -n1 dirname | xargs -n1 basename | sort -u \
                      | while IFS= read -r d; do echo "skills/$d/SKILL.md"; done | sort -u)
declared_dispatchers=$(declared_for dispatching-stage)
if [ "$derived_dispatchers" = "$declared_dispatchers" ]; then
  ok "manifest-dispatchers" "the manifest lists every dispatching stage ($(echo "$declared_dispatchers" | wc -l | tr -d ' '))"
else
  bad "manifest-dispatchers" "dispatching stages differ from the manifest:"
  diff <(echo "$declared_dispatchers") <(echo "$derived_dispatchers") | sed 's/^/         /'
fi

derived_fanout=$( { git ls-files '*.md'; git ls-files -o --exclude-standard '*.md'; } \
  | sort -u | not_test_data | grep -v '^docs/plans/' | grep -v '^eval-fixtures/' | grep -v '^rules/' \
  | while IFS= read -r f; do
      # a section that caps or uncaps concurrency is a fan-out section whatever
      # it calls itself: "## Concurrency ceiling" raising the limit to 20 was
      # invisible to a heading match on "fan-out" alone
      [ -f "$f" ] && grep -qiE '^#+ .*([Ff]an-out|扇出|[Cc]oncurrenc|並發|併發|平行|[Pp]arallelis)|\*\*[Ff]an-out' "$f" && echo "$f"
      true
    done | sort -u )
declared_fanout=$(declared_for fanout-section)
if [ "$derived_fanout" = "$declared_fanout" ]; then
  ok "manifest-fanout" "the manifest lists every fan-out section ($(echo "$declared_fanout" | wc -l | tr -d ' '))"
else
  bad "manifest-fanout" "fan-out sections differ from the manifest:"
  diff <(echo "$declared_fanout") <(echo "$derived_fanout") | sed 's/^/         /'
fi

# Known contradictions, matched literally and case-insensitively — the first
# version was case-sensitive and "You may pass..." walked past a blocklist
# entry that began with a lowercase y. This is a blocklist: it catches
# what has been written before, not what could be written next — a limit
# stated in rules/README.md and in RULE-INVENTORY rather than papered over.
head_ "rules  no file contradicts a canonical rule (literal blocklist)"
hits=$( { git ls-files '*.md'; git ls-files -o --exclude-standard '*.md'; } \
  | sort -u | not_test_data | grep -v '^rules/' | grep -v '^docs/plans/' \
  | while IFS= read -r f; do
      [ -f "$f" ] && grep -inFf rules/anti-patterns.txt "$f" | sed "s|^|$f:|"
      true
    done )
[ -z "$hits" ] && ok "no-anti-pattern" "no known anti-pattern appears in any tracked file" \
  || { bad "no-anti-pattern" "anti-pattern found:"; echo "$hits" | sed 's/^/         /'; }

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
             | sort -u | not_test_data | grep -v '^docs/plans/' | while IFS= read -r f; do
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
  bad "total-budget-scoped" "no fan-out ceiling stated anywhere — the rule has been deleted, not satisfied"
elif [ -z "$noscope" ]; then
  ok "total-budget-scoped" "all $nb stated total-agent budgets are scoped to a task loop or a round"
else
  bad "total-budget-scoped" "total-agent budget with no task-loop/round scope:"; echo "$noscope" | sed 's/^/         /'
fi

# ── bonus: prefix hygiene — no pre-rename names survive ─────────────────────
head_ "naming  no pre-rename identifiers survive"
# This script necessarily contains the pattern it searches for, so exclude it.
# `dev pipeline` (unhyphenated) survived the rename in 22 descriptions —
# the field that decides whether a skill is selected at all — because this
# pattern only matched the hyphenated form.
STALE='dev-(discover|plan|execute|finish|debug|wayfind|workflow|exec)|unified-dev-skills|(unified )?dev pipeline'
if leftover=$( { git ls-files -z; git ls-files -zo --exclude-standard; } | xargs -0 grep -lE "\b($STALE)" 2>/dev/null \
              | grep -v '^eval-fixtures/check-structure.sh$' | not_test_data || true); [ -z "$leftover" ]; then
  ok "no-stale-names" "no dev-* or unified-dev-skills references in tracked files"
else
  bad "no-stale-names" "stale identifiers in:"; echo "$leftover" | sed 's/^/         /'
fi

# ── fixtures cite stable anchors, not line numbers ──────────────────────────
# Four fixtures once cited line ranges that had drifted onto unrelated text —
# one of them drifted inside the very commit that was auditing it. A grader
# following eval-fixtures/README.md ("open the cited Rule source file:line")
# then walks the wrong rule and grades PASS on text unrelated to the fixture.
head_ "fixtures  Rule source cites a resolvable anchor"
nfix=$(ls eval-fixtures/[0-9]*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$nfix" -eq 0 ]; then
  bad "fixture-anchor" "no fixture files found — check ran against nothing"
else
  # any Rule-source line, bolded or not, citing any .md with a line number
  cites=$(grep -hniE '^\**Rule source' eval-fixtures/[0-9]*.md \
          | grep -E '\.md:[0-9]+' || true)
  [ -z "$cites" ] && ok "fixture-anchor" "none of the $nfix fixtures pins a rule to a line number" \
    || { bad "fixture-anchor" "line-number citation will drift:"; echo "$cites" | sed 's/^/         /'; }

  # every file named in a Rule source must exist — a dangling path sends the
  # grader somewhere that is not merely stale but absent
  missf=""
  for f in $(grep -hoE '`?(skills|agents)/[A-Za-z0-9_./-]+\.md`?' eval-fixtures/[0-9]*.md \
             | tr -d '`' | sort -u); do
    [ -f "$f" ] || missf="$missf $f"
  done
  [ -z "$missf" ] && ok "fixture-file-exists" "every file cited by a fixture exists" \
    || bad "fixture-file-exists" "fixture cites a nonexistent file →$missf"
fi

# ── every named section that is referenced actually exists ──────────────────
# The `## Signals` defect: six files read a section by that exact name and no
# file defined it, because what got added was a header *field*. Section-vs-
# field is invisible to every other check here and cost one whole commit.
head_ "sections  every referenced ## section is defined somewhere"
# A filename containing a space used to word-split into three nonexistent
# paths, three awk fatals, and every section reported undefined — a check
# that degrades to all-false-positive is a check nobody will read.
allmd=$( { git ls-files '*.md'; git ls-files -o --exclude-standard '*.md'; } | sort -u | not_test_data )
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
        # A heading in live prose is a definition anywhere. A heading inside a
        # fenced block is a template, and a template is only a definition in a
        # skill that owns the artifact — pasting one into a README code fence
        # (plus an HTML comment) was how an undefined section passed.
        if [ -f "$m" ]; then
          if [ "$(live_text "$m" | grep -cE "^## ${name}([[:space:]]|\(|$)")" -ge 1 ]; then
            echo "$m"
          elif echo "$m" | grep -q '^skills/' \
               && [ "$(uncommented "$m" | grep -cE "^## ${name}([[:space:]]|\(|$)")" -ge 1 ]; then
            echo "$m"
          fi
        fi
        true
      done)
  [ -n "$defined" ] || missing_sec="$missing_sec [$name]"
done
[ -z "$missing_sec" ] && ok "section-defined" "every referenced ## section has a definition" \
  || bad "section-defined" "referenced but never defined →$missing_sec"

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
[ -z "$badq" ] && ok "fixture-quote-verbatim" "every fixture blockquote is verbatim from its cited source" \
  || { bad "fixture-quote-verbatim" "fixture quotes text absent from its source:"; echo "$badq" | sed 's/^/         /'; }

# ── generated tables: the structure is rendered, not duplicated ─────────────
# Six checks used to live here: route count, route destinations, gate list,
# README roster, documented model pin, and shipped-vs-rostered. Every one of
# them existed to keep three copies of the same table honest, and five audits
# produced six separate defects in them — a sorted multiset that missed a swap,
# a `<prose>` slot that absorbed any number of rows, a gate deleted from all
# three at once, a model column read from the wrong cell. Verification kept
# losing to duplication, so the duplication is what changed: the key and
# structural columns are generated from tables/*.tsv and the agents' own
# frontmatter. What is left to check is that nobody hand-edited the output.
#
# The prose in those tables is NOT generated and never was checked: no
# description is shared between the three documents, by design.
head_ "tables  generated blocks match their source"
if [ -x tables/render.sh ] || [ -f tables/render.sh ]; then
  render_out=$(/bin/bash tables/render.sh --check 2>&1)
  if [ $? -eq 0 ]; then
    ok "tables-generated" "all 9 generated table blocks match tables/*.tsv"
  else
    bad "tables-generated" "a generated table block was hand-edited or its source changed:"
    printf '%s\n' "$render_out" | sed 's/^/         /'
  fi
else
  bad "tables-generated" "tables/render.sh is missing — the three duplicated tables have no source"
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
  [ -z "$drift" ] && ok "install-in-sync" "all skills and agents byte-identical to ~/.claude" \
    || bad "install-in-sync" "installed copy has drifted →$drift"
fi

# ── summary ─────────────────────────────────────────────────────────────────
printf '\n\033[1m%d passed, %d failed\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
