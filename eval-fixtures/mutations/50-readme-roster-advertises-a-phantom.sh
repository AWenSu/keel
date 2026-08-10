# expect: readme-roster
# class:  declared-not-wired
# origin: gate-4
perl -i -pe 's/^(\| `keel-plan-skeptic-critical` .*)$/$1\n| `keel-exec-phantom` | 4 execute | Does not exist | sonnet | read-only |/' README.md
