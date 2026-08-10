# expect: manifest-dispatchers
# class:  derivation-too-narrow
# origin: gate-5 (glob was skills/*/SKILL.md)
mkdir -p skills/keel-triage
printf -- '---\nname: keel-triage\ndescription: x\n---\n\nsee playbook\n' > skills/keel-triage/SKILL.md
printf 'Dispatch `keel-exec-implementer` for each ticket.\n' > skills/keel-triage/PLAYBOOK.md
