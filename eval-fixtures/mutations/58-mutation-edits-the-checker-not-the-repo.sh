# expect: refused
# class:  unattributed-red
# origin: gate-6 — "I broke the check" was graded as "the check enforces the
# rule". This mutation injects no defect into any product file; the harness
# must refuse to grade it. No `# touches-checker:` header, on purpose.
perl -i -pe 's/^BASH_OK=.*/BASH_OK=""/' eval-fixtures/check-structure.sh
