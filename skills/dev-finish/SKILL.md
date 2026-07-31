---
name: dev-finish
description: Use when implementation appears complete, before claiming done, committing final work, or opening a PR — enforces fresh verification evidence for every claim, exercises the change end-to-end, then integrates the branch. Stage 5 (final) of the unified dev pipeline.
provenance:
  synthesized: 2026-07-14
  sources:
    - superpowers:verification-before-completion @6.1.1 (Iron Law, Gate Function, claim-evidence table, red-green regression rule)
    - superpowers:finishing-a-development-branch @6.1.1 (integration options; typed discard confirmation added 2026-07-23)
    - built-in /verify concept (drive the real flow, not just the test suite)
    - gstack TODOS.md deferral + mattpocock ADR offer (added 2026-07-23)
---

# dev-finish — Verification & Branch Integration

```
INPUT   implementation complete on a non-main branch; the plan's success
        criteria; the ledger at .dev-pipeline/progress.md
OUTPUT  every claim backed by fresh evidence from this session; open items
        reconciled (Part 2b); branch integrated by the user's chosen option
```

<IRON-LAW>
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.
If you haven't run the verification command in this session, in this state
of the code, you cannot claim it passes. Violating the letter of this rule
by paraphrase ("should work now", "looks good") violates the rule.
</IRON-LAW>

## Part 1: The Gate Function

Run this before ANY status claim — "done", "fixed", "passing", "ready":

```
1. IDENTIFY  What command proves this claim?
2. RUN       Execute the FULL command — fresh, complete, no cached result
3. READ      The whole output. Exit code. Count the failures yourself.
4. VERIFY    Does the output actually confirm the claim?
5. ONLY THEN Make the claim, with the evidence in hand.
Skipping any step is lying, not verifying.
```

### Claim → required evidence

| Claim | Sufficient evidence | NOT sufficient |
|-------|--------------------|----------------|
| Tests pass | Test run output: 0 failures, this session | Previous run; "should pass" |
| Bug fixed | Red-green cycle (below) | The fix "addresses the cause" |
| Feature works | You drove the real flow and saw it | Unit tests green; typecheck clean |
| Agent completed X | VCS diff shows the changes | Agent reported "success" |
| Linter/build clean | Full command output, zero errors | Linter alone (linter ≠ compiler) |

### Red-green regression rule (for every bug fix)

```
Write the regression test → run it (passes with fix) →
revert the fix → run it (MUST FAIL) →
restore the fix → run it (passes)
```

A regression test that never went red proves nothing.

### Drive the real flow

Tests exercise what the tests exercise. Additionally run the actual affected
surface once: start the app/CLI/endpoint, perform the changed behavior,
observe the result. Any change to product source has a runtime surface to
drive; "all tests pass but the feature doesn't work" is a routine failure.

### Rationalization table — excuses that mean STOP

| Excuse | Reality |
|--------|---------|
| "Agent said success" | Verify independently |
| "It worked before my change" | Your change is exactly what's unverified |
| "Just a small refactor" | Small refactors break builds daily |
| "Great! Done!" (before running anything) | Satisfaction is not evidence |

## Part 2: Success criteria check

Open the plan's **Success Criteria** checklist (dev-plan header). Check every
box with evidence, or say plainly which are unmet and why. Unmet criteria are
reported, never silently dropped. A criterion the user agrees to ship
without is deferred work: record it in the repo's `TODOS.md` using
dev-plan-review's entry format — unwritten deferrals evaporate.

If `CONTEXT.md` exists: any new domain term this work introduced belongs in
it, and public names in the diff should match its vocabulary. One-line check,
report mismatches — don't rename code at this stage. Same check for ADRs:
a decision this work locked that is hard to reverse + surprising without
context + a real trade-off → offer a one-paragraph ADR before integrating.

## Part 2b: Open-items reconciliation

Loose ends live in three places that never talk to each other. Pull all three
into ONE list before integrating, because a decision that exists in only one of
them is a decision nobody will find again:

| Source | Where |
|--------|-------|
| Unresolved decisions | the plan's `REVIEW REPORT` section (dev-plan-review) |
| Deferred work | `TODOS.md` entries added during review |
| Flagged concerns | every `DONE_WITH_CONCERNS` in `.dev-pipeline/progress.md` and the task report files |

Every item gets one of two dispositions: **resolved** (with the evidence) or
**explicitly deferred** (with its `TODOS.md` line number). **An item with
neither blocks completion.** Present the reconciled list in the final summary
even when everything is clean — "nothing outstanding" is a claim, and like
every other claim here it needs to show its work.

## Part 3: Integrate the branch

**Never merge, rebase, push, or force-push into `main`/`master` without
explicit user consent** — the rule is defined in dev-workflow and binds this
stage exactly as it binds dev-execute. Integration is where the pipeline's
work becomes irreversible; the branch protection does not lapse at the finish
line.

All boxes checked, evidence fresh — present the user exactly these options:

1. **Merge** back to the base branch locally
2. **Push + PR** — PR body summarizes what/why, links spec + plan
3. **Keep the branch** — user integrates later
4. **Discard** — the work was exploratory. This is the pipeline's only
   irreversible deletion path: list exactly what will be deleted (branch
   name, commit list, worktree path), then require the user to type
   `discard` verbatim. Wait for that exact word — "yes", "ok", "sure" do
   not count.

Then clean up: worktree removed if one was used, ledger closed with a final
line, plan file marked complete. Report outcomes faithfully — if anything was
skipped or is unverified, that goes in the final summary, not under it.

## Red flags

- Committing with a failing test "to fix in a follow-up" the user didn't ask for
- Writing the completion summary before running the verification commands
- Deleting the branch before the user chose an integration option
