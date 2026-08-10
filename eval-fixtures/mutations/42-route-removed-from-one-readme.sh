# expect: tables-generated
# class:  declared-not-wired
# origin: gate-3 (A7 was in keel-workflow and neither README)
perl -i -ne 'print unless /post-merge reality/' README.md
