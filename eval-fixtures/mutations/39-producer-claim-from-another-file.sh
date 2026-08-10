# expect: section-defined
# class:  check-cannot-fail
# origin: gate-4 (the exemption was repo-global)
python3 - <<'PY'
import pathlib,re
p=pathlib.Path('skills/keel-plan/SKILL.md'); s=p.read_text()
p.write_text(re.sub(r'^## Signals$', '**Signals:**', s, count=1, flags=re.M))
q=pathlib.Path('skills/keel-finish/SKILL.md')
q.write_text(q.read_text()+"\nkeel-finish writes `## Signals` into the plan.\n")
PY
