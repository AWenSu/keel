# expect: tables-generated
# class:  declared-not-wired
# origin: second-tier refactor — the failure mode generation replaces
perl -i -pe 's/^\| `keel-exec-fixer` \| 4 execute \|/| `keel-exec-fixer` | 9 nowhere |/' README.md
