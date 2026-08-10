# Removes a check, its id, its mutation and its registry line in one edit —
# the co-deletion the ratchet exists to catch. Used by mutation 72.
import pathlib

p = pathlib.Path('eval-fixtures/check-structure.sh')
s = p.read_text()
i = s.index('# The READMEs are declaration sites for F3')
j = s.index('# \u2500\u2500 F4/F5:')
p.write_text(s[:i] + s[j:])

q = pathlib.Path('eval-fixtures/CHECK-IDS.txt')
q.write_text('\n'.join(x for x in q.read_text().split()
                       if x != 'readme-shell-grant') + '\n')

pathlib.Path('eval-fixtures/mutations/06-readme-calls-reviewer-plain-readonly.sh').unlink()

g = pathlib.Path('eval-fixtures/mutations/REGISTRY.txt')
g.write_text(''.join(l for l in g.read_text().splitlines(True)
                     if '06-readme' not in l))
