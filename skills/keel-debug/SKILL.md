---
name: keel-debug
description: Use when something is broken, throwing, failing, flaky, or slow and the cause is not already known — a disciplined diagnosis loop that forbids guessing before a reproduction exists. Debug lane of the keel pipeline; replaces the superpowers:systematic-debugging routing.
provenance:
  synthesized: 2026-07-22
  sources:
    - mattpocock/skills diagnosing-bugs @1.2.0 (loop-first iron law, 10 loop constructions, tighten/repro-rate rules, tagged instrumentation, post-fix architecture question)
    - superpowers:systematic-debugging @6.1.1 (root-cause-before-fix spirit, no symptom-patching)
  dropped: Matt's hitl-loop.template.sh (script dependency; inlined the idea), his improve-codebase-architecture hand-off (we route findings to keel-discover instead)
---

# keel-debug — Diagnosis Loop

```
INPUT   an observable symptom (error, wrong output, flake, slowness) and an
        environment the code can be run in
OUTPUT  a one-line root-cause statement, a regression test that went red
        before the fix and green after, and zero leftover instrumentation
```

Missing INPUT → `BLOCKED: 缺 <symptom | runnable environment> → 退回 <the
stage or person that owes it>`. A symptom nobody can reproduce and no
environment to try it in are the two things this stage cannot substitute for.

**Build/compile failures short-circuit the loop.** If the symptom is a
compile, type, or build error rather than a runtime behavior, Phase 1 is
already done — the build command *is* the loop. Dispatch
`build-error-resolver` (by name, never `general-purpose`, no `model`
override) and skip to Phase 6's checklist. The phases below are
for behavior you have to hunt.

Skip phases only when explicitly justified. Read `CONTEXT.md` (if it exists)
before exploring, so you name modules the way the project does, and
`docs/adr/` for the affected area — what looks like a bug is sometimes a
recorded deliberate trade-off; don't "fix" an ADR.

<IRON-LAW>
NO HYPOTHESIS WITHOUT A RED LOOP.
Until you can name ONE command — already run at least once, output in hand —
that reproduces the user's exact symptom, you may not theorize about causes
or read code "to build a theory". Fix nothing you cannot watch fail.
</IRON-LAW>

## Phase 1 — Build the feedback loop

This is the skill; everything after it is mechanical. Spend disproportionate
effort here. Ways to construct one, in rough order:

1. **Failing test** at whatever seam reaches the bug (prefer the spec's
   confirmed seams if this code went through the pipeline)
2. **Curl / HTTP script** against a running dev server
3. **CLI invocation** with a fixture input, diffed against known-good output
4. **Headless browser script** (Playwright) asserting on DOM/console/network
5. **Replay a captured trace** — save a real payload/event log, replay it
   through the code path in isolation
6. **Throwaway harness** — minimal subset of the system, mocked deps, one
   function call into the bug path
7. **Property/fuzz loop** — 1000 random inputs when the symptom is
   "sometimes wrong output"
8. **Bisection harness** — bug appeared between two known states → automate
   "boot at state X, check" so `git bisect run` works
9. **Differential loop** — same input through old vs new version, diff
10. **Human-in-the-loop script** — last resort; if a human must click, drive
    them with a script that captures their observation back to you

**Tighten it:** faster (cache setup, narrow scope), sharper (assert the
specific symptom, not "didn't crash"), deterministic (pin time, seed RNG,
freeze network). A 2-second deterministic loop is a superpower; a 30-second
flaky one is barely a loop.

**Non-deterministic bugs:** the goal is a higher reproduction rate, not a
clean repro. Loop the trigger 100×, add stress, inject sleeps. 50% flake is
debuggable; 1% is not.

**Genuinely cannot build one:** stop and say so. List what you tried; ask
the user for a reproducing environment, a captured artifact (HAR, log dump,
recording), or permission to add temporary instrumentation. Do NOT proceed
to Phase 3 without a loop.

**Exit criterion:** one command, agent-runnable, fast, deterministic (or
pinned high repro rate), that goes red on this bug and will go green when
fixed. Paste the invocation and its output.

## Phase 2 — Reproduce + minimise

Run the loop; watch it go red. Confirm it fails with the **user's exact
symptom** — a nearby different failure means wrong bug, wrong fix.

**A third outcome exists: the loop is red, the symptom matches, and the code
is doing exactly what the spec or an ADR says it should.** Then this is not a
bug — the requirement is wrong. Stop the diagnostic loop and route back to
`keel-discover` with the repro and the `file:line` of the spec/ADR text that
sanctions the behavior (`keel-workflow`'s `keel-debug → keel-discover` route).

Do not "fix" it here. A code change that contradicts an approved spec is a
silent spec amendment — it skips the approval gate stage 1 exists to enforce,
and leaves the written requirement stating the opposite of what ships. Phase
3 asks "why does the code do this"; this outcome answers it in one line and
makes the remaining phases the wrong tool.

Otherwise, shrink to the smallest scenario that still goes red: cut inputs, config,
callers one at a time, re-running after each cut. Done when every remaining
element is load-bearing. The minimal repro shrinks Phase 3's hypothesis
space and becomes Phase 5's regression test.

## Phase 3 — Hypothesise

Generate **3–5 ranked hypotheses** before testing any — single-hypothesis
generation anchors on the first plausible idea. Each must be falsifiable:
"If X is the cause, then changing Y makes the bug disappear." Can't state
the prediction → it's a vibe, discard it.

Show the ranked list to the user before testing — they often re-rank
instantly ("we just deployed #3") — but don't block on it; proceed with
your ranking if they're AFK.

## Phase 4 — Instrument

Each probe maps to one prediction; change one variable at a time.
Debugger/REPL beats targeted logs beats never-"log everything and grep".
**Tag every debug log** with a unique prefix (`[DEBUG-a4f2]`) so cleanup is
one grep. Performance bugs: logs are usually wrong — baseline measurement
first (profiler, timing harness, query plan), then bisect; measure before
fixing.

## Phase 5 — Fix + regression test

Write the regression test **before the fix**, at a correct seam — one that
exercises the real bug pattern as it occurs at the call site. A too-shallow
seam gives false confidence; **if no correct seam exists, that itself is a
finding** — record it and flag the architecture gap to the user (a
keel-discover candidate). With a seam:

1. Minimised repro → failing test. Watch it fail.
2. Apply the fix. Watch it pass.
3. Re-run the Phase 1 loop against the original un-minimised scenario.

Fix the root cause, not the symptom — a fix you can't explain in one
sentence ("X assumed Y, but Z") is a patch, not a fix.

**Three-strikes circuit breaker (from superpowers):** count failed fixes.
Under 3 → return to Phase 3 and re-analyze. At 3 → STOP; a 4th attempt is
forbidden. Tell-tales that this is architecture, not a failed hypothesis:
each fix reveals new coupling somewhere else, the fix keeps growing into a
refactor, the fix creates new symptoms. Take it to the user as an
architecture conversation — more thrashing only buries the real problem.

## Phase 6 — Cleanup + post-mortem

Before declaring done:

- [ ] Original repro no longer reproduces (Phase 1 loop re-run, fresh)
- [ ] Regression test passes — or the missing-seam finding is documented
- [ ] `grep` shows zero `[DEBUG-` instrumentation left
- [ ] Throwaway harnesses deleted
- [ ] The winning hypothesis stated in the commit message

Then ask: **what would have prevented this bug?** If the answer is
architectural (no test seam, tangled callers, hidden coupling), recommend it
to the user now — after the fix, when you know the most. Verification of the
overall change still goes through **keel-finish** if the fix is part of
pipeline work.

## Red flags

- Reading code to build a theory before the loop exists → the exact failure this skill prevents
- "It's probably X, let me just try" → that's a hypothesis without a loop
- Repro passes but with a different error than the user reported → wrong bug
- Fix committed with the debug logs still in → grep the tag
- Regression test that never went red → proves nothing
