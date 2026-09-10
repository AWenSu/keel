# Fixture 28: gate stops and BLOCKED routes (A6, B2, B3, B4, B5)

**Rule source:** `skills/keel-workflow/SKILL.md` Backward routes; Stage contracts; Protocol — the gates that may stop the pipeline for a user answer.
**Rule source:** `skills/keel-plan/SKILL.md` INPUT block; Step 6 (Quiz the user on the breakdown).
**Rule source:** `skills/keel-plan-review/SKILL.md` INPUT block; Step 0 (Premises); Step 3 (decision taxonomy); Step 5 (Ask the user).
**Rule source:** `skills/keel-execute/SKILL.md` INPUT block; ORCHESTRATED pre-flight plan review; per-task loop step 0; INLINE mode step 1.
**Rule source:** `skills/keel-finish/SKILL.md` INPUT block.
**Rule source:** `skills/keel-discover/SKILL.md` INPUT block.
**Rule source:** `skills/keel-debug/SKILL.md` INPUT block; Phase 3 — Hypothesise.
**Rule source:** `skills/keel-wayfind/SKILL.md` INPUT block.

Six rules about the same thing from two directions: **when the pipeline is
allowed to stop and wait for a human** (B2–B5), and **where work goes when it
cannot start at all** (A6). They share one failure mode — a stop that is
skipped and a stop that is invented look identical from the outside, and both
are wrong. The B rules carry a stronger claim than "documented":

> A "should I continue?" that is not one of the rows above is forbidden —
> generic checkpoint questions burn the user's time and are not a safety
> mechanism.

> The distinction matters: G1–G9 are not checkpoints, they are the
> points where proceeding without an answer would either skip a hard gate or
> do something that cannot be undone. Treating the table as shorter than it is
> does not make the pipeline faster; it makes it unsafe in exactly the places
> speed is worth the least.

The list is closed in **both** directions. Fixture `19` states that for G7/G8;
this fixture pins the four gates in the middle (G2–G5) and the route the
pipeline takes when a stage may not start. G1 is `01`/`02`, G6 is `10`/`11`,
G7/G8 are `19`/`16`, G9 is `15` — no scenario below re-tests those.

## A — A6: the BLOCKED line names a field *and* a destination

**Scenario:** `keel-plan-review` is invoked on a plan whose tasks carry
`Delivers:` and `Files:` but no `Interfaces:` block anywhere.

**Expected:** the stage does not start. It emits the contract miss in the one
declared shape, with the owing stage named:

> Missing INPUT → `BLOCKED: 缺 <field> → 退回 keel-plan`. Do not review a plan
> whose task fields are absent; the findings would have nothing to anchor to.

The router's declaration is what makes this a route rather than an error
message:

> | A stage's INPUT contract is unsatisfiable (see below) | any | the stage that owes the missing artifact |

> Every stage skill declares an **INPUT** block (what must exist before it may
> start) and an **OUTPUT** block (what it guarantees on completion). Check INPUT
> on entry and OUTPUT before announcing completion. On a miss, emit one line and
> take the backward route — do not proceed on a partial artifact:

> BLOCKED: 缺 <artifact/field> → 退回 <stage>

**Not expected:** reviewing the plan anyway and raising "no Interfaces block"
as a finding — the stage's own text refuses that reading. Also not expected:
a `BLOCKED:` line with no `→ 退回` half. The destination is the rule; a naked
`BLOCKED` is an error report and leaves the work with nobody.

> Contract violations that surface mid-execution are the most expensive class of
> failure in this pipeline; checking on entry is nearly free.

## B — A6: routing back to the wrong stage is a distinct failure

**Scenario:** four stages hit an unsatisfiable INPUT in four different runs.
Each has exactly one correct destination, and they are not the same one.

**Expected**, per stage, verbatim from that stage's own INPUT block:

**B1 — `keel-plan` with no approved spec and no file-level requirements:**

> Missing INPUT → `BLOCKED: 缺 <approved spec | requirements naming exact file
> paths> → 退回 keel-discover`. This is the INPUT-contract miss every stage
> declares; it is distinct from the spec-status gate below, which fires when a
> spec *exists* but is not yet approved.

**B2 — `keel-finish` with no Success Criteria and no ledger:** the
destination is not one stage but two, chosen per missing field:

> Missing INPUT → `BLOCKED: 缺 <field> → 退回 <keel-plan for success criteria,
> keel-execute for the ledger>`.

**B3 — `keel-discover` with an idea too vague to state:** there is no earlier
stage, and the rule says so rather than picking the nearest one:

> This stage is the pipeline's entry point, so there is no earlier stage to
> route to: an idea too vague to state at all goes back to the person who
> asked, and no codebase access means the evidence rule below cannot be met.

**B4 — `keel-debug` with a symptom nobody can reproduce:** the destination is
resolved at runtime, not fixed:

> Missing INPUT → `BLOCKED: 缺 <symptom | runnable environment> → 退回 <the
> stage or person that owes it>`.

**Not expected:** collapsing all four into "→ 退回 keel-plan" because that is
the most common destination; routing `keel-discover`'s miss to a pipeline
stage; treating `keel-finish`'s two-target line as a choice the agent makes on
style rather than on which field is missing. A stage that routes back to the
wrong owner has produced a BLOCKED line that reads correct and moves the work
in a circle — indistinguishable, downstream, from not blocking at all.

## C — A6: the miss that is a mis-entry, not a missing artifact

**Scenario:** an oversized idea arrives at `keel-wayfind`, but its route is
already visible — the user knows the steps, there is just a lot of it.

**Expected:** this is not a BLOCKED-and-route-back; it is the wrong stage,
and `keel-wayfind` is the one INPUT block that says so:

> In practice the miss is the other way round: this is the wrong stage. Work that is merely large but whose
> route is visible goes straight to `keel-discover`; the fog is the entry
> condition, not the size.

**Not expected:** emitting `BLOCKED: 缺 <foggy oversized idea> → 退回 the
requester` at a user who supplied a perfectly good idea — the artifact is not
missing, the routing was. Nor: building the map anyway because the INPUT
line's literal field ("an idea too large for one session") is satisfied.

## D — A6: a missing field inside execution is still an INPUT miss

**Scenario:** `keel-execute` starts on a Medium-shortcut plan. Every task has
`Delivers:`, `Files:`, `Interfaces:`, `Skills:`; no task has a `Depends on:`
line at all.

**Expected:** step 0 blocks before any dispatch, and the rule distinguishes
absence from an explicit `none`:

> A task with **no `Depends on:` line at all** is a different thing from one
> reading `none` → `BLOCKED: 缺 Depends on → 退回 keel-plan`. The Medium
> shortcut can produce plans without it, and those are exactly the plans G2
> never confirmed.

**Boundary — `Depends on: none` on every task:**

> `Depends on: none` on every task is a legitimate graph, not a missing one.

**Boundary — a dependency naming a task that does not exist:** still blocks,
but as a different line, because it is a different defect:

> A task naming a dependency that does not exist in the plan is a plan bug →
> `BLOCKED: Depends on 指向不存在的 task → 退回 keel-plan`.

**Boundary — every task has `Depends on:`, but the plan came down the Medium
shortcut:** nothing blocks; the edges are present. What the plan never had is
a confirmer — the Medium lane skips `keel-plan` (so no G2) and skips
`keel-plan-review` (so no eng lens). Until 2026-09-11 step 0 named only those
two provenances, which read as though the third did not exist; the audit that
produced this fixture found it, and the step now names it and requires the
disclosure:

> There is a third provenance and it is weaker than
> both: a `keel-workflow` **Medium** shortcut plan reaches here having had
> neither, because it never entered `keel-plan` (no Step 6) and never
> entered `keel-plan-review` (no lens). The edges are present and
> unconfirmed. Say so once in the ledger header —
> `breakdown: unconfirmed — Medium shortcut, no G2, no eng lens` — and hold
> the graph to a higher bar of suspicion before parallelising on it

**Not expected:** inferring the graph from task numbers; treating a
`Depends on:`-free plan as "all independent" and parallelising it;
parallelising an unconfirmed Medium-lane graph as freely as a G2-confirmed
one, or omitting the ledger-header disclosure because nothing was missing.
See fixture `22` for what `Depends on:` is consumed *for* once it exists.

## E — B2: the G2 quiz is two questions on titles and edges, not a plan read-back

**Scenario:** `keel-plan` has finished Step 5 self-review on an eleven-task
plan heading straight to `keel-execute`.

**Expected:** the quiz fires, and its shape is constrained on both ends —
what is shown and what is asked:

> Present the task list as titles + **Depends on** edges only (not the full
> plan) and ask two questions before exit:

> Does the granularity feel right — any task too coarse to review as one
> unit, or too fine to be worth a separate task?

> Are the `Depends on` edges correct — does each task depend only on tasks
> that genuinely gate it, no more and no less?

The gate table's own row says the same, and names the single skip condition:

> | G2 | keel-plan Step 6 | Task-breakdown granularity and `Depends on` edges (skipped only when the plan is heading into keel-plan-review anyway) |

**Not expected:** pasting the full plan and asking "does this look right?" —
that is a different question with a different answer rate, and the rule
excludes the plan body in as many words. Also not expected: asking only about
granularity because the edges "look obvious"; two questions is the contract.

## F — B2: the skip is conditional on the *next* stage, and it is the only skip

**Scenario:** the same plan, but it is >8 files with a new architecture and
`keel-plan` is about to offer keel-plan-review as path 1.

**Expected:** the quiz may be skipped, and the reason is not "the user is
busy" but that a named lens re-does the work:

> This is the only human checkpoint most plans get on their task breakdown —
> **keel-plan-review is optional and skipped by most plans** (only large/risky
> ones route through it). Skip this quiz only when the plan is heading into
> keel-plan-review anyway; `keel-plan-lens-eng` re-examines the breakdown and
> the `Depends on:` edges in more depth and asking twice wastes a round-trip.

`keel-execute` reads the same two provenances back out at step 0, which is
what makes the skip safe rather than merely permitted:

> confirmed by the user at G2, or re-examined by
> `keel-plan-lens-eng` when G2 was skipped because the plan routed through
> `keel-plan-review`.

**Not expected:** skipping the quiz because the plan is small, because the
user already approved the spec, or because the agent is confident in the
breakdown. **Also not expected:** running the quiz *and* routing to
keel-plan-review — the rule names that as a wasted round-trip, so
over-asking is a defect here, not safe over-compliance.

## G — B3: G3 is asked even when the premises are obvious

**Scenario:** `keel-plan-review` opens on a plan the same session just wrote.
The controller believes it already knows every premise.

**Expected:** it asks anyway, once, as one question:

> Before any review, confirm premises with the user in a single question:
> "This plan assumes <X, Y, Z>. Correct?" Wrong premises make every downstream
> finding worthless. This is the only question that must always be asked.

**Boundary — resumed after compaction:** the question is re-asked *unless*
its answer survived in the artifact, not in the agent's memory of it:

> re-ask Step 0's premise question unless its answer is already recorded in the report.

**Not expected:** folding the premise question into the Step 5 frontier batch
so it rides along with the Taste questions — Step 0 is *before any review*,
and a premise confirmed after the lenses ran confirms nothing. Also not
expected: three premise questions because there are three premises; it is one
question listing them.

## H — B4: the frontier decides batch membership; dependency, not convenience

**Scenario:** Step 5 has six survivors. Two are Mechanical. Of the four
remaining, "which auth pattern" gates "session storage format"; the other two
depend on nothing open.

**Expected:** the two Mechanical ones never reach the user —

> | **Mechanical** | One defensible answer exists | Auto-decide silently, apply the edit |

— and the four judgment calls go out in two batches, not one and not four:

> **Frontier** = every finding whose prerequisite decisions are already
> settled — answerable right now without guessing an answer you haven't
> heard yet.

> Ask the whole frontier in **one AskUserQuestion call** (up to its 4-question
> cap; a frontier over 4 splits across the fewest calls needed — never forced
> down to one question per call just to be safe).

> A question whose answer depends on another still open this batch belongs to a **later** batch, not
> this one — batching is bounded by dependency, not by convenience.

> Apply every answer from a batch to the plan file before computing the next
> batch's frontier — an answer often resolves or reshapes what's still open;
> drop questions an earlier answer already settled. The session's Step 5 is
> done when the frontier is empty.

**Not expected:** all four in one call because they fit under the cap — the
storage-format question would be answered against an auth pattern the user
has not chosen yet. **Also not expected:** four separate calls "to be safe";
the rule forbids that by name, and each extra round-trip is a real cost the
gate table exists to ration.

## I — B4: a User Challenge is never auto-decided, and never proceeds unanswered

**Scenario:** one surviving finding says the user's stated caching approach is
wrong. The evidence is strong and the controller considers it Mechanical.

**Expected:** the taxonomy forbids the reclassification, whatever the
evidence strength:

> | **User Challenge** | Review says the user's stated direction is wrong | NEVER auto-decide — ask with the 5-field format |

and the batch does not advance without the answer:

> Never proceed on an unanswered question.

**Boundary — the ADR checkpoint in the same step is *not* a tenth gate:**

> it is not a new mandatory gate, and
> a decision that fails the check is not blocked or flagged, it simply
> produces no ADR.

**Not expected:** an unanswered User Challenge recorded as "deferred — user's
direction kept as default" so Step 5 can close. The user's direction *is* the
default option, but a default is what an answer selects, not a substitute for
one. Also not expected: treating the per-decision ADR check as a stop — a
mandatory stop not on the gate table is countermanded by it, not merely
undocumented.

## J — B5: G5 fires once, batched, before Task 1 — and a clean scan is silent

**Scenario:** `keel-execute` ORCHESTRATED. The pre-flight scan finds Task 2
violating the plan's own Global Constraint on request timeouts, and Task 6
contradicting Task 3 about the retry owner.

**Expected:** one question containing both, each quoting the plan:

> One scan of the whole plan before any dispatch, checking for:
> tasks that contradict each other, tasks that violate the plan's own Global
> Constraints, and anything the plan mandates that the review rubric
> (smells.md, repo standards) would flag as a defect. Findings → ONE batched
> question to the user, each item quoting the plan's text and asking which
> wins. Clean scan → proceed silently. Cheap once; discovering a plan
> contradiction at Task 7 is not.

**Boundary — the scan finds nothing:** *proceed silently.* This is the one
gate in this fixture whose empty case must **not** be announced. Contrast
fixture `26` scenario D, where the empty rulebook case must be spoken: the
difference is that G5's absence of findings changes nothing downstream, while
a skipped rulebook injection is invisible in the artifact it should have
shaped.

**Not expected:** two questions, one per finding — G5 is explicitly the
batched gate, and the per-finding form belongs to G4 and G6. Also not
expected: stopping at Task 2 to ask about Task 2's contradiction; the scan is
before Task 1 or it is not the pre-flight. Also not expected: "pre-flight
clean ✓" as a checkpoint line that then waits for acknowledgement.

## K — B5: G5 in INLINE mode, where there is no second chance

**Scenario:** INLINE mode (subagents unavailable) on a plan with the same two
contradictions.

**Expected:** the identical scan, re-lifted into the INLINE step list rather
than left implied by the ORCHESTRATED heading:

> **Run the same pre-flight as ORCHESTRATED mode**, in full, before task 1:
> the plan-contradiction scan (G5), the **Spec drift check**, the
> **Destructive-operation scan** (G9), and the **dependency graph** read of
> step 0.

> Those gates live under ORCHESTRATED above only because that is where they
> were written, not because they are a property of dispatching subagents.

> **INLINE removes the second chance, not the requirement**

**Not expected:** reading the pre-flight as an ORCHESTRATED-only step because
of where it sits in the file — the structural defect this line exists to
prevent, and the same shape fixture `26` scenario B pins for the rulebook
injection. Also not expected: substituting the per-task self-review for the
pre-flight scan; the scan is whole-plan and the self-review is not.

## L — the closed list has no AFK exemption, and one non-gate explicitly does

**Scenario:** two stops in one session with the user away from keyboard.
(1) `keel-plan-review` Step 5 has an open Taste question. (2) `keel-debug`
Phase 3 has a ranked hypothesis list to show.

**Expected (1):** the pipeline waits. G4 has no AFK branch anywhere in its
text, and `Never proceed on an unanswered question.` is unqualified.

**Expected (2):** debug does **not** wait. The one place the pipeline states
an AFK carve-out states it at something that is not on the gate table:

> Show the ranked list to the user before testing — they often re-rank
> instantly ("we just deployed #3") — but don't block on it; proceed with
> your ranking if they're AFK.

**Not expected:** generalising the debug carve-out into a rule that gates may
proceed on silence when nobody is answering. The two are opposites and are
adjacent on purpose: an unanswered G2–G5 stalls the pipeline, which is the
designed cost; an unanswered hypothesis ranking does not, because nothing
downstream depends on it. A gate that can be waited out is not a gate.

## Not expected (any scenario)

- A mandatory user stop that is not a row in the gate table — the table
  forbids it rather than merely omitting it, so inventing one is a defect of
  the same size as skipping G2–G5
- A `BLOCKED:` line without a named destination stage, or with a destination
  chosen by convention rather than by which stage owes the missing field
- G2 skipped for any reason other than the plan routing into
  keel-plan-review, or run in addition to that routing
- Step 0's premise question folded into a Step 5 batch, or answered from the
  agent's recollection after compaction rather than from the report
- A Step 5 batch containing a question whose prerequisite is still open in
  the same batch, or split one-per-call to be safe
- G5 raised per finding instead of batched, raised after Task 1 has started,
  or announced when the scan was clean
- Any of G2–G5 proceeding on silence because the user is AFK
