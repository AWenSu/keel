# expect: rule-file-usable
# class:  self-disarm
# origin: gate-5 (grep -F reads a multi-line pattern as an OR)
python3 - <<'PY'
import pathlib
p=pathlib.Path('rules/no-general-purpose.txt'); p.write_text("\n"+p.read_text())
q=pathlib.Path('skills/keel-workflow/SKILL.md')
q.write_text(q.read_text().replace("Never dispatch `general-purpose` from this pipeline — name the `subagent_type`.",""))
PY
