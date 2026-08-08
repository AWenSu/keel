# Rule inventory — structural coverage denominator

Every declared trigger/gate rule in the pipeline, one row each. This is the
denominator for `FIXTURE COVERAGE: N/M` (see `eval-fixtures/README.md`) —
borrowed from the structural-coverage-criteria approach (a workflow's
declared rules form a finite, countable graph; coverage = how many of those
edges a fixture actually exercises), not the path-count approach (denominator
is generally intractable for open-ended agents).

A rule earns "covered" only when an `eval-fixtures/NN-*.md` file cites it as
`Rule source` and includes both a trigger and a no-trigger scenario where the
rule text draws that boundary. Partial (trigger-only, no boundary case) is
listed as "partial," not "covered."

| # | Rule | Source | Fixture | Status |
|---|------|--------|---------|--------|
| 1 | Spec `Status:` must be `approved` before `dev-plan` proceeds | `dev-plan/SKILL.md:26-31` | `01`, `02` | covered |
| 2 | Spec-version drift during execution routes back to `dev-plan` | `dev-execute/SKILL.md:83-90` | `03` | covered |
| 3 | Feature matrix required for UI-heavy plans (2+ keyword hits) | `dev-plan/SKILL.md:98-109` | `04` | covered |
| 4 | ADR offer criteria (hard-to-reverse + surprising + real trade-off) | `dev-finish/SKILL.md:94-100` | `05` | covered |
| 5 | Backward route: plan contradicts code beyond one task's fix | `dev-workflow/SKILL.md:34` | — | not covered |
| 6 | Backward route: plan review round 3 still unresolved | `dev-workflow/SKILL.md:36` | — | not covered |
| 7 | Backward route: dev-finish can't produce required evidence | `dev-workflow/SKILL.md:37` | — | not covered |
| 8 | Backward route: debugging concludes the requirement is wrong | `dev-workflow/SKILL.md:38` | — | not covered |
| 9 | R4 condition 1 — task touches auth/encryption/upload/outbound/DB-query (semantic, not filename match) | `dev-execute/SKILL.md:126-132` | — | not covered |
| 10 | R4 condition 2 — diff adds/modifies externally-reachable endpoint | `dev-execute/SKILL.md:133` | — | not covered |
| 11 | R4 condition 3 — dev-plan marked task high-risk | `dev-execute/SKILL.md:134` | — | not covered |
| 12 | R4 condition 4 — plan-stage security lens previously flagged this task | `dev-execute/SKILL.md:135-140` | — | not covered |
| 13 | R4 condition 5 — diff matches sensitive-string pattern | `dev-execute/SKILL.md:141-143` | — | not covered |
| 14 | G4 gate, ORCHESTRATED — plan-conflicting finding goes to the user, never self-decided | `dev-execute/SKILL.md` Fix loop step 4 | — | not covered |
| 15 | G4 gate, INLINE — same rule restated for the no-subagent path | `dev-execute/SKILL.md` INLINE mode step 3 | — | not covered |
| 16 | dev-finish Part 2c BLOCKED — unresolved Critical from (2)/(3b)/(4) blocks integration | `dev-finish/SKILL.md:138-156` | — | not covered |
| 17 | Security lens dispatch trigger (2+ security keywords / high-risk marker / new endpoint) | `dev-plan-review/SKILL.md` Step 1 | — | not covered |

**Current coverage: 4/17 rules (24%).** Rows 5-8 and 14-16 are the highest-value
next additions — they're the ones most likely to silently regress from an
unrelated wording edit nearby (same failure class as the Task 7
README-drift finding this session caught). Rows 9-13 (R4 conditions) are
lower priority individually since they share one dispatch mechanism; a
single fixture with 5 sub-scenarios would cover all five economically.

Update this table's `Fixture`/`Status` columns whenever a new
`eval-fixtures/NN-*.md` file is added.
