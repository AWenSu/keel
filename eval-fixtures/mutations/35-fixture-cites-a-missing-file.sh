# expect: fixture-file-exists
# class:  declared-not-wired
# origin: self-audit
perl -i -pe 's|skills/keel-execute/SKILL.md|skills/keel-nonexistent/SKILL.md| if $. == 3' eval-fixtures/22-plan-field-contracts.md
