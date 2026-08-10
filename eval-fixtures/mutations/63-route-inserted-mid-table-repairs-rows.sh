# expect: tables-generated
# class:  round-trip-laundering
# origin: gate-6 — following tables/README.md's own instructions corrupted five routes
perl -i -pe 'print "R2b\tspec itself is wrong\tspec itself is wrong\tspec 本身錯了\tkeel-execute\t`keel-execute`\t`keel-execute`\t`keel-discover`\t`keel-discover`\t`keel-discover`\n" if /^R3\t/' tables/routes.tsv
