# expect: agent-tools-pin
# class:  present-but-inert
# origin: gate-5
python3 - <<'PY'
import pathlib,re
p=pathlib.Path('agents/keel-plan-lens-ceo.md'); s=re.sub(r'^tools:.*\n','',p.read_text(),count=1,flags=re.M)
p.write_text(s+"\n## Appendix\n\n---\ntools: Read, Grep, Glob\n---\n")
PY
