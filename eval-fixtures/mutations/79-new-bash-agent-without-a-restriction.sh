# touches-checker: reviewer-shell-prose — BASH_OK is the set this check derives from
# expect: reviewer-shell-prose
# class:  derivation-too-narrow
# origin: gate-8 — this check looped over four hardcoded names while the check
# three lines below it derived the same set from BASH_OK, so a new Bash-holding
# read-only agent could ship with no stated restriction at all
printf -- '---\nname: keel-exec-reviewer-perf\ndescription: x\ntools: Read, Grep, Glob, Bash\nmodel: sonnet\n---\n\nNo restriction stated anywhere in this file.\n' > agents/keel-exec-reviewer-perf.md
perl -i -pe 's/^BASH_OK="(.*)"/BASH_OK="$1 keel-exec-reviewer-perf"/' eval-fixtures/check-structure.sh
