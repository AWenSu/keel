# expect: readme-shell-grant
# class:  derivation-too-narrow
# origin: gate-7 — the README shell check looped over a hardcoded three of the
# seven Bash holders, so a fourth could be documented as holding anything
perl -i -pe 's/read-only \+ a shell restricted to running the checkers[^\t]*/full write access/' tables/agents.tsv
bash tables/render.sh >/dev/null 2>&1
