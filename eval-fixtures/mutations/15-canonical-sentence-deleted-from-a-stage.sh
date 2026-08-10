# expect: rule-text-verbatim
# class:  declared-not-wired
# origin: design of the canonical mechanism
perl -i -ne 'print unless /^Do not pass a `model` override at the call site/' skills/keel-debug/SKILL.md
