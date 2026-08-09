# Project-Type Guide — how to use the pipeline per project type

The five stages are the same everywhere; what changes per project type is
**which stages you actually run, which review lenses fire, and which domain
skills you layer on top**. Defaults below; deviate when the task tells you to.

Reminder that overrides everything: planning cost ≤ ~20% of the task.
A one-file fix in ANY project type skips straight to work + the keel-finish
gate. One exception: if that one file sits on an auth/session, encryption,
upload, outbound-call, or query-construction path, or adds an
externally-reachable endpoint, it also runs keel-finish Part 2c. Small and
safe are different measurements.

## Quick matrix

| Project type | Discover | Plan | Review | Execute | Finish focus | Layer on top |
|---|---|---|---|---|---|---|
| Full-stack web app | Full | Full artifact | CEO+Eng+Design | Orchestrated | Drive the real flow in browser | UI router for frontend tasks |
| Frontend / landing page | Light (visual refs replace prose spec) | Optional | Design lens dominant | Inline usually | Screenshot verification | Design-taste skills via UI router |
| Backend API / DB service | Full, evidence-heavy | Full artifact | CEO+Eng+DX | Orchestrated | Contract tests + one real request | API design, migration, observability skills |
| CLI / automation script | Five-question intake only | Sizing guide says skip mostly | Skip unless >8 files | Inline | Run the CLI end-to-end | — |
| MCP server / agent tooling | Full | Full artifact | Eng+DX (DX is the product!) | Orchestrated or inline | Connect a real client, call every tool | MCP builder skill |
| Serverless / edge (Workers) | Full | Full artifact | Eng+DX | Inline (small surface) | Deploy to preview, hit the endpoint; Release Runbook if non-preview deploy | Platform skill (e.g. Cloudflare) |
| Docs / config / knowledge repo | Skip | Skip | Skip | Direct edits | Render/lint check | Doc-coauthoring skill for long docs |
| Scraping / integration | Light — targets ARE the spec | Findings-file driven | Skip | Inline, iterative | Run against the live target once | Browser-automation skills |

## Per-type notes

### Full-stack web app
The default pipeline as designed. Split UI tasks out to your UI router
(design-taste skills) — the pipeline handles logic/data; the UI lane handles
look and feel. keel-plan-review runs CEO + Eng always, Design activates on
the UI vocabulary trigger automatically.

### Frontend / landing page / UI-heavy
Discover shrinks: a visual reference (mockup, generated design image,
competitor screenshot) carries more spec weight than prose — get the visual
approved, that IS the gate. Plans are usually small (component-level);
inline execution. Finish = screenshot the real rendered page, compare
against the approved visual. Never claim "looks right" from code reading.

### Backend API / database service
Evidence rule matters most here: current behavior claims need `path:line`,
schema claims need the actual schema. When the plan involves a public or
inter-service API, keel-plan should produce an OpenAPI/AsyncAPI spec as a
standalone Task 0 first, and later `Interfaces:` blocks should reference
that spec's path instead of re-writing signatures. Plan must risk-grade
every migration task High with a named rollback. keel-plan-review's DX lens
activates (API consumers are developers). Finish: contract/integration tests plus ONE
real request against a running instance — unit tests lie about wiring.
High-risk overlay (doubt-driven) on anything touching production data.

### CLI tool / automation script
The pipeline's smallest configuration. Five-question intake (5 minutes) →
straight to work with a todo list. The Iron Law still fully applies: run the
actual CLI with the actual flags before claiming done. Scripts have a
runtime surface too.

### MCP server / agent tooling
DX lens is not optional — the developer experience IS the product. Spec must
name every tool, its schema, and its error behavior (problem + cause + fix
in every error message). Finish: connect a real client (not just the test
harness) and invoke every tool once.

### Serverless / edge (e.g. Cloudflare Workers)
Layer the platform skill for platform idioms; the pipeline governs process.
Surfaces are small — inline execution usually beats orchestration. Finish
requires a preview deploy + a real HTTP hit; local emulation passes are
evidence for logic, not for platform behavior (bindings, limits, cold
starts). For projects with a real deploy step (not preview-only), keel-finish
Part 3 should additionally produce a Release Runbook — pre-deploy checks,
deploy command, post-deploy verification commands, and rollback command —
written into the PR body or a standalone doc; preview-only deploys don't
need this.

### Docs / config / knowledge repo
The pipeline mostly stands down — no runtime surface, reversible edits.
What survives: the keel-finish claim discipline (does the doc render? do the
links resolve? does the config parse?) and scope lock for large
reorganizations (moving 50 files is a plan, not an edit).

### Scraping / integration workflows
Discovery is empirical: the target site/API is the spec, and it changes
under you. Work findings-file driven — every selector, endpoint, and rate
limit discovered goes to `findings.md` immediately (they're expensive to
rediscover). Plans stay short-horizon; review is usually wasted (the target
will invalidate it). Finish: one run against the live target, output
inspected.

## Cross-cutting, all types

- **Name the target environment before driving anything.** Several rows above
  demand evidence from a running system — "ONE real request against a running
  instance," "a preview deploy + a real HTTP hit," "one run against the live
  target." None of them authorize choosing production to satisfy that demand.
  Before executing, state which environment you are pointing at; if it cannot
  be shown to be local, preview, or ephemeral, stop and get explicit consent
  naming the environment and the exact command. `not executed — no
  non-production environment available` is a legitimate evidence line.
- **Release Runbook** (pre-deploy checks, deploy command, post-deploy
  verification, rollback): required for **any** project type with a real
  deploy step, not preview-only — the criterion is the deploy, not the
  platform. The Serverless/edge section above names it explicitly because preview deploys
  make the distinction easy to miss there, but a full-stack app or backend
  service that ships to a real environment needs one just the same.
- **High-risk overlay** (production / security / irreversible / data
  migration): layer adversarial review on any stage, any project type.
- **Unknown codebase**: prepend a cheap exploration pass (read-only agent or
  code-graph tooling) before Discover — never plan against an imagined
  codebase.
- **Debugging is its own lane**: bug work enters via systematic debugging,
  not via Discover. The pipeline is for building; debugging has its own
  discipline.
