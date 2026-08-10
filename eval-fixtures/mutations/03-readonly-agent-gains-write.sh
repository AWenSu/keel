# expect: write-grant
# class:  declared-not-wired
# origin: self-audit 2026-08-09
perl -i -pe "s/^(tools: .*)/\$1, Write/ if \$. < 8" agents/keel-plan-lens-dx.md
