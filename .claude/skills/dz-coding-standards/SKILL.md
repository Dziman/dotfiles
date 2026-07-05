---
name: dz-coding-standards
description: Load when writing, editing, or reviewing code in any language — comments/docstrings, naming, formatting, function and type design, absence/nullability, error and exception handling, dependency hygiene and layering, logging, configuration, public-API stability/deprecation, and discipline for editing existing code.
---

# Comments & docstrings

- Comments explain **why** (intent, trade-off, non-obvious constraint), not **what** the code already says. Delete commented-out code — that's what version control is for.
- Do not add comments that merely restate what the code or config already expresses; assume the reader is fluent in the language. Do not add comments explaining why something was added, updated, or removed — that context belongs in the commit message.
- Doc-comment the **public** surface; keep internal comments sparse and current. A wrong comment is worse than none.

# Naming

- Names reveal intent; length scales with scope — short for short-lived locals, descriptive for public API. Avoid abbreviations except universally understood ones (`id`, `url`, `db`).
- Booleans read as predicates (`isReady`, `hasItems`); collections are plural; functions are verbs, values are nouns. Don't encode the type in the name (`strName`, `listUsers`).

# Formatting & layout

- Follow the project's formatter/`.editorconfig` exactly; never hand-fight an auto-formatter. Absent one, keep lines reasonable (~100–120 cols), one statement per line, consistent indent.
- Group related code; separate logical blocks with a blank line; order members most-public-first (or however the file already does it).

# Function & method design

- One function, one job, one level of abstraction. Prefer **early returns / guard clauses** over deep nesting. Keep parameter lists short (~3–4); past that, pass an object/struct.
- Avoid boolean flag parameters that fork behavior — split into two functions.

# Class / type design

- Prefer **immutable** value types; expose the **narrowest** visibility that works; keep state private and invariants enforced in one place (the constructor/factory).
- Prefer composition over inheritance; an interface/abstract type earns its place only when a second implementation exists (see the `dz-testing-and-refactoring` no-speculative-abstraction rule).
- Use the language's data-carrier construct for plain data (record / dataclass / struct / `data class`) instead of hand-written getters.

# Absence & nullability

- Represent absence **in the type**, never as a bare `null`/`nil` returned silently. Return an **empty collection** for "no elements" and an **option/maybe type** for "no value".
- Keep the option type at the boundary it's designed for — **return values** — not fields, parameters, or collection elements.
- Adopt **one** nullability convention across the codebase (annotations or the type system) and apply it consistently. Every genuinely-nullable value is explicitly marked **and justified**.

# Error & exception handling

- **Catch the most specific type** the protected block can raise. Wildcard `catch (Exception)` / bare `except:` only at process/request boundaries — with a comment, a logged cause, and a controlled fallback or wrapped rethrow.
- **Never swallow.** A catch must rethrow, log with the throwable, or update observable state — never an empty body.
- **Preserve the cause** when wrapping (`throw new X("…", e)` / `raise X() from e`).
- Translate library/transport errors into your domain's error type at the **module boundary**.
- Format dynamic values into exception **messages**; use placeholders in **logs** (see *Logging*).

# Dependency hygiene & layering

- Keep the dependency graph **explicit** — declare what you use; don't rely on transitive deps to provide a type you reference directly.
- Export the **narrowest** surface: default to the private/internal tier; widen to public/ exported only when a type genuinely appears in your public signatures — and justify it.
- Respect **layering** and avoid **cycles**. Ask before adding a dependency whose placement is unclear. Justify each new third-party dependency; prefer the standard library; avoid a whole dependency for one function you could inline.

# Logging & observability

- **Parameterized/structured logging**, never string concatenation or eager formatting inside a log call (so a disabled level costs nothing). The error/throwable goes **last**.
- **Level semantics:** `error` = needs attention, always include the cause; `warn` = recoverable anomaly with triage context; `info` = lifecycle events, **never** in per-request/per-item hot paths; `debug` = per-item flow; `trace` = rare protocol detail.
- **Never log PII or secrets** at any level (emails, phones, addresses, names, payment data, tokens, API keys, account/loan IDs). When a value is genuinely needed, **redact** (hash / mask / last-4) and comment why the redacted form suffices. Omit forwarded upstream tokens entirely.

# Configuration

- No hardcoded environment-specific values; configure via files/env, not code. **Secrets never  in source.** Provide sane, **documented** defaults.

## Changing public / exported API (stability & deprecation)

- Identify the **public/exported surface** explicitly (exported types/members; published endpoints; anything a consumer compiles or links against).
- **Never break it silently.** Flag a potentially-breaking change and **ask**, offering: (a) *backward-compatible* — add the new API, mark the old deprecated-for-removal, track the deferred removal; or (b) *coordinated fix-forward* — break and update all known consumers in one sequence. Don't choose unilaterally.
- Every deprecation **names its replacement** and rationale. No replacement ⇒ no deprecation.

## Editing existing code (working discipline)

- **Touch-it-fix-it:** when you edit code that violates a convention, fix the violation in the same change rather than propagating it — but if the fix would ripple widely, note the deferred migration (in the PR/commit message) instead of silently spreading the smell.
- **Minimize unrelated churn:** don't reformat, rename, or restyle code you aren't changing. Match the surrounding style even if it differs from a default here.
- **Ask, don't silently choose,** for consequential or hard-to-reverse decisions.
