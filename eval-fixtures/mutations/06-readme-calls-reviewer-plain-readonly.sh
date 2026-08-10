# expect: readme-shell-grant
# class:  declared-not-wired
# origin: gate-2 (the defect recurred in the untranslated half)
perl -i -pe "s/read-only \+ shell restricted to .git diff.\/.log.\/.show., .which., tests/read-only, no shell/" README.md
