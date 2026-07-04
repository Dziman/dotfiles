# Dyslexia Directive

The user is dyslexic — less text to read is a genuine accessibility need. State the answer once, up front, in one representation; support it, don't restate it in multiple formats. Narrate steps in ≤6-word fragments — what, not why ("Checking glossary.", never "Per the repo rules, let me check the glossary to give you an accurate answer"). Do not buy brevity by searching less or dropping source citations — keep the rigor, cut the repetition.

## Shell tool preferences

Prefer `rg` (ripgrep) over `grep` and `fd` over `find` for all shell-driven search and file-discovery tasks — they're faster, respect `.gitignore` by default, and produce cleaner output. Fall back to `grep`/`find` only when `rg`/`fd` are unavailable on the host or when a flag/behavior is genuinely missing.

Do not use `-exec` (or `-execdir`, `--exec`, `-X`) with `fd` or `find`. Pipe into `xargs` (prefer `xargs -0` with `-print0`/`--print0`) or a `while read -r` loop instead — it's easier to inspect, composes with other shell tooling, and avoids per-file fork overhead.

## General behavior

- Be direct, concise, and action-oriented.
- Inspect relevant project files before making changes.
- Follow existing project conventions, language, framework, and style.
- Make the smallest safe change needed to solve the task.
- Do not commit changes unless explicitly requested.
- Do not run destructive commands unless explicitly requested.
- Ask before changing architecture, dependencies, CI/CD, public APIs, or database schemas.
- Never expose secrets, tokens, credentials, or private user data.
- Prefer reversible changes and clear diffs.
- For multi-file tasks, read relevant files first to understand context, then plan edits before executing them.

## Scope discipline

- Complete the user's requested task first.
- Do not silently expand scope (e.g. adding tests, refactoring, fixing unrelated issues) beyond what was asked.
- If you notice violations of global/project rules (missing tests, style issues, etc.) while working, **ask** the user after completing the task: "While making changes I noticed X. Do you want me to handle it now?"
- Never do extra work without explicit user confirmation.

## Coding standards

- Keep changes focused and minimal.
- Update tests when behavior changes.
- Update documentation when adding or changing user-facing behavior.
- Discover the project's check, lint, and test commands (inspect README, package.json scripts, Makefile, task runners, etc.) and run them after changes. Read error output and iterate until they pass.
- After editing files, stop — do not summarize what was changed unless asked.
- Do not add comments that merely restate what the code or config already expresses. Assume the reader is fluent in the language and does not need the purpose of a statement explained inline.
- Do not add comments explaining why something was added, updated, or removed — this context belongs in the commit message. Only add comments when the solution is tricky or non-obvious and cannot be understood from the code alone.

## Repository hygiene

- Preserve existing formatting unless the project requires a different style.
- Avoid unnecessary generated files.
- Do not modify lockfiles unless dependencies actually change.
- Ensure files end with an empty line (enforced via `insert_final_newline = true` in `.editorconfig`, if present).

## Git / Forge

- Repositories on `git.blakitka.home` are managed by **Forgejo**.
- Use the `fj` CLI tool to manage PRs, MRs, issues, and other forge operations (not `glab` or `gh`).
- Example: `fj pr create`, `fj pr view`, `fj pr list`, etc.
- `fj pr create` opens an editor by default. Use `--body <text>` to provide the PR body inline and skip the editor.
- **Do not commit directly to `main` or `develop`.** These branches are protected — all development and bugfixing must happen on a feature/bugfix branch.
- Before the **first commit task** in a session:
  1. Check the current branch (`git branch --show-current`).
  2. If already on a non-protected branch (`main`/`develop`), ask the user whether to stay on it or create a new branch.
  3. If on `main`/`develop`, or the user wants a new branch, **do not commit until the user confirms the branch**.
  4. Suggest a branch name in this priority order:
     - **Project conventions** (e.g. `feat/finhea-123-foo`, `web/`, `api/` prefixes — see project CONTRIBUTING or recent branch names).
     - **Global user conventions** (e.g. `<type>/<short-slug>` patterns visible in the repo).
     - **Generic best practice**: `<type>/<concise-kebab-slug>` where `type` ∈ {`feat`, `fix`, `chore`, `refactor`, `test`, `docs`}.
  5. Create the branch only after explicit user confirmation.
- Once a user confirms (or chooses) a branch for the first commit, **all subsequent commits in that session go to the same branch** without re-asking, unless the user explicitly requests otherwise.
- Commit message should contain description what logically was done, without listing updated files.
- **Do not push to remote without explicit user confirmation.** You may suggest pushing and explain why it's safe/ useful, but the actual `git push` (and `fj pr create` / `gh pr create`) must only run after the user explicitly approves.
