# expect: agent-tools-pin
# class:  declared-not-wired
# origin: self-audit 2026-08-09 (an agent with no tools: inherits the ambient set)
perl -i -ne "print unless /^tools:/" agents/keel-exec-implementer.md
