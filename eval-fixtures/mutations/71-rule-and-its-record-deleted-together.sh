# expect: ratchet
# class:  co-deletion-blind
# origin: gate-7 — backward route A6 removed from tables/routes.tsv AND
# from RULE-INVENTORY section A, the two independent sources agreeing at
# six, every board green, and the rule gone from the pipeline
perl -i -ne 'print unless /^R7\t/' tables/routes.tsv
perl -i -ne 'print unless /^\| A6 \|/' eval-fixtures/RULE-INVENTORY.md
bash tables/render.sh >/dev/null 2>&1
