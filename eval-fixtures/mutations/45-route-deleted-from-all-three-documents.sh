# expect: route-count
# class:  check-cannot-fail
# origin: gate-5 (cross-checked against each other and nothing else)
python3 - <<'PY'
import pathlib,re
for f in ['skills/keel-workflow/SKILL.md','README.md','README.zh-TW.md']:
    p=pathlib.Path(f)
    p.write_text(re.sub(r'^\|[^\n]*(requirement itself is wrong|需求本身就錯)[^\n]*\n','',p.read_text(),flags=re.M))
PY
