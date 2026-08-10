# expect: agent-model-pin
# class:  present-but-inert
# origin: gate-5 (the sed range re-triggered in the body)
python3 - <<'PY'
import pathlib
p=pathlib.Path('agents/keel-plan-lens-ceo.md'); s=p.read_text().replace('model: opus\n','',1)
p.write_text(s+"\n## Appendix\n\n---\nmodel: opus\n---\n")
PY
