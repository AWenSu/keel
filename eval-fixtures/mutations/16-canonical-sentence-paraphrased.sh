# expect: rule-text-verbatim
# class:  declared-not-wired
# origin: design of the canonical mechanism
perl -i -pe 's/Do not pass a `model` override at the call site — each agent file pins its own\./Never pass a model override; the agent file pins it./' skills/keel-plan/SKILL.md
