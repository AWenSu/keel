# expect: tables-generated
# class:  round-trip-laundering
# origin: gate-6 — a read-only agent documented as holding full tools
perl -i -pe 's/^(\| `keel-plan-skeptic` \| 3 review \| [^|]*\| sonnet \| ).*\|$/${1}full |/' README.md
