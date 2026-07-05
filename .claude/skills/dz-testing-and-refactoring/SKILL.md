---
name: dz-testing-and-refactoring
description: Load when writing tests or refactoring/moving code — one-scenario-per-test, naming cases by the business rule, fixture reuse, grouping related tests, characterization-tests-first, and keeping behavior-preserving moves in their own commit.
---

# Testing strategy

- **One scenario per test.** Multiple inputs → separate tests or a parameterized test, never chained scenarios in one method.
- Tests **mirror the subject's location** and use a predictable name (`<Subject>Test` / `test_<subject>`). The failure message should name the broken case unambiguously.
- **Name each case by the business rule, not the variable values.** The condition part of a test name says *why* the case matters in domain terms, not the mechanical state of an input. A branch guarding a missing name → `missingName` / `productWithoutName` (whichever fits the context), never `nameIsNull` / `nullName`. A reader should learn the rule under test from the name alone, and the name should survive a refactor of *how* the rule is implemented (the field becoming an `Optional`, the check moving) — a name tied to `null` rots the moment the mechanics change.
- **Reuse fixtures/builders** before writing new ones; shared fixtures live in the shared test module, not copied per package.
- Test **behavior, not implementation**; cover boundaries and error paths, not just the happy path.
- Prefer a shared setup helper over hand-stacked boilerplate; keep tests free of logic.
- **Group related tests.** Once **5+** tests target the same method or a common scenario family, group them: at minimum keep them **contiguous and ordered** in the file, but prefer the language's **native grouping construct** (a nested test class, a `describe` block). A group reads as a unit and can share its own setup. Below the threshold, ordering alone is enough.

# Refactoring discipline

- **Pin behavior first.** Before moving or extracting non-trivial code, add characterization tests on the *source* that capture current behavior incl. edge cases. Tests added afterward don't count.
- **Behavior-preserving moves stay separate from logic changes.** A move/extract commit must not change behavior; existing tests pass unchanged. Logic changes go in their own commit.
- Keep each move in its own commit (see the `dz-git-forge-workflow` one-logical-change rule) so a regression bisects to a single move.
- **No speculative abstraction (YAGNI).** Don't add an interface, base class, factory, or generic "in case." Introduce the abstraction when the *second* implementation actually arrives.
