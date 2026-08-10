# expect: tables-generated
# class:  check-cannot-fail
# origin: gate-5
python3 - <<'PY'
import pathlib,re
for f in ['skills/keel-workflow/SKILL.md','README.md','README.zh-TW.md']:
    p=pathlib.Path(f)
    p.write_text(re.sub(r'^\| \*{0,2}G6\*{0,2} \|[^\n]*\n','',p.read_text(),flags=re.M))
PY
