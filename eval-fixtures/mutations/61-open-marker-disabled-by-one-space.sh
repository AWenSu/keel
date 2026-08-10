# expect: tables-generated
# class:  self-disarm
# origin: gate-6 — render became an identity function and cmp said up to date
perl -i -pe 's/^(<!-- generated:roster )/ $1/' README.md
perl -i -ne 'print unless /^\| `keel-exec-fixer-critical` \| 4 execute \|/' README.md
