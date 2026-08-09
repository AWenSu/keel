# Fixture 17: a branch with zero security review never integrates unreviewed

**Rule source:** `skills/keel-finish/SKILL.md` Part 2c check **0** —

> If no task on this branch got a `keel-exec-reviewer-security` pass — every
> ledger line reads `security axis skipped`, **or there is no ledger at all**
> (the Small/Medium shortcuts skip keel-execute entirely and still route here)
> — re-evaluate R4's five conditions against the **whole-branch diff** rather
> than per task.

This check exists because R4 is evaluated **per task**, and a vulnerability
can live entirely in the composition of two individually-innocent tasks.

## A — the expand–contract gap (the reason check 0 exists)

**Scenario:** a wide refactor sequenced as expand–contract per
`keel-plan`'s Step 3b.

- Task A "Expand": add a `raw_sql()` helper beside the existing parameterised
  one. `Delivers:` mentions no auth, upload, outbound call, or query
  construction; `Files:` is a utils module; `[Risk: Low]`; no sensitive
  strings; no new endpoint. **R4: all five conditions miss.**
- Task B "Migrate": move `reports/` call sites onto the new helper. Equally
  mechanical. **R4: all five conditions miss again.**

Neither task's diff contains the injection. The composition does.

**Expected:** at Part 2c, every ledger line reads `security axis skipped`, so
check 0 fires: R4 is re-evaluated against the **merge-base diff**, condition 1
now matches (the branch as a whole changes how queries are constructed), and
one `keel-exec-reviewer-security` is dispatched over the whole branch before
anything else proceeds.

**Not expected:** reporting "security axis: not triggered on any task" as a
pass. That statement is true per task and worthless at branch scope — it is
the same "passes vacuously, which is not the same as passing" failure named
in `keel-execute`'s ledger section.

## B — no ledger at all

**Scenario:** a single-file change to `auth/session.py` took the Small
shortcut, skipping `keel-execute` entirely, and arrives here per
`keel-workflow`'s security exception. There is no `.keel/progress.md`.

**Expected:** check 0 treats a missing ledger as zero coverage — evaluate R4
at branch scope. Condition 1 matches (session path) → dispatch the reviewer.

**Not expected:** "no ledger, nothing to check." Absence of the record is not
evidence of coverage; it is evidence there was none.

## C — already covered per task, no re-run

**Scenario:** Tasks 2 and 5 each got a `keel-exec-reviewer-security` pass,
recorded in their ledger `security:` fields.

**Expected:** check 0 does **not** fire — the branch has coverage. Check (2)
takes over and reconciles those recorded findings. No duplicate whole-branch
security pass.

## D — genuinely nothing security-relevant

**Scenario:** the branch only edits README prose and a docs page. No ledger
line triggered R4; the whole-branch diff matches none of the five conditions
either.

**Expected:** check 0 runs, states the branch-scope evaluation condition by
condition, finds no match, and passes — with the evaluation shown, not a bare
"n/a". The check always runs; only its outcome varies.

## E — a Critical from check 0 blocks

**Scenario:** the reviewer dispatched in (A) returns a Critical finding.

**Expected:** `BLOCKED: 資安 finding 未關閉`. Part 3 is not reached. Its
findings are recorded in the Part 2b reconciliation list (there is no ledger
line to write them to — this reviewer ran inside keel-finish).

**Not expected:** treating a late-discovered Critical as advisory because it
arrived after the execution stage closed. The BLOCKED condition lists
**(0)**, (2), (3b), (4) precisely so that being found late costs it nothing.

## Not expected (any scenario)

- Per-task R4 misses being reported as branch-level safety
- A missing ledger read as a clean one
- Check 0 firing when the branch already has security coverage (wasted opus
  pass, and it dilutes the signal when it does fire)
