# expect: rule-text-verbatim
# class:  declared-not-wired
# origin: gate-4
perl -i -pe 's/Fan-out ceiling: ≤8 concurrent, ≤16 total per task loop\.//' README.md
