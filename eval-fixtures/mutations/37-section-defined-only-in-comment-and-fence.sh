# expect: section-defined
# class:  present-but-inert
# origin: gate-5
printf '\nEscalations follow `## Escalation ladder`.\n' >> skills/keel-execute/SKILL.md
printf '\n<!--\n## Escalation ladder\n-->\n\n```text\n## Escalation ladder\n```\n' >> README.md
