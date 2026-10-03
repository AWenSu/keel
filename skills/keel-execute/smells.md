# Smell baseline (Fowler, _Refactoring_ ch.3 — via mattpocock/skills code-review)

Fixed reference for reviewer subagents. Match each smell against the diff.
Binding rules:

- **The repo overrides.** A documented repo standard (CODING_STANDARDS.md,
  CONTRIBUTING.md, CLAUDE.md) always wins; where it endorses something this
  list would flag, suppress the smell.
- **Always a judgement call.** Report each hit as a labelled heuristic
  ("possible Feature Envy"), never a hard violation. Skip anything tooling
  (linter, formatter, type checker) already enforces.

Each smell: what it is → how to fix.

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

# Testing anti-patterns (superpowers TDD + mattpocock tdd)

Unlike the smells above, these are hard findings, not judgement calls —
each one silently defeats the test's reason to exist.

- **Testing mock behavior** — the assertion verifies what the mock was told to return, so the test passes whether or not the real code works. → assert on the unit's real output/effects; mocks only stand in for boundaries.
- **Tautological test** — the expected value is computed the same way the code computes it (`expect(add(a,b)).toBe(a+b)`); it passes by construction and can never disagree with the code. → expected values come from an independent source of truth: a known-good literal, a worked example, the spec.
- **Test-only methods on production classes** — production code grows a method that exists only so a test can reach inside. → test through the public interface; if you can't, the seam is wrong (report it).
- **Mock at the wrong level** — mocking an internal collaborator instead of the system boundary, so the test pins implementation, not behavior. → understand the dependency chain first; mock only what you don't control.
- **Partial mock drift** — a mock that mirrors only part of the real structure; code paths reading the unmocked part fail silently or pass wrongly. → mocks mirror the complete real shape, or use a real/in-memory implementation instead.

# Runtime cost smells (ported 2026-09-13 from a locally-installed reviewer agent's performance dimension)

Fowler's catalogue is about structure; none of it fires on code that is
correctly shaped and still too slow. These are the ones that reach production
looking fine, because every unit test runs against three rows:

- **N+1** — a query inside a loop over rows another query returned. Grade by
  what the loop is over: a fixed-size config list is not an N+1, a user's
  orders is.
- **Unbounded fetch** — a list endpoint, a `SELECT` with no `LIMIT`, or a
  read of a whole directory/table whose size the caller does not control.
  Missing pagination on a collection that grows is this smell, not a feature
  request.
- **Sync in an async path** — a blocking call (file, network, crypto,
  `sleep`) on a request path or event loop the rest of which is async.
- **Repeated work per item** — recompiling a regex, re-reading a config,
  re-establishing a connection, once per iteration instead of once.
- **Re-render storms** (UI) — a new object/array/closure identity created in
  render and passed as a prop or dependency, so memoisation never holds.

Each still owes the evidence gate's two halves: the quoted line, and the
concrete input size or state at which it actually hurts. "This is O(n²)" with
no statement of what n is in this system is a shape observation, not a
finding.

# Comment smells (Google eng-practices, review/reviewer/looking-for; Lauren Tan's Cursor Compile 2026 talk and pstack no-comments skill)

**A comment the diff adds needs a reason from this list, or it is a finding:**
a license header; behaviour forced by an external dependency, platform, or
protocol this repo cannot change; a doc comment that defines a public API
contract; a link to an issue or spec for a constraint the code cannot express;
a regular expression or non-obvious algorithm. Anything else — narration,
section banners, commented-out code, notes to the next reader about our own
code — is deleted, and the surprise it explained is fixed by renaming,
extracting, or typing until the code says it. This holds even in a repo full of
comments: agents copy the patterns they read, so a comment habit spreads the way
a workaround does, and the diff is graded on what it adds, not on matching the
volume around it. Comments the diff did not touch are out of scope.

- **Comment that justifies a workaround** — "known issue", "fine for now",
  "too risky to change", "temporary", or a paragraph explaining why the real
  fix was not made. Grade it as an **unfixed problem, not a comment**: the
  comment is how the band-aid passed review, and the next agent will read it as
  permission to add another. The finding is the workaround; deleting the
  comment alone does not close it.
- **A constraint that lives only in a comment** — "do not remove", "must stay
  in this order", "talk to X before changing". Prose is the weakest place a
  constraint can live: the next agent may not read it, and nothing fails when
  it is ignored. The finding asks for the cheapest enforcement in scope — a
  type, a runtime check, a test, a lint rule — and the comment goes once that
  exists. A constraint nothing in scope can enforce is reported, not kept as
  the only guard.
- **Lint or type-check suppression** (eslint-disable, `@ts-ignore`,
  `# noqa`, `# type: ignore`) — the same test: if the silenced rule catches
  real bugs, the suppression is the finding and the code under it is what gets
  fixed. Suppressing a style-only or demonstrably wrong rule is fine.
- **Comment explains *what*, not *why*** — a comment restating the line below
  it is a signal the line should be simpler, not that the comment is missing.
  The fix is to rewrite the code; adding the comment closes the case at the
  wrong end. Exceptions that genuinely need a "what": regular expressions and
  non-obvious algorithms.
- **Comment that only exists in the review** — an explanation the author gave
  in a report or a reply, for something a future reader will hit too, belongs
  in the code or the docs. A review thread is not a place future readers look.
- **Stale comment left beside changed code** — the diff moved and the comment
  did not. Grade this as wrong, not as untidy: a comment that contradicts the
  code is worse than no comment, because it is believed.
