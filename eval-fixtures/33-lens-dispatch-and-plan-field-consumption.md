# Fixture 33: Lens dispatch conditions and plan-field consumption (D5, D6, P3, P9)

**Rule source:** `skills/keel-plan-review/SKILL.md` Step 1: Detect scope → select lenses.
**Rule source:** `skills/keel-plan-review/SKILL.md` Step 2: Run lenses — sequential, fresh-context.
**Rule source:** `skills/keel-plan/SKILL.md` § Write the plan header.
**Rule source:** `skills/keel-plan/SKILL.md` § Write tasks (the `Interfaces:` template).
**Rule source:** `skills/keel-execute/SKILL.md` INPUT contract, Pre-flight plan review, and per-task loop step 1 (brief extraction).
**Rule source:** `agents/keel-exec-reviewer-spec.md` (Interface drift + evidence-strength tier + Plan-mandated findings).

D5/D6 are the sibling rules to fixture `14`'s security-lens trigger: same
declaration site (Step 1) and same enforcement site (Step 2's roster), but a
plain 2+-keyword-hit condition instead of an OR of three. Fixture 14 already
proves the mechanics of "exactly 1 hit doesn't trigger" and "the roster must
say which condition was checked and found absent" for the OR-lens; this
fixture checks the same mechanics transfer to a single-condition lens, and
spends its second scenario per lens on a wording gap between the two
declaration sites instead of re-proving the boundary count.

P3/P9 are two of the eleven fields fixture `22` already partially covers
(`Depends on:`, `[Risk:]`). Fixture 22 scenario C already proves that
`keel-execute`'s brief extraction pulls in exactly the dependency tasks'
`Interfaces:` blocks — that consumption path is not re-tested here. What
fixture 22 does not touch is what happens when `Interfaces:`'s promised
shape drifts from what actually got built (P3's verifier,
`keel-exec-reviewer-spec`'s interface-drift check) or what happens when
`Global Constraints:` is violated, or silently missing, at the one place
that both consumes and verifies it (P9).

## D5 — Design lens dispatches on 2+ UI keyword hits

### A — exactly 1 hit, boundary

**Scenario:** Plan text: "Add a settings **screen** for notification
preferences." (1 hit: screen. No view/rendering/UI/component elsewhere.)

**Expected:** Design lens does not dispatch. Step 1 states the condition as

> Conditionally add (2+ keyword hits in the plan): - **Design lens** — view/rendering/UI/component/screen vocabulary

— 1 hit is short of 2+. Per Step 2's generic roster rule:

> **Announce the roster before dispatching**, naming which conditional lenses were skipped and why.

the roster line for this plan must name Design as skipped and state that
only 1 UI-vocabulary hit was found.

**Not expected:** dispatching on the single hit; skipping Design silently
without naming the condition checked.

### B — "rendering"-only hits: Step 1 and Step 2 disagree on the word list

**Scenario:** Plan text: "Move chart **rendering** off the main thread; the
background **rendering** worker posts frames back." (2 hits, both
"rendering." No occurrence of view/UI/component/screen.)

**Expected, reading Step 1 alone:** Design lens dispatches — "rendering" is
literally one of the five listed words and this plan hits it twice, which
satisfies "2+ keyword hits in the plan" as written, without regard to
whether the two hits are about the same word.

**And Step 2's dispatch table now restates the same word list, all five
words:**

> | Design | `keel-plan-lens-design` | 2+ view/rendering/UI/component/screen keywords |

so the answer is unambiguous: dispatch. Until 2026-09-11 the Step 2 copy was
one word short — it omitted "rendering" — and an agent reading only the
dispatch table (exactly what a fresh-context resume does) would have counted
zero hits and skipped Design, the opposite of Step 1's own reading. The audit
that produced this fixture found the drift; this scenario is its regression
check.

**Not expected:** the two lists diverging again. A condition restated in two
places is a maintenance hazard by construction — the sibling D6 row has
matched verbatim in both copies since it was written, which is what this one
must now be held to.

**Not expected:** treating this as a clean pass in either direction without
noting the disagreement; silently picking whichever answer confirms a
change was correct.

## D6 — DX lens dispatches on 2+ API/CLI/SDK keyword hits

### A — exactly 1 hit, boundary (mirrors D5-A)

**Scenario:** Plan text: "Publish a new **SDK** method for batch export."
(1 hit: SDK. No API/CLI/docs/MCP elsewhere.)

**Expected:** DX lens does not dispatch —

> **DX lens** — API/CLI/SDK/docs/MCP vocabulary (product is developer-facing)

— and Step 2's table repeats the identical word list for DX (no drift here,
unlike D5-B):

> | DX | `keel-plan-lens-dx` | 2+ API/CLI/SDK/docs/MCP keywords |

so this boundary has one consistent answer: skip, with the roster stating
1 hit against a 2+ threshold.

**Not expected:** dispatching on the single hit.

### B — keywords present, product not developer-facing (literal count still fires)

**Scenario:** Plan text: "The nightly job calls the payment provider's
**API** twice — once to charge, once to confirm — and logs both calls to
our internal metrics **API**." (2 hits, both "API." The plan is an internal
batch job; nothing in it ships an API, CLI, or SDK for outside developers.)

**Expected:** DX lens dispatches. Step 1's condition is stated as a keyword
count with a parenthetical gloss, not a second AND-clause:

> **DX lens** — API/CLI/SDK/docs/MCP vocabulary (product is developer-facing)

Read literally — "no interpretation beyond what the text says," per this
directory's own grading instruction — "(product is developer-facing)" reads
as the *reason* 2+ hits of this vocabulary are treated as a signal, not as
an independently-checked precondition the roster must also verify. Nothing
in Step 1 or Step 2 instructs counting only hits that occur in a
developer-facing context. So this plan, which merely calls two external/
internal APIs from a batch job, still crosses the 2-hit bar and DX
dispatches — likely to return a low-value review (there is no persona, no
install path, no CLI for it to evaluate), but that is the DX lens's problem
to report ("no developer-facing surface found" as its own finding), not a
Step 1/2 reason to suppress dispatch.

**Not expected:** the roster skipping DX on the theory that "the product
isn't developer-facing" — that judgment is nowhere in the dispatch
condition's text, only in its parenthetical explanation.

## P3 — `Interfaces:` produced, consumed, and verified

### A — signature drift between the plan's promise and the diff

**Scenario:** Task 4's plan text reads `Interfaces: - Produces:
parseInvoice(xml: string): Invoice`. Task 6 depends on Task 4 and consumes
that signature. The implementer's
diff for Task 4 ships:

```ts
function parseInvoice(xml: string, opts?: ParseOptions): Invoice | null
```

(an added optional parameter, and a return type that is now nullable).

**Expected:** `keel-exec-reviewer-spec` raises a **Critical/Important**
Interface drift finding under its finding class 4:

> **Interface drift** — the task's `Interfaces:` block promised a signature or shape that downstream tasks consume; the diff produced a different one.

quoting `docs/plans/...md` for the promised shape and the diff's actual
declaration line as evidence, since Task 6's brief (per `keel-execute`'s
brief-extraction rule proven in fixture 22-C) was built against the
*promised* signature, not this one — a caller written against
`Invoice` will not null-check, and a caller passing no `opts` still matches
the old call sites but silently changes nothing, masking that the contract
moved.

**Not expected:** treating the added optional parameter as harmless because
existing call sites still compile; skipping the finding because Task 6
hasn't been dispatched yet ("nothing broke yet" is not the test — the
promised shape is the source of truth for briefs not yet built).

### B — evidence-strength disclosure when no contract-testing tool exists

**Scenario:** Same drift as A, but the repo has no `*.openapi.yaml` /
`*.openapi.json` / `*.asyncapi.yaml` file, and neither `spectral` nor `pact`
is installed.

**Expected:** the reviewer still raises finding 4, but its evidence line
must disclose the fallback rather than silently downgrading or upgrading
severity:

> Otherwise, fall back to plain- text comparison of the `Interfaces:` block's described signature against the implementation's actual signature.

and

> Tool absence never upgrades a finding to FAIL and never gets ignored: state "contract test: not executed — no spectral/pact available, falling back to plain-text comparison" explicitly, and cap confidence accordingly

so the report reads something like `證據: contract test: not executed — no
spectral/pact available, falling back to plain-text comparison; plan
promises Invoice, diff returns Invoice | null (file:line)`, confidence
capped, per finding class 5 — which is explicitly the same finding, not a
second one:

> Never report this as a second, separate finding alongside 4 — fold it into the same finding's evidence line so the same drift isn't reported twice.

**Not expected:** two separate findings (one "interface drift," one
"contract test not run"); silently omitting the disclosure because the
plain-text comparison still caught the drift; treating tool absence as a
reason to drop the finding.

## P9 — `Global Constraints:` produced, consumed, and enforced at pre-flight

### A — a task directly violates a stated Global Constraint

**Scenario:** Plan header reads:

> **Global Constraints:** <exact values copied verbatim from the spec — limits, formats, naming, versions. Never paraphrase.>

concretely instantiated as "Global Constraints: all timestamps stored as
UTC ISO-8601; no local-timezone conversion server-side." Task 5's steps
call for storing `created_at` using the server's local timezone, "to match
the legacy export format."

**Expected:** `keel-execute`'s pre-flight scan catches this before Task 1
dispatches, per:

> One scan of the whole plan before any dispatch, checking for: tasks that contradict each other, tasks that violate the plan's own Global Constraints, and anything the plan mandates that the review rubric (smells.md, repo standards) would flag as a defect.

and surfaces it as:

> Findings → ONE batched question to the user, each item quoting the plan's text and asking which wins. Clean scan → proceed silently.

so the controller asks the user, quoting both the Global Constraints line
and Task 5's local-timezone step, before Task 1 ever runs — not a BLOCKED,
not a silent auto-resolution favoring either side. This pre-flight scan
runs identically in INLINE mode:

> the plan-contradiction scan (G5), the **Spec drift check**, the **Destructive-operation scan** (G9), and the **dependency graph** read of step 0.

(the same paragraph names this "the same pre-flight as ORCHESTRATED mode,
in full" — P9's enforcement is not an ORCHESTRATED-only guarantee.)

**Not expected:** the implementer for Task 5 discovering the contradiction
mid-task and picking a side unasked; the pre-flight scan finding nothing
because it only compares tasks against each other and not against the
header.

### B — the field can go missing with nothing naming its absence

**Scenario:** A Medium-task plan produced via `keel-plan`'s lightweight
`planner`-agent shortcut skips the full header — it carries `Delivers:`,
`Files:`, `Interfaces:`, `Skills:`, and `Depends on:` per task (the four
fields `keel-plan`'s shortcut paragraph names as owed) but never states
`Global Constraints:` anywhere, and goes straight to `keel-execute` without
`keel-plan-review`.

**Expected:** blocked at the INPUT contract, which since 2026-09-11 names
the field:

> a plan file with a header carrying Spec Version + Global Constraints + Success Criteria, and every task carrying Delivers / Files / Depends on / Interfaces / Skills

and which now also says what a *blank* field means, because that is the
variant the generic missing-field check cannot see:

> An **empty** `Global Constraints:` is the one that hides best: the pre-flight scan checks tasks against it, so a blank field makes that scan pass on nothing, and a clean scan reads identically whether the constraints were satisfied or absent. Blank is a miss, not a permissive default.

Before that fix the contract omitted the field entirely, and the reasoning
below is the record of why it was added — a Medium-shortcut plan reached
execution with no check anywhere that would produce a BLOCKED for it:

— compare `keel-plan-review`'s INPUT contract, which *does* list it
(`plan file with header (Goal, Spec Version, Global Constraints, Success
Criteria)`, fixture-external but present in that file's own INPUT block).
A plan that skips `keel-plan-review` (the common path for anything not
"large/risky," per `keel-plan`'s own Exit section) reaches `keel-execute`
with no check anywhere that would produce
`BLOCKED: 缺 <field> → 退回 keel-plan` for a missing `Global Constraints:`
the way it would for a missing `Interfaces:` or `Depends on:`:

> Missing INPUT → `BLOCKED: 缺 <field> → 退回 keel-plan`. A plan without those fields silently disables brief extraction, the staleness check, and the spec-compliance axis

names three mechanisms and never lists Global-Constraints enforcement among
them. With the field simply absent, pre-flight's own violation scan has
nothing to compare tasks against and reports a clean scan — not because no
task violates a constraint, but because no constraint was ever stated. This
is functionally silent: nothing in `keel-execute`'s own text distinguishes
"clean scan, constraints checked" from "clean scan, no constraints to
check," and the brief-extraction step (`plus the plan header (Goal, Global
Constraints, and Visual source of truth: when the plan has one)`) simply
carries forward an empty field into every task brief without comment.

**Not expected:** treating this scenario as correctly handled — it isn't.
A grader walking `keel-execute`'s text alone, with this plan as input,
produces no BLOCKED and no disclosure, which is exactly the "declared a
verifier, but the verifier has nothing to fire on and nothing says so"
shape this repo's own P-section intro names as its most recurring defect.
The gap is narrower than a full producer/consumer/verifier miss — a plan
that *does* go through `keel-plan-review` is still caught there — but for
the direct `keel-plan` → `keel-execute` path, which `keel-plan`'s own Exit
section treats as the default ("Plan is straightforward → keel-execute
directly"), nothing catches a silently blank `Global Constraints:`.

## Not expected (any scenario)

- Dispatching Design or DX on exactly 1 keyword hit (D5-A, D6-A)
- Skipping a conditional lens without the roster naming which condition was
  checked and found absent
- Treating the DX dispatch condition's "(product is developer-facing)" as an
  additional AND-gate the roster must separately verify (D6-B)
- Reporting Interface drift and its evidence-strength tool-absence disclosure
  as two separate findings, or silently omitting the disclosure (P3-B)
- A `[Risk:]`-style silent pass on `Global Constraints:` — a pre-flight
  "clean scan" that cannot distinguish "no violation found" from "nothing to
  check against" (P9-B)
- Blocking or auto-resolving a Global Constraints violation instead of one
  batched question quoting both sides (P9-A)
