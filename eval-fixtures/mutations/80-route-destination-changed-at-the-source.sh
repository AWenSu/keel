# expect: tables-generated
# class:  check-cannot-fail
# origin: gate-8 — the independent record was consulted for its row count only,
# so a destination changed in the tsv propagated into all three documents while
# RULE-INVENTORY's A-row and the fixture still named the old one
perl -i -pe 's/`keel-discover`\t`keel-discover`\t`keel-discover`/`keel-plan`\t`keel-plan`\t`keel-plan`/ if /^R3\t/' tables/routes.tsv
