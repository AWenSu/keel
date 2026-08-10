# expect: rule-file-usable
# class:  self-disarm
# origin: gate-5
python3 -c "
import pathlib
p=pathlib.Path('rules/manifest.tsv'); l=p.read_text().splitlines(True); p.write_text(''.join(l+[l[2]]))"
