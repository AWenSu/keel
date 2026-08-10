# expect: tables-generated
# class:  declared-not-wired
# origin: gate-5
perl -i -pe 's/^\| \*\*G6\*\* \| `keel-execute`/| **G6** | `keel-finish`/' README.md
