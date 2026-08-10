---
name: dz-test-writing
description: Load when writing tests — one-scenario-per-test, naming cases by the business rule, fixture reuse, grouping related tests, behavior coverage, and no implementation-detail ties.
---

# Test writing strategy

- **One scenario per test.** Multiple inputs → separate tests or a parameterized test, never chained scenarios in one method.
- Tests **mirror the subject's location** and use a predictable name (`<Subject>Test` / `test_<subject>`). The failure message should name the broken case unambiguously.
- **Name each case by the business rule, not the variable values.** The condition part of a test name says *why* the case matters in domain terms, not the mechanical state of an input. A branch guarding a missing name → `missingName` / `productWithoutName` (whichever fits the context), never `nameIsNull` / `nullName`. A reader should learn the rule under test from the name alone, and the name should survive a refactor of *how* the rule is implemented (the field becoming an `Optional`, the check moving) — a name tied to `null` rots the moment the mechanics change.
- **Reuse fixtures/builders** before writing new ones; shared fixtures live in the shared test module, not copied per package.
- Test **behavior, not implementation**; cover boundaries and error paths, not just the happy path.
- Prefer a shared setup helper over hand-stacked boilerplate; keep tests free of logic.
- **Group related tests.** Once **5+** tests target the same method or a common scenario family, group them: at minimum keep them **contiguous and ordered** in the file, but prefer the language's **native grouping construct** (a nested test class, a `describe` block). A group reads as a unit and can share its own setup. Below the threshold, ordering alone is enough.
