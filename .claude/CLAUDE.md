# Dyslexia Directive

The user is dyslexic — less text to read is a genuine accessibility need. State the answer once, up front, in one representation; support it, don't restate it in multiple formats. Narrate steps in ≤6-word fragments — what, not why ("Checking glossary.", never "Per the repo rules, let me check the glossary to give you an accurate answer"). Do not buy brevity by searching less or dropping source citations — keep the rigor, cut the repetition.

# Tools

- Prefer `rg` (ripgrep) over `grep` and `fd` over `find` for all shell-driven search and file-discovery tasks — they're faster, respect `.gitignore` by default, and produce cleaner output. Fall back to `grep`/`find` only when `rg`/`fd` are unavailable on the host or when a flag/behavior is genuinely missing.
- Do not use `-exec` (or `-execdir`, `--exec`, `-X`) with `fd` or `find`. Pipe into `xargs` (prefer `xargs -0` with `-print0`/`--print0`) or a `while read -r` loop instead — it's easier to inspect, composes with other shell tooling, and avoids per-file fork overhead.
- When a **language server (LSP)** or an IDE's semantic refactoring is available for the project's language, use it for the operations it performs correctly — **symbol rename**,  find-references, go-to-definition, change-signature, extract / inline, move, organize-imports. Prefer it over text manipulation (`grep` / `sed` / `awk` / regex find-replace).

# Skills

Load the matching skill before doing the work — its rules are authoritative for that task:

- Writing, editing, or reviewing code → load `dz-coding-standards`.
- Writing tests → load `dz-test-writing`.
- Refactoring or moving code → load `dz-refactoring`.
- Committing, branching, opening PRs/MRs, or validating before a commit → load `dz-git-forge-workflow`.

## Brainstorming

- Whenever you write or edit a spec or plan file (e.g. via `superpowers:brainstorming`
  or `superpowers:writing-plans`), you MUST paste its **full, final, verbatim content**
  into the conversation in the same turn you write it. This is mandatory, not optional.
- Show the complete file, not a summary, paraphrase, excerpt, or the design outline you
  discussed earlier — the exact bytes that landed on disk.
- Do both every time: write/update the file AND show its content. Re-show the full
  content after **every** subsequent edit to that file.
- Show it **before** committing the file — never let a spec/plan reach a commit, or end
  a turn, with the user holding only a file path, a summary, or a diff.

# General behavior

- Be direct, concise, and action-oriented.
- Assume the user is fluent in the language/framework in use; never restate or narrate what code does in plain language — refer to it directly (symbols, diffs, file:line) instead.
- Inspect relevant project files before making changes.
- Follow existing project conventions, language, framework, and style.
- Make the smallest safe change needed to solve the task; prefer reversible changes and clear diffs.
- Do not commit or push changes unless explicitly requested.
- Every commit made by the agent MUST include a `Co-Authored-By:` trailer identifying the model that produced the changes, in the form `Co-Authored-By: <model-name>`. Place the trailer after the commit body, separated by a blank line.
- Do not run destructive commands unless explicitly requested.
- Ask before changing architecture, dependencies, CI/CD, public APIs, or database schemas.
- Never expose secrets, tokens, credentials, or private user data.
- For multi-file tasks, read relevant files first to understand context, then plan edits before executing them.

# Coding standards

- Keep changes focused and minimal; update tests when behavior changes.
- Update documentation when adding or changing user-facing behavior.
- After editing files, stop — do not summarize what was changed unless asked.

# Scope discipline

- Complete the user's requested task first.
- Do not silently expand scope (e.g. adding tests, refactoring, fixing unrelated issues) beyond what was asked.
- If you notice violations of global/project rules (missing tests, style issues, etc.) while working, **ask** the user after completing the task: "While making changes I noticed X. Do you want me to handle it now?"
- Never do extra work without explicit user confirmation.

# Repository hygiene

- Preserve existing formatting unless the project requires a different style.
- Avoid unnecessary generated files.
- Do not modify lockfiles unless dependencies actually change.
- Ensure files end with an empty line (enforced via `insert_final_newline = true` in `.editorconfig`, if present).

@RTK.md
