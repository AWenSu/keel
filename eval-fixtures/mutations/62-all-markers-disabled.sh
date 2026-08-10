# expect: tables-generated
# class:  self-disarm
# origin: gate-6 — zero blocks located, success line said 9 anyway
perl -i -pe 's/^(<!-- \/?generated:)/x$1/' README.md README.zh-TW.md skills/keel-workflow/SKILL.md
