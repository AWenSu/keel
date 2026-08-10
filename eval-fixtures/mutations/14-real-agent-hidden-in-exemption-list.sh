# touches-checker: yes — this mutation IS the exemption-list disarm
# expect: exemption-guard
# class:  self-disarm
# origin: gate-4 (nothing asserted a NONAGENT token was not a real agent)
perl -i -pe 's/^NONAGENT="/NONAGENT="test-engineer /' eval-fixtures/check-structure.sh