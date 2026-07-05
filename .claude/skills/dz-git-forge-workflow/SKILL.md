---
name: dz-git-forge-workflow
description: Load when committing, branching, opening PRs/MRs, or validating before a commit — Forgejo/`fj` CLI usage, protected branches, branch-before-first-commit, one-logical-change commits, no-push-without-confirmation, and the format→lint→build→test validation order.
---

# Git / Forge

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
- **One logical change per commit.** Keep behavior-preserving changes separate from logic changes. Justify notable decisions in the commit/PR message (a new dependency, a widened public surface, a deprecation, a checked-exception introduction).
- **Do not push to remote without explicit user confirmation.** You may suggest pushing and explain why it's safe/ useful, but the actual `git push` (and `fj pr create` / `gh pr create`) must only run after the user explicitly approves.

# Work validation

- Validation should happen before any commit or declaring that work is completed
- validation steps to be performed (order matters):
  1. formatting
  2. linters/static analysis
  3. build, compilation
  4. tests
- validation step can be skipped if project does not have corresponding setup (for example no linter is set in project, then linter step can be skipped)
- if any validation step is failing - stop. Fix issue before proceeding further
- validation should cover widest scope possible. For example tests should be run for a whole project, not just for files/classes updated. If current git repository contains other project which depend on current then they also need to be validated (build and tests steps)
