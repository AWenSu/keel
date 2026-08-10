# expect: external-rostered
# class:  check-cannot-fail
# origin: gate-3 (the derivation was X∈S⇒X∈S)
perl -i -ne 'print unless /^\| `test-engineer` \|/' skills/keel-workflow/SKILL.md
