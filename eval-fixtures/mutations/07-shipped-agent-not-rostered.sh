# expect: tables-generated
# class:  declared-not-wired
# origin: self-audit
perl -i -ne "print unless /^\| .keel-plan-skeptic. \|/" skills/keel-workflow/SKILL.md
