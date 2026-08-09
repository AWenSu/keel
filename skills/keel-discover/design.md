# Design vocabulary & test-strategy reference

Shared reference for keel-discover (seam negotiation), keel-plan (Interfaces),
keel-execute (reviewer briefs), keel-debug (Phase 5 seam findings).
Source: mattpocock/skills codebase-design + DEEPENING @1.2.0 (Ousterhout,
_A Philosophy of Software Design_).

## Vocabulary — use these terms exactly

Never substitute "component", "service", "unit", "API", "signature", or
"boundary" — precision here is what makes design discussion cheap.

- **Module** — anything with an interface and an implementation: a function,
  class, file, package, or system.
- **Interface** — what a caller must know to use a module. Smaller is better.
- **Depth** — implementation hidden per unit of interface. **Deep module =
  small interface + lots of implementation** (good). Shallow module = large
  interface + little implementation (avoid — it adds surface without hiding
  anything).
- **Seam** — a public interface where behavior is observable and testable
  without reaching inside.
- **Adapter** — a module translating between an interface you own and a
  dependency you don't.
- **Leverage** — capability delivered per unit of interface exposed.
- **Locality** — change, bugs, knowledge, and verification concentrate in one
  place rather than spreading across callers. Fix once, fixed everywhere.

## Judgment tools

- **Deletion test:** would deleting this module concentrate complexity
  behind a better interface — or just move the same complexity somewhere
  else? If it just moves, the module isn't earning its place.
- **One adapter is a hypothetical seam. Two adapters make it real.** A port
  with a single implementation is indirection, not a seam — don't build the
  second implementation speculatively; note it and keep the design honest
  about which seams actually exist.
- **Testable-design rules:** accept dependencies, don't create them; return
  results, don't produce side effects; keep the surface area small.

## Dependency categories → test strategy

Classify every dependency of the module under design; the category decides
the test approach mechanically:

| Category | Example | Test with |
|----------|---------|-----------|
| 1. In-process, owned | your own modules | the real thing — no mocks |
| 2. Locally substitutable | Postgres→PGLite, fs→in-mem | the stand-in |
| 3. Remote but owned | your own HTTP service | port + in-memory adapter |
| 4. True external | Stripe, LLM APIs | injected port + mock adapter mirroring the full real shape |

Corollary — **replace, don't layer:** once tests exist at a deepened
module's seam, old unit tests pinned to the shallow internals it absorbed
are waste; delete them.
