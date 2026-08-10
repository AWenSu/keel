# expect: tables-generated
# class:  check-cannot-fail
# origin: gate-4 (the multiset was sorted)
python3 - <<'PY'
import pathlib
p=pathlib.Path('README.md'); l=p.read_text().splitlines(True)
i=[n for n,x in enumerate(l) if 'contradicts the code as it now stands' in x][0]
j=[n for n,x in enumerate(l) if 'Plan review pass 3' in x][0]
l[i]=l[i].replace('`keel-plan` |','`keel-discover` |'); l[j]=l[j].replace('`keel-discover` |','`keel-plan` |')
p.write_text(''.join(l))
PY
