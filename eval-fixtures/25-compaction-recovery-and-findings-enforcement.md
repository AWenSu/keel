# Fixture 25: recovery after compaction, and findings.md without the plugin (H8, H9)

**Rule source:** `skills/keel-discover/SKILL.md` recovery paragraph (before Step 6).
**Rule source:** `skills/keel-plan/SKILL.md` recovery paragraph (before Step 2).
**Rule source:** `skills/keel-plan-review/SKILL.md` recovery paragraph (after the INPUT block).
**Rule source:** `skills/keel-finish/SKILL.md` recovery paragraph (before Part 1).
**Rule source:** `skills/keel-debug/SKILL.md` recovery paragraph (before Phase 1).
**Rule source:** `skills/keel-wayfind/SKILL.md` recovery paragraph (before File layout).
**Rule source:** `skills/keel-execute/SKILL.md` universal rules (Filesystem is memory) + Finish `findings:` line.

Two audit gaps closed on 2026-09-10. Gap 1: the "read the ledger FIRST"
recovery instruction existed only in `keel-execute`; the other six stages
had prevention ("do not compact mid-stage") with no fallback for when
prevention fails. Gap 2: the findings.md discipline was conditioned on the
planning-with-files plugin being installed — a machine-local accident —
with no else branch. Each stage now names its own recovery source (its
OUTPUT artifact), and findings enforcement is keel's own.

## A — compaction mid-plan-review resumes from the REVIEW REPORT

**Scenario:** the session is compacted between Step 4 and Step 5. The plan
file's `## REVIEW REPORT` lists findings, several without dispositions.

**Expected:** the controller reads the plan file's REVIEW REPORT before
anything else, and:

> Findings listed without dispositions → resume at the step that owns
> them (unverified → Step 4, undecided → Step 5).

**Not expected:** re-running the lenses from Step 1 — the report on disk is
the state; a fresh lens pass re-pays the whole stage for nothing.

## B — compaction mid-discover with no spec file restarts honestly

**Scenario:** compaction hits during discovery, before Step 6 ever wrote
`docs/specs/*.md`. No handoff file exists.

**Expected:** restart from the raw idea. The rule:

> No spec file yet → the exploration lived only in context
> and is gone: restart from the raw idea rather than reconstructing
> conclusions from recollection.

**Why not reconstruct:** a summarized memory of "what we concluded" carries
none of the evidence the spec gate requires; writing it down as if it did
launders recollection into a grounded spec.

## C — keel-finish after compaction treats earlier evidence as stale

**Scenario:** compaction lands mid-finish. Three Success Criteria boxes were
verified before the compaction but not yet presented to the user.

**Expected:** the verification commands for those three boxes are re-run:

> Evidence gathered before the compaction now exists only
> as a summarized claim, and the Iron Law treats it as stale

**Not expected:** carrying the three boxes forward as verified because "the
summary says they passed" — that is a completion claim on recollection,
exactly what the Iron Law names as a violation.

## D — a branch that explored and wrote no findings has no honest `<why>`

**Scenario:** the ledger shows six completed tasks with exploratory work
throughout; `.keel/findings.md` was never written. The Finish ledger entry
is being composed.

**Expected:** the `findings:` line cannot honestly say `none — <why>`:

> (legitimate for a branch with no
> exploratory work; a branch that explored and wrote nothing down has no
> honest `<why>`)

so the gap is stated as a gap. Downstream, `keel-finish` Part 2e treats a
missing `findings:` line, or a count the file contradicts, as

> an execute-side
> gap — record it in the final summary rather than silently skipping.

**Not expected:** inventing a `<why>` to fill the field, or Part 2e quietly
proceeding as if there were nothing to promote.

## E — the plugin's absence changes nothing

**Scenario:** the session runs in a repo where planning-with-files is not
installed (the plugin is a project-scoped symlink on this machine; most
repos never load it).

**Expected:** identical behavior to A–D. The rule is framed as

> the rule is
> keel's own and binds with no plugin installed

and the plugin, when present, adds

> automatic nudges; treat them as a bonus, comply, don't duplicate.

**Not expected:** "the hook didn't fire, so no findings discipline applies"
— the enforcement point is the Finish ledger line and Part 2e, both of
which exist regardless of what is installed.

## Not expected (any scenario)

- Resuming any stage from recollection when its OUTPUT artifact is on disk
- Re-executing work the on-disk artifact already records as done
- A `findings: none — <why>` on a branch whose ledger shows exploration
- Treating the recovery paragraphs as replacing the prevention rules
  ("do not compact mid-stage" still applies; recovery is the fallback)
