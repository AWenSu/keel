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
    - 20260807 dev-pipeline-security-review-requirements 需求書 R6 (security
      exit gate section; added 2026-08-07)
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

Open the plan's **Success Criteria** checklist (dev-plan header). Read each
criterion aloud with its evidence and only mark it done once the user confirms
it on the spot — a one-line "does this one check out?" is enough; the user's
on-the-spot confirmation is what closes a box, never the agent's own
assessment. If the user disagrees, that criterion follows the existing unmet
path below. Unmet criteria are reported plainly, with why, and never silently
dropped. A criterion the user agrees
to ship without is deferred work: record it in the repo's `TODOS.md` using
dev-plan-review's entry format — unwritten deferrals evaporate.

If `CONTEXT.md` exists: any new domain term this work introduced belongs in
it, and public names in the diff should match its vocabulary. One-line check,
report mismatches — don't rename code at this stage. Same check for ADRs:
a decision this work locked that is hard to reverse + surprising without
context + a real trade-off → offer a one-paragraph ADR before integrating.
If the plan file already has a matching `## ADR: <decision name>` section —
because `dev-plan-review` Step 5 already produced it at the moment the
decision was made — skip the offer (found → skip, not found → offer as
before).

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

## Part 2c: Security exit gate

Runs every time, regardless of project type — even a plan that never
triggered `dev-plan-lens-security` or `dev-exec-reviewer-security` still
executes this section; "nothing to check" is a claim, and like every other
claim in this file it needs to show its work. Same Iron Law as Part 1: every
line below needs evidence produced **this session**, not a stale scan.

Four checks (verbatim from the security requirements doc's R6):

| # | Check | Evidence | Tool-absent handling |
|---|-------|----------|----------------------|
| 1 | Full-branch secrets scan | gitleaks/semgrep output, this session | No such tool installed → state "secrets scan: not executed — no gitleaks/semgrep available" explicitly; never blocks (see BLOCKED condition below). |
| 2 | Execution-stage security axis findings closed | Every Critical/Important `dev-exec-reviewer-security` finding (dev-execute Step 3c, R4-triggered), pulled from `.dev-pipeline/progress.md`'s per-task ledger lines and each `task-N-report.md`, is either resolved (cite the fix commit) or has an explicit user risk-acceptance decision (format below) | n/a — always runs |
| 3a | New-dependency CVE / maintenance-status scan | Scanner output if one is installed | Same tool-existence rule as (1): state "not executed" plainly if absent, never BLOCK on absence |
| 3b | New-dependency **package-existence verification** (anti-slopsquatting) | For every new dependency name introduced on this branch, confirm against its registry that the name actually exists and resolves to the intended package — the same check `dev-exec-reviewer-security`'s checklist item 9 defines | Pure LLM + registry lookup, no external tool involved — **no "not executed" exemption; this one must actually run** |
| 4 | Plan-stage security lens findings | If `dev-plan-lens-security` ran in `dev-plan-review` (visible in the plan's `REVIEW REPORT`), the disposition of every Critical finding it raised — matched by its `## Task N` tag, `plan-global`-tagged findings reconciled once, not per task — is resolved or explicitly risk-accepted | n/a — check only fires when the lens ran |

### BLOCKED condition

Any unresolved Critical finding from **(2), (3b), or (4)** with no explicit
user risk-acceptance decision → dev-finish returns:

```
BLOCKED: 資安 finding 未關閉
```

and does not proceed to Part 3. (1) and (3a) do **not** trigger this BLOCKED
path on their own — reporting "not executed" for those two IS the honest
disclosure this file asks for everywhere else; it is a stated absence, not
"pretending the check ran." The plan's Global Constraints rule out requiring
an external/paid security service, and a hard requirement here would BLOCK
every run in an environment without the tool, which is alarm fatigue, not
signal — if a scanner IS installed, its real output upgrades that line past
"not executed," but it is never required. Treating an unresolved Critical
from (2)/(3b)/(4) as anything less than blocking is the failure this gate
exists to prevent.

### Risk-acceptance decisions

When the user explicitly accepts a Critical finding instead of fixing it,
record it the same way Part 2's deferred work is recorded: the repo's
`TODOS.md`, using `dev-plan-review`'s existing entry format (What / Why
deferred / Effort / Priority), plus the finding's `file:line` appended. No
new ledger schema in `.dev-pipeline/progress.md` for this — in this
single-user interactive pipeline the decider is always the user present at
the time, and the timestamp is recoverable from the commit or the `TODOS.md`
entry itself, so a dedicated "decider"/"time" field would be ceremony with no
reader.

## Part 3: Integrate the branch

**Never merge, rebase, push, or force-push into `main`/`master` without
explicit user consent** — the rule is defined in dev-workflow and binds this
stage exactly as it binds dev-execute. Integration is where the pipeline's
work becomes irreversible; the branch protection does not lapse at the finish
line.

When this stage dispatches the final whole-branch `code-reviewer` (per
`dev-execute`'s Finish step), tell it which tasks already had a
`dev-exec-reviewer-security` pass — read from the `.dev-pipeline/progress.md`
ledger lines (`security axis skipped — ...` vs. an R4-triggered pass) — so it
spends its budget on cross-task composition risk instead of re-scanning
single tasks the security axis already covered. This changes only the
context `dev-finish` hands to `code-reviewer` at dispatch time, not the
`code-reviewer` agent definition itself.

All boxes checked, evidence fresh — present the user exactly these options:

1. **Merge** back to the base branch locally
2. **Push + PR** — PR body summarizes what/why, links spec + plan. If the
   project hits PROJECT-TYPE-GUIDE.md's "a real deploy step (not
   preview-only)" criterion, additionally produce a Release Runbook
   (pre-deploy checks, deploy command, post-deploy verification commands,
   rollback command) and write it into the PR body; otherwise skip it.
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
