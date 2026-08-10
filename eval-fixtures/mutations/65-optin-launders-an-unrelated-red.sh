# expect: refused
# class:  unattributed-red
# origin: gate-7 — the opt-in was unconditional, so a mutation could break any
# check and claim the red as that check's proof. Twenty-three of these could
# have "covered" all twenty-three ids without touching the repo.
# touches-checker: bash-grant
perl -i -pe 's/^STALE=.*/STALE="keel"/' eval-fixtures/check-structure.sh
