# expect: no-ghost-agent
# class:  declared-not-wired
# origin: self-audit
perl -i -pe "s/\`keel-exec-fixer\`/\`keel-exec-ghost\`/" skills/keel-execute/SKILL.md
