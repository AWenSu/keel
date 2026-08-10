# expect: tables-generated
# class:  declared-not-wired
# origin: gate-4
perl -i -pe 's/^(\| G9 \| any stage .*)$/$1\n| G10 | keel-execute | An invented gate |/' skills/keel-workflow/SKILL.md
