# expect: section-defined
# class:  declared-not-wired
# origin: the defect P11 exists for
python3 - <<'PY'
import pathlib,re
p=pathlib.Path('skills/keel-plan/SKILL.md'); s=p.read_text()
p.write_text(re.sub(r'^## Signals$', '**Signals:**', s, count=1, flags=re.M))
PY
