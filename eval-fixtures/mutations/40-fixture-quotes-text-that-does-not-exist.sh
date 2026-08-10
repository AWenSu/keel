# expect: fixture-quote-verbatim
# class:  declared-not-wired
# origin: gate-2
python3 - <<'PY'
import pathlib
p=pathlib.Path('eval-fixtures/16-merge-push-consent.md'); l=p.read_text().splitlines(True)
for i,x in enumerate(l):
    if x.startswith('>'): l[i]="> This sentence was invented and appears in no source file whatsoever\n"; break
p.write_text(''.join(l))
PY
