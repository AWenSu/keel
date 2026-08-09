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
