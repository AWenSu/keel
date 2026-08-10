---
name: keel-finish
description: Use when implementation appears complete, before claiming done, committing final work, or opening a PR — enforces fresh verification evidence for every claim, exercises the change end-to-end, names the signals that would later show it worked or that the requirement was wrong, then integrates the branch. Stage 5 (final) of the keel pipeline.
provenance:
  synthesized: 2026-07-14
  sources:
    - superpowers:verification-before-completion @6.1.1 (Iron Law, Gate Function, claim-evidence table, red-green regression rule)
    - superpowers:finishing-a-development-branch @6.1.1 (integration options; typed discard confirmation added 2026-07-23)
    - built-in /verify concept (drive the real flow, not just the test suite)
    - gstack TODOS.md deferral + mattpocock ADR offer (added 2026-07-23)
    - 20260807 keel-security-review-requirements 需求書 R6 (security
      exit gate section; added 2026-08-07)
---

# keel-finish — Verification & Branch Integration

```
INPUT   implementation complete on a non-main branch; the plan's success
        criteria; the ledger at .keel/progress.md
OUTPUT  every claim backed by fresh evidence from this session; open items
        reconciled (Part 2b); branch integrated by the user's chosen option
```

Missing INPUT → `BLOCKED: 缺 <field> → 退回 <keel-plan for success criteria,
keel-execute for the ledger>`. Part 2 opens the Success Criteria checklist
unconditionally; arriving without one means the gate has nothing to check
and will pass on an empty set.

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

**When step 4 comes back NO — the command ran but its output doesn't support
the claim — that is an undiagnosed bug, and it routes.** Not "run it again,"
not "write it in the summary and move on": stop keel-finish and take the
command plus its output into `keel-debug`, which already wants exactly that as
its Phase 1 red loop. Come back and re-run the whole gate from the top when
it's fixed. This is `keel-workflow`'s `keel-finish → keel-debug` backward route,
and it fires here.

Two cases that are **not** this route:

- The command produced a clear, specific failure you can fix in place — an
  ordinary red test. Fix it; that's a normal fix pass, not a stage handoff.
- The command cannot exist or cannot run at all — no test harness, no
  non-production environment. That IS the summary-disclosure path: state
  `not executed — <why>` plainly. A stated absence is honest; a claim resting
  on nothing is not.

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

**Name the target environment before driving anything.** If you cannot show
it is local, preview, or otherwise ephemeral, stop and get explicit consent
naming that environment and the exact command (gate G9). Migrations, deploys,
and writes against a live third party are never authorized by the Iron Law
alone — `not executed — no non-production environment available` is a
legitimate evidence line, structurally identical to the tool-absent exemption
Part 2c grants the secrets scan.

This is the one place the Iron Law can be turned against the user. The
pressure it creates is real and deliberate — no claim without fresh evidence —
and the only instance the repo makes available is sometimes staging with real
data, or a `wrangler` config whose only configured env is production. An
honest missing-evidence line costs a caveat in the summary; the alternative
costs the data.

### Rationalization table — excuses that mean STOP

| Excuse | Reality |
|--------|---------|
| "Agent said success" | Verify independently |
| "It worked before my change" | Your change is exactly what's unverified |
| "Just a small refactor" | Small refactors break builds daily |
| "Great! Done!" (before running anything) | Satisfaction is not evidence |

## Part 2: Success criteria check

Open the plan's **Success Criteria** checklist (keel-plan header). Read each
criterion aloud with its evidence and only mark it done once the user confirms
it on the spot — a one-line "does this one check out?" is enough; the user's
on-the-spot confirmation is what closes a box, never the agent's own
assessment. If the user disagrees, that criterion follows the existing unmet
path below. Unmet criteria are reported plainly, with why, and never silently
dropped. A criterion the user agrees
to ship without is deferred work: record it in the repo's `TODOS.md` using
keel-plan-review's entry format — unwritten deferrals evaporate.

If `CONTEXT.md` exists: any new domain term this work introduced belongs in
it, and public names in the diff should match its vocabulary. One-line check,
report mismatches — don't rename code at this stage. Same check for ADRs:
a decision this work locked that is hard to reverse + surprising without
context + a real trade-off → offer a one-paragraph ADR before integrating.
If the plan file already has a matching `## ADR: <decision name>` section —
because `keel-plan-review` Step 5 already produced it at the moment the
decision was made — skip the offer (found → skip, not found → offer as
before).

## Part 2b: Open-items reconciliation

Loose ends live in three places that never talk to each other. Pull all three
into ONE list before integrating, because a decision that exists in only one of
them is a decision nobody will find again:

| Source | Where |
|--------|-------|
| Unresolved decisions | the plan's `REVIEW REPORT` section (keel-plan-review) |
| Deferred work | `TODOS.md` entries added during review |
| Flagged concerns | every `DONE_WITH_CONCERNS` in `.keel/progress.md` and the task report files |

Every item gets one of two dispositions: **resolved** (with the evidence) or
**explicitly deferred** (with its `TODOS.md` line number). **An item with
neither blocks completion.** Present the reconciled list in the final summary
even when everything is clean — "nothing outstanding" is a claim, and like
every other claim here it needs to show its work.

## Part 2c: Security exit gate

Runs every time, regardless of project type — even a plan that never
triggered `keel-plan-lens-security` or `keel-exec-reviewer-security` still
executes this section; "nothing to check" is a claim, and like every other
claim in this file it needs to show its work. Same Iron Law as Part 1: every
line below needs evidence produced **this session**, not a stale scan.

Checks 1–4 are verbatim from the security requirements doc's R6; check 0 is
this pipeline's own addition, covering the case R6 assumed away — a branch on
which the execution-stage axis never ran at all.

| # | Check | Evidence | Tool-absent handling |
|---|-------|----------|----------------------|
| 0 | **Branch-level security coverage.** If no task on this branch got a `keel-exec-reviewer-security` pass — every ledger line reads `security axis skipped`, **or there is no ledger at all** (the Small/Medium shortcuts skip keel-execute entirely and still route here) — re-evaluate R4's five conditions against the **whole-branch diff** rather than per task. Any condition met at branch scope → dispatch `keel-exec-reviewer-security` once over the merge-base diff before continuing — by name, never `general-purpose`, and **do not pass a `model` override**: that agent pins its own | The branch-scope R4 evaluation, stated condition by condition, plus that reviewer's verdict if it fired | n/a — always runs |
| 1 | Full-branch secrets scan | Run `gitleaks detect --source . -v` (or `semgrep` if that's what's installed) this session and paste the summary line (leak count, or "no leaks found") | No such tool installed → state "secrets scan: not executed — no gitleaks/semgrep available" explicitly; never blocks (see BLOCKED condition below). |
| 2 | Execution-stage security axis findings closed | Every Critical/Important `keel-exec-reviewer-security` finding, read from the `security:` field of each task's ledger line in `.keel/progress.md` (keel-execute writes it whenever that axis runs), is either resolved (cite the fix commit) or has an explicit user risk-acceptance decision (format below). A ledger line with neither a `security:` field nor a documented skip is a **gap, not a pass** — say so and go get the answer | n/a — always runs |
| 3a | New-dependency CVE / maintenance-status scan | Scanner output if one is installed | Same tool-existence rule as (1): state "not executed" plainly if absent, never BLOCK on absence |
| 3b | New-dependency **package-existence verification** (anti-slopsquatting) | For every new dependency name introduced on this branch, confirm against its registry that the name actually exists and resolves to the intended package — the same check `keel-exec-reviewer-security`'s checklist item 9 defines | Pure LLM + registry lookup, no external tool involved — **no "not executed" exemption; this one must actually run** |
| 4 | Plan-stage security lens findings | Read the plan file's `## SECURITY FINDINGS` table. Every Critical row is resolved or explicitly risk-accepted — matched by its `## Task N` tag, `plan-global` rows reconciled once, not per task | **Section missing entirely** (no plan file, or a plan that never went through keel-plan-review — the common case) → this check cannot fire; say so as `plan-stage lens findings: no section — plan did not go through keel-plan-review`, and rely on check 0, which is what covers that branch. Do **not** report it as passed |

### BLOCKED condition

Any unresolved Critical finding from **(0), (2), (3b), or (4)** with no
explicit user risk-acceptance decision → keel-finish returns:

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
from (0)/(2)/(3b)/(4) as anything less than blocking is the failure this gate
exists to prevent.

**Where check 0's findings live.** That reviewer runs inside this stage, so
there is no ledger line to write them to and no fix loop already scheduled.
Record them directly in the Part 2b reconciliation list as their own source
row, with the same two dispositions everything else there gets: resolved
(cite the fix commit) or explicitly risk-accepted (`TODOS.md` entry). A
Critical from check 0 blocks exactly like one from (2) — being discovered
late is not a reason to weigh it less.

### Risk-acceptance decisions

**One finding, one decision.** A blanket "fine, ship it, I accept the risk"
covering several findings is not a decision — re-ask each one separately,
quoting that finding's own text. The user cannot weigh what they were never
shown individually.

When the user explicitly accepts a Critical finding instead of fixing it,
record it the same way Part 2's deferred work is recorded: the repo's
`TODOS.md`, using `keel-plan-review`'s existing entry format (What / Why
deferred / Effort / Priority), plus the finding's `file:line` appended. No
new ledger schema in `.keel/progress.md` for this — in this
single-user interactive pipeline the decider is always the user present at
the time, and the timestamp is recoverable from the commit or the `TODOS.md`
entry itself, so a dedicated "decider"/"time" field would be ceremony with no
reader.

## Part 2d: Name the signal, before it becomes unaskable

Everything above verifies the change against a **test** environment. Nothing
so far asks whether it works where it will actually live, and after
integration nobody is holding the question any more — the context that knew
what "working" meant is about to end.

So, in one line each, before integrating:

- **What would tell us this worked?** A metric, a log line, a support-ticket
  category that should shrink, a screen someone actually uses. Name where it
  is read, not just that it exists.
- **What would tell us this was wrong?** Not "a bug appears" — the specific
  observation that would mean the *requirement* was mistaken rather than the
  code. That is the signal that routes back to `keel-discover`, and it is
  almost impossible to recognise later if nobody wrote it down now.
- **Is anything instrumented to produce either?** If the answer is no and the
  change is worth watching, that is a `TODOS.md` entry, not a shrug.

All three answers go into the plan file under `## Signals`, next to the
Success Criteria they outlive — the instrumentation one as a `TODOS.md`
reference when the answer was "not instrumented yet".

**No plan file?** The Small and Medium shortcuts skip `keel-plan` and still
route here. Then the answers go in the PR body, or `TODOS.md` if there is no
PR — the question is about the work, not about which artifact happens to
exist. Part 2c check 0 makes the same allowance for its own missing input. **One question, asked once** — this is not a new gate
and it does not block integration; a user who answers "nothing to watch, it's
a docs fix" has answered it correctly.

Why it sits here rather than in a sixth stage: the pipeline ends at merge,
which is where the code's life starts. A full post-release stage would be a
scope this repo cannot honestly claim to run — but the *cheap* half of a
product loop is writing down, while the context still exists, what reality
would have to show for the work to count. Skipping that is what makes the
loop unclosable, not the absence of a stage.

## Part 3: Integrate the branch

**Never merge, rebase, push, or force-push into `main`/`master` without
explicit user consent** — the rule is defined in keel-workflow and binds this
stage exactly as it binds keel-execute. Integration is where the pipeline's
work becomes irreversible; the branch protection does not lapse at the finish
line.

**`keel-execute` dispatches the final whole-branch `code-reviewer`, not this
stage** — it holds the base commit and the ledger context that reviewer needs.
By the time work reaches here, that review and its one fix pass have already
happened. keel-finish's job is to confirm it did: **read the `final-review:`
line from `.keel/progress.md`** — verdict, findings with their `file:line`,
each one's disposition, and the coverage figure. No such line is a **gap, not
a pass**; say so and go get it, the same way Part 2c check (2) treats a
missing `security:` field. Confirming, not re-running; two whole-branch reviews at
inherit-strongest is the most expensive way to duplicate work in this
pipeline.

Do not pass a `model` override at the call site — each agent file pins its own.

All boxes checked, evidence fresh — present the user exactly these options:

1. **Merge** back to the base branch locally
2. **Push + PR** — PR body summarizes what/why, links spec + plan. If the
   project hits PROJECT-TYPE-GUIDE.md's "a real deploy step (not
   preview-only)" criterion, additionally produce a Release Runbook
   (pre-deploy checks, deploy command, post-deploy verification commands,
   rollback command) and write it into the PR body; otherwise skip it.
3. **Keep the branch** — user integrates later
4. **Discard** — the work was exploratory. The pipeline's most destructive
   path: list exactly what will be deleted (branch name, commit list,
   worktree path), then require the user to type `discard` verbatim. Wait
   for that exact word — "yes", "ok", "sure" do not count.

Then clean up: ledger closed with a final line, plan file marked complete.

**Removing a worktree is its own deletion path, and it runs under options
1–3 too.** Before removing one, run `git status --porcelain` inside it. Any
uncommitted change or untracked file — a `.env.local`, downloaded fixtures,
the throwaway harness `keel-debug` asks you to build — is content `git` cannot
recover, so list it and require the user to type `remove` verbatim. Clean
worktree, nothing untracked → remove it without asking. Option 4's typed
confirmation covers the branch and its commits; it does not cover a dirty
worktree, and the pipeline routes risky work into worktrees on purpose
(`keel-workflow`'s INFRA row).

Report outcomes faithfully — if anything was skipped or is unverified, that
goes in the final summary, not under it.

## Red flags

- Committing with a failing test "to fix in a follow-up" the user didn't ask for
- Writing the completion summary before running the verification commands
- Deleting the branch before the user chose an integration option
