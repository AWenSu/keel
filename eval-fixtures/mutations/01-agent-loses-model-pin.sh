# expect: agent-model-pin
# class:  declared-not-wired
# origin: self-audit 2026-08-09 (the original finding: three agents with no pin)
perl -i -ne "print unless /^model:/" agents/keel-plan-skeptic.md
