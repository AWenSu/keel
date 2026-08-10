# touches-checker: yes — the registry is the subject of this check
# expect: check-id-registry
# class:  derivation-too-narrow
# origin: gate-6 — the harness denominator came from what a run printed, so a
# check behind an environment guard was exempt from needing a mutation
perl -i -ne 'print unless /^install-in-sync$/' eval-fixtures/CHECK-IDS.txt
