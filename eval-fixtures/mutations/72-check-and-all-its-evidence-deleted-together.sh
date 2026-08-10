# touches-checker: ratchet — co-deletion is exactly what the ratchet guards
# expect: ratchet
# class:  co-deletion-blind
# origin: gate-7 — a check, its id, its mutation and its registry line
# removed in one edit; four separate equality controls all reported
# success on the smaller board
python3 eval-fixtures/mutations/lib-delete-a-check.py
