# expect: total-budget-scoped
# class:  regex-reads-prose
# origin: gate-3 / gate-4 (detector missed 'in total')
perl -i -pe 's/≤16 total per task loop/≤16 agents in total across the whole pipeline/' README.md
