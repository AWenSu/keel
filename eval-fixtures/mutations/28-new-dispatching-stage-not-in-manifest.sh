# expect: manifest-dispatchers
# class:  derivation-too-narrow
# origin: gate-5 (verb was the literal token `dispatch`)
mkdir -p skills/keel-triage
printf -- '---\nname: keel-triage\ndescription: x\n---\n\nLaunch four subagents at once: `keel-plan-lens-ceo`, `keel-plan-lens-eng`.\n' > skills/keel-triage/SKILL.md
