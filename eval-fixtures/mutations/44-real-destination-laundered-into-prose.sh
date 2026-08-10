# expect: tables-generated
# class:  check-cannot-fail
# origin: gate-4 (<prose> was a wildcard)
for f in README.md README.zh-TW.md skills/keel-workflow/SKILL.md; do
  perl -i -pe 's/`keel-debug` \|/wherever feels right |/' "$f"
done
