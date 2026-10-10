---
description: Model tier routing for superpowers subagent dispatches
alwaysApply: true
---

When a superpowers skill dispatches a `general-purpose` subagent and picks a model tier, set `agent` instead of a model:

- Implementation / fix work: `impl-cheap`, `impl-standard`, `impl-capable`.
- Any review (task, re-review, spec/plan, code, final branch review): `review-cheap`, `review-standard`, `review-capable` (a different model family from the author, by design).
- Tier = the skill's choice: cheapest → `cheap`, standard/mid → `standard`, most capable → `capable`. "One tier above" escalation moves up within the same family.
- Never review with the family that wrote the work. If a `review-*` agent fails to start, report it; do not silently fall back to a reviewer from the author's family.
