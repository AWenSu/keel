# expect: rule-file-usable
# class:  self-disarm
# origin: self-audit + gate-5 (suffix names were pre-laundered)
printf 'Every task brief must name the branch it may commit to.\n' > rules/router.txt
