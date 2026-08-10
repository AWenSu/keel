# expect: fixture-anchor
# class:  declared-not-wired
# origin: gate-2 (12 citations had drifted to unrelated text)
perl -i -pe 's|`skills/keel-execute/SKILL\.md`|`skills/keel-execute/SKILL.md:142`| if $. == 3' eval-fixtures/22-plan-field-contracts.md
