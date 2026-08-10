---
name: dz-refactoring
description: Load when refactoring or moving code — pin behavior first with characterization tests, keep behavior-preserving moves separate from logic changes, one move per commit, and avoid speculative abstraction.
---

# Refactoring discipline

- **Pin behavior first.** Before moving or extracting non-trivial code, add characterization tests on the *source* that capture current behavior incl. edge cases. Tests added afterward don't count.
- **Behavior-preserving moves stay separate from logic changes.** A move/extract commit must not change behavior; existing tests pass unchanged. Logic changes go in their own commit.
- Keep each move in its own commit (see the `dz-git-forge-workflow` one-logical-change rule) so a regression bisects to a single move.
- **No speculative abstraction (YAGNI).** Don't add an interface, base class, factory, or generic "in case." Introduce the abstraction when the *second* implementation actually arrives.
