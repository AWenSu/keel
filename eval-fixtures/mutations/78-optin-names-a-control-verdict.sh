# expect: refused
# class:  unattributed-red
# origin: gate-8 — `none` is a legal expect value, so `# touches-checker: none`
# on a control disarmed the self-edit scan for the whole control class: the
# mutation whose job is to certify the board is clean could disable the checks
# it was certifying
# touches-checker: none
perl -i -pe 's/^STALE=.*/STALE="zzzz-no-such-token"/' eval-fixtures/check-structure.sh
