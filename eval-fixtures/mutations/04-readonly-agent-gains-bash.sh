# expect: bash-grant
# class:  declared-not-wired
# origin: self-audit 2026-08-09 (every read-only agent held Bash)
perl -i -pe "s/^(tools: .*)/\$1, Bash/ if \$. < 8" agents/keel-plan-lens-ceo.md
