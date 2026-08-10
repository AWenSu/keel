# expect: rule-text-verbatim
# class:  present-but-inert
# origin: gate-5
python3 - <<'PY'
import pathlib
C="Do not pass a `model` override at the call site — each agent file pins its own."
p=pathlib.Path('skills/keel-debug/SKILL.md'); s=p.read_text()
p.write_text(s.replace(C,"<!-- superseded\n"+C+"\n-->",1))
PY
