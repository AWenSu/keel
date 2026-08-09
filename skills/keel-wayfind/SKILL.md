---
name: keel-wayfind
description: Use when a piece of work is too big for one session AND the route to it is still foggy — chart it as a local map of decision tickets, then resolve them one per session until the way is clear. Pre-stage of the unified dev pipeline; hands off to keel-discover or keel-plan once the fog is gone.
provenance:
  synthesized: 2026-07-22
  sources:
    - mattpocock/skills wayfinder @1.2.0 (map/ticket structure, fog of war, ticket types, one-ticket-per-session, plan-don't-do)
  dropped: issue-tracker backend (GitHub/Linear) — replaced with local files per our filesystem-is-memory convention; multi-session claiming via assignee (single-user setup, a ticket file's Status field serves instead)
---

# keel-wayfind — Decision Maps for Oversized Work

```
INPUT   an idea too large for one session whose route is still unclear —
        fog, not just size
OUTPUT  docs/maps/<topic>/MAP.md with zero open tickets and no fogged
        section, exiting to keel-discover or keel-plan
```

Missing INPUT → this is the wrong stage. Work that is merely large but whose
route is visible goes straight to `keel-discover`; the fog is the entry
condition, not the size.

A loose idea has arrived — too big for one session, and wrapped in fog: the
route from here to the **destination** isn't visible yet. Wayfinding charts
that route as a map of **decision tickets** — questions whose resolution is
a decision, not slices of a build — and resolves them one at a time.

**Plan, don't do.** Every ticket resolves a decision. The map is done when
nothing is left to decide — then the effort exits to **keel-discover** (spec
the now-clear work) or **keel-plan** (if the decisions already amount to a
spec). Feeling the pull to just start building is the signal you've reached
the map's edge and it's time to exit, not to code inside the map.

**When NOT to use:** if one keel-discover session could plausibly settle all
open questions, skip the map — this skill's overhead only pays off when the
deciding itself spans sessions.

## File layout

```
docs/maps/<topic>/
├── MAP.md                      ← the map: low-res view, loaded every session
└── tickets/
    ├── 01-<slug>.md
    └── 02-<slug>.md
```

### MAP.md

```markdown
# Map: <topic>

## Destination
<what reaching the end looks like — the spec, decision, or change this
effort is finding its way to. 1-2 lines; every session orients here first.>

## Notes
<domain background; skills every session should consult; standing
preferences for this effort>

## Decisions so far
<!-- index only — one line per resolved ticket; detail stays in the ticket -->
- [01 — <ticket title>](tickets/01-<slug>.md) — <one-line gist of the answer>

## Not yet specified
<!-- fog of war: in-scope questions you can't phrase sharply yet -->

## Out of scope
<!-- consciously ruled out; never graduates unless the destination is redrawn -->
```

### Ticket file

```markdown
# <NN> — <title>

**Type:** research | prototype | grilling | task
**Status:** open | resolved | out-of-scope
**Blocked by:** <NN list, or "none">

## Question
<the decision or investigation this ticket resolves — sized to one session>

## Resolution
<empty until resolved; then the answer, and links to any assets produced>
```

## Ticket types

Each is **HITL** (worked with the user live) or **AFK** (agent alone). A
HITL ticket only resolves through that exchange — never answer the user's
side yourself.

- **research** (AFK) — surface a fact a decision waits on: docs, third-party
  APIs, the codebase. Resolvable by a background subagent; findings land in
  the Resolution section with citations.
- **prototype** (HITL) — raise the fidelity of the discussion with a cheap
  concrete artifact to react to. **A prototype is throwaway code that
  answers a question** (from mattpocock prototype) — discipline:
  - *Logic question* → a pure reducer/state-machine with a throwaway shell
    (CLI/TUI) calling into it; nothing flows the other direction. The pure
    core may graduate to production later; the shell always dies.
  - *UI question* → radically different variants mounted **inside the real
    page** behind a `?variant=` switcher — a standalone demo page is a
    vacuum, reactions there don't transfer.
  - *Capture:* commit the prototype to a throwaway branch; only the
    **decision** reaches the ticket's Resolution (plus decision-rich
    snippets — a state machine, a schema — inlined there). A prototype that
    starts growing features is violating plan-don't-do: stop, extract the
    decision, delete.
- **grilling** (HITL) — the default: one-question-at-a-time interview
  (keel-discover's step-3 discipline, including the domain-language rules)
  until the question is decided.
- **task** (either) — manual work that must happen before a decision can be
  made: provision access, sign up for a service, move data so its shape can
  be seen. The one type that *does* rather than decides — it earns its place
  by unblocking a decision. Resolution records what was done and the facts
  later tickets depend on.

## Fog of war

Chart only what you can see. The test for ticket vs fog: **can you state
the question precisely now?** (Not: can you answer it.)

- Sharp question → ticket, even if blocked.
- Can't phrase it sharply → one loose line in **Not yet specified**. Don't
  pre-slice fog into ticket-sized pieces; one patch may become several
  tickets, or none, once the frontier reaches it.
- Beyond the destination → **Out of scope**, with one line on why. A
  mis-scoped existing ticket gets Status: out-of-scope and a line there —
  it never enters Decisions so far.

## Invocation

Two modes. Either way: **resolve at most ONE ticket per session** —
research tickets excepted (they may run in parallel as background subagents).

### Chart the map (first session)

1. **Name the destination** — grill the user (one question at a time) until
   the destination is 1-2 lines sharp. It fixes the scope, so it's first.
2. **Map the frontier** — grill again, breadth-first across the whole space,
   surfacing open decisions. If this surfaces no fog, you don't need a map:
   exit to keel-discover directly.
3. **Create** `MAP.md` and the tickets you can state sharply now, numbered
   in dependency order, `Blocked by` wired. Everything else → fog sections.
4. **Fire `keel-wayfind-researcher` subagents** for any research tickets (never
   `general-purpose`, no model override); wire their Resolutions in as they
   land, and broadcast each as it returns. Cap concurrent researchers at 8.
   A ticket that turns out to need the user's preference rather than an
   external fact was mis-typed — retype it as HITL, don't let a researcher
   guess an answer that then reads as fact in later sessions.
5. Stop. Charting is one session's work.

### Work the map (every later session)

1. Read `MAP.md` first — not every ticket body. The **frontier** = open
   tickets whose blockers are all resolved.
2. Pick the ticket: the user's named one, else the first frontier ticket.
3. Resolve it by its type. Zoom into related resolved tickets on demand.
4. Record: fill the ticket's Resolution, flip Status to resolved, append
   the one-line gist to Decisions so far.
5. Tend the map: graduate any fog the answer sharpened into new tickets
   (removing it from Not yet specified), rule newly-revealed out-of-scope
   items out, update or drop tickets the decision invalidated.
6. If no open tickets remain and the fog sections are empty → the way is
   clear: exit to **keel-discover** (or keel-plan), linking the map as input.

## Red flags

- Writing implementation code inside a wayfind session → the map plans; exit to the pipeline to build
- A ticket whose resolution is "we built it" → that was a build slice, not a decision
- Ticketing something you can't yet phrase sharply → that's fog, leave it in Not yet specified
- Resolving three tickets in one sitting because they "seemed quick" → depth per decision is the point; one per session
- Answering a grilling ticket's questions yourself because the user is away → HITL means the user decides; park it and take a research/task ticket instead
