# Fixture 18: Release Runbook fires on the deploy, not on the platform

**Rule source:** `PROJECT-TYPE-GUIDE.md` cross-cutting —

> **Release Runbook** (pre-deploy checks, deploy command, post-deploy
> verification, rollback): required for **any** project type with a real
> deploy step, not preview-only — the criterion is the deploy, not the
> platform.

Consumed by `skills/keel-finish/SKILL.md` Part 3 option 2 (Push + PR).

This fixture exists because the criterion was originally written **inside**
the Serverless/edge section while being referenced as if it were universal —
a full-stack app with a real deploy step would have read right past it.

## A — full-stack web app that ships to production

**Scenario:** the project deploys to a real environment on merge. Integration
option 2 (Push + PR) is chosen. Project type is "Full-stack web app", whose
Quick-matrix row says nothing about a Runbook.

**Expected:** a Release Runbook is produced into the PR body — pre-deploy
checks, the deploy command, post-deploy verification commands, the rollback
command. The Quick-matrix row's silence is not an exemption; the cross-cutting
rule governs and the criterion is the deploy.

**Not expected:** skipping it because only the Serverless/edge row mentions
Runbooks. That reading is the defect this rule was rewritten to close.

## B — Serverless with preview-only deploys

**Scenario:** a Cloudflare Workers project. `keel-finish` drove a **preview**
deploy for evidence. Nothing ships to a real environment in this change.

**Expected:** no Runbook. "Preview-only" is the stated exemption, and the
Serverless/edge section says so outright: *preview-only deploys don't need
this.*

## C — no deploy step at all

**Scenario:** a CLI tool distributed by `git clone`. Nothing deploys.

**Expected:** no Runbook. Nothing to write pre-deploy checks or a rollback
command for.

## D — option 1 or 3, not option 2

**Scenario:** the project has a real deploy step, but the user picks option 1
(merge locally) or option 3 (keep the branch).

**Expected:** no Runbook now — the rule is attached to option 2, whose output
is a PR body. Nothing is shipping yet.

**Boundary worth stating:** a merge to a branch that auto-deploys makes
option 1 a deploy in disguise. That case is **G9** (an irreversible operation
outside the repo), not this rule — ask before merging, naming the target.

## E — Runbook contents are four specific things

**Scenario:** the criterion is met and a Runbook is written.

**Expected:** all four parts present — pre-deploy checks, deploy command,
post-deploy **verification commands**, rollback command. A Runbook without a
rollback command is the one that matters most and the one most often omitted;
a Runbook without post-deploy verification asserts success rather than
checking it, which contradicts this pipeline's Iron Law.

## Not expected (any scenario)

- Reading the criterion as platform-scoped when the text says the criterion
  is the deploy
- Producing a Runbook for a preview-only deploy (noise; it trains readers to
  skim them)
- A Runbook missing the rollback or the verification commands
