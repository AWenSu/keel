# expect: model-pin-documented
# class:  check-cannot-fail
# origin: gate-5 (first match anywhere in the row)
perl -i -pe 's/^model: opus/model: haiku/' agents/keel-exec-reviewer-security.md
perl -i -pe 's/\| Security axis only/| Security axis only, haiku-fast triage/' README.md
perl -i -pe 's/\| 只看資安軸/| 只看資安軸（haiku 快篩）/' README.zh-TW.md
perl -i -pe 's/\| Security review axis/| Security review axis (haiku triage)/' skills/keel-workflow/SKILL.md
