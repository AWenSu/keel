---
name: keel-audit
description: Use only when the user explicitly asks to security-audit a whole codebase they name (e.g. "/keel-audit ~/code/foo") — a source-only, coverage-accounted vulnerability audit with an independent verifier per candidate. Never part of the discover→plan→plan-review→execute→finish flow and never started by it; diff-level and design-level security stay with keel-exec-reviewer-security and keel-plan-lens-security. Side lane of the keel pipeline.
provenance:
  synthesized: 2026-09-19
  sources:
    - cloudflare/security-audit-skill @c1c8a8c1471069fb0e188eeaff69b8e8db6564a8 (MIT, Copyright Cloudflare, Inc.) — the whole method, vendored verbatim in upstream/ with its LICENSE and UPSTREAM_SHA.txt; this file is only keel's adaptation layer over it
  dropped: the README's `npx skills add` install path and every other external install or fetch (the validators need only the local `node`, no packages); target-code execution on hosts that cannot enforce every control in upstream's "Universal execution safety" — verified 2026-09-19 on macOS 26 that the loopback is shared with live host services and `ulimit -v` is refused, so this lane is source-only there, which upstream's own rule already requires; upstream's general-execution role (it exists to run bounded local execution, which source-only never does); the scratch→artifacts promotion procedure (it promotes files produced by executed target code, of which there are none)
---

# keel-audit — Whole-Codebase Security Audit (side lane)

```
INPUT   an explicit request naming the repository to audit, plus read access to it
OUTPUT  a run directory outside the target holding findings.json and
        coverage-ledger.json that both upstream validators accept, and
        REPORT.md / FINDINGS-DETAIL.md / NEEDS-VALIDATION.md derived from them
```

Missing INPUT → `BLOCKED: 缺 <target repository named by the user> → 退回 the requester`.
There is no earlier stage to route to, and this lane never picks a target on its own.

**What this is for, and what it is not.** `keel-exec-reviewer-security` reviews
one task's diff; `keel-plan-lens-security` threat-models a plan. Neither looks
at code nobody is changing. This lane does, once, on request. It is also not a
replacement for gstack's `/cso` where that is installed: `/cso` covers
infrastructure, secrets history, CI and skill supply chain with a confidence
gate; this lane contributes what `/cso` lacks — a **coverage ledger** that says
exactly what was and was not examined, a `needs_validation` state that carries
no severity, and machine-validated findings.

**Cost.** Each unit in the ledger is roughly one agent; each surviving
candidate is one or two more. Even `quick` on a small repository is
double-digit agent invocations. That is why nothing in the pipeline starts it.

## The method lives upstream — read it on demand

Resolve **`<U>`** = the absolute path of `upstream/` next to this file
(`~/.claude/skills/keel-audit/upstream` for a global install,
`<repo>/.claude/skills/keel-audit/upstream` for a per-project one). Every file
below is read from `<U>`, and every path you put in a brief is `<U>`-absolute —
a relative name resolves for you and for nobody in a subagent's cwd.

| When | Read |
|------|------|
| before anything else | `<U>/SKILL.md` — "Universal execution safety", "Full audit setup", "Full audit planning", "Core principles", "Full audit workflow", "Anti-patterns" |
| Phase 1 | `<U>/RECONNAISSANCE.md` |
| Phase 2 | `<U>/HUNTING.md`, `<U>/ATTACK-CLASSES.md`, and only the domain companions reconnaissance selected |
| Phases 3–6 | `<U>/VALIDATION-AND-REPORTING.md`, `<U>/report-schema.json` |

Follow upstream's **full audit mode** as written. The request that invoked
this lane is the explicit audit request upstream requires, so do not ask
upstream's disambiguation question. The overrides below are the only places
keel departs from it.

## keel's overrides

**1. Roles.** Upstream's research role is **`keel-audit-hunter`** — for
reconnaissance, hunting, and coverage-critic passes alike, each brief saying
which. Upstream's candidate and record verifiers are **`keel-audit-verifier`**,
a fresh one per candidate as upstream requires. Upstream's general-execution role is
not used: it exists for bounded local execution, and this lane does not
execute target code. Never substitute `general-purpose`.

**2. Source-only unless every control is enforceable.** Before dispatching,
check the host against each control upstream lists under "Universal execution
safety". On macOS, as verified 2026-09-19, two fail: the loopback is shared
with live host services — a sandboxed `curl` allowed `localhost` reached a
local service on `127.0.0.1` — so upstream's *isolated* loopback namespace is
unavailable, and `ulimit -v` is refused, so there is no memory limit. Upstream
then forbids executing target code, and this lane follows it: every question
that only execution could settle becomes `needs_validation` naming the missing
control. Both agents hold `Read, Grep, Glob` and no shell, so this is enforced
by their tool lists, not by their good behaviour.

**3. The parent is the only writer, and the only one running anything.** Only
the controller writes the run files upstream lists under "Write isolation",
and the only programs it runs are the two validators, which read those files
and nothing in the target:

```
node <U>/validate-findings.cjs <output-dir>/findings.json
node <U>/validate-coverage-ledger.cjs <output-dir>/coverage-ledger.json
```

Local `node` only; no `npx`, no package installs.

**4. Profile, scope, budget — stated, not asked.** Take them from the
invocation; absent ones default to `quick`, the whole repository, and a budget
of 16 agent invocations. Announce all three and the output directory (upstream's
default, outside the target) in your first line, then proceed. If the budget
cannot fund upstream's minimum, do what upstream says when the request stays
unchanged: launch nothing, record `run_status: "incomplete"` with its reason,
and say so. This lane adds no stop to keel's gate table.

**5. Report honestly about coverage.** A `quick` or scoped run is partial and
says so in its first paragraph; source-only means every execution-dependent
unit is `needs_validation` or `deferred`, never `covered`. A clean report on
an unexecuted target is a statement about the source that was read, not about
the running system.

## Fan-out and budget

Fan-out ceiling: ≤8 concurrent per wave; the run's agent budget is the total.

Do not pass a `model` override at the call site — each agent file pins its own.
Name the agent, not the role: announce each dispatch before it runs and broadcast each result when it lands, both using the agent's literal `keel-*` name.

## Red flags

- Starting this lane because a diff touched auth, or because a plan was risky → those are the other two security stages; this one runs only on request
- Picking the target yourself → the user names it
- Executing anything from the target "just to check" → source-only; record `needs_validation`
- Relative paths in a brief → `<U>`-absolute, always
- Reporting a partial run as a clean bill → say what was not covered, first
