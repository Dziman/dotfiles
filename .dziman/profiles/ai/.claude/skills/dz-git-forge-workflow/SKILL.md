---
name: dz-git-forge-workflow
description: Use when working with Git and Forgejo repositories, especially branches, commits, pull requests, issues, releases, actions, tags, reviews, or pre-commit validation.
---

# Git / Forgejo

Repositories on `git.nasha.casa` use Forgejo.

- Use `git` for local repository state, branches, commits, diffs, and remotes.
- Use `fj` for Forgejo repositories, issues, pull requests, releases, actions, tags, reviews, and repository metadata.
- Never use `gh`, `glab`, GitHub APIs, or GitLab APIs for Forgejo operations.
- Do not translate flags mechanically from `gh`. `fj` has different command names, arguments, and option placement.

## Command discovery

The installed `fj` version is authoritative. Never guess an argument.

For an unfamiliar operation, run the narrowest relevant help command first:

    fj --help
    fj <group> --help
    fj <group> <command> --help

Use `--host git.nasha.casa` when the host is not already configured. Check authentication with `fj auth list` and identity with `fj whoami`. Do not expose tokens or credentials.

## GitHub CLI to `fj` mapping

| GitHub CLI | Forgejo CLI |
|---|---|
| `gh auth status` | `fj auth list`; `fj whoami` |
| `gh repo view` | `fj repo view` |
| `gh repo clone` | `fj repo clone` |
| `gh repo fork` | `fj repo fork` |
| `gh repo create` | `fj repo create` |
| `gh repo edit` | `fj repo edit` |
| `gh repo browse` | `fj repo browse` |
| `gh issue list` | `fj issue search` |
| `gh issue view` | `fj issue view` |
| `gh issue create` | `fj issue create` |
| `gh issue comment` | `fj issue comment` |
| `gh issue edit` | `fj issue edit` |
| `gh issue close` | `fj issue close` |
| `gh pr list` | `fj pr search` |
| `gh pr view` | `fj pr view` |
| `gh pr create` | `fj pr create` |
| `gh pr checks` | `fj pr status` |
| `gh pr comment` | `fj pr comment` |
| `gh pr edit` | `fj pr edit` |
| `gh pr close` | `fj pr close` |
| `gh pr merge` | `fj pr merge` |
| `gh pr checkout` | `fj pr checkout` |
| `gh pr diff` | `fj pr view <id> diff` |
| `gh pr review` | No approve or request-changes; for conversations use `fj pr review conversations`, `show`, `reply`, `resolve`, `unresolve` |
| `gh release list/view` | `fj release list/view` |
| `gh release create` | `fj release create` |
| `gh release edit/delete` | `fj release edit/delete` |
| `gh release upload` | `fj release asset create` |
| `gh release download` | `fj release asset download` |
| `gh run list` | `fj actions tasks` |
| `gh run view/watch/rerun` | No direct equivalent; `fj actions tasks` only lists tasks |
| `gh workflow run` | `fj actions dispatch` |
| `gh workflow list` | No direct equivalent; inspect `fj actions --help` |
| `gh secret ...` | `fj actions secrets ...` |
| `gh variable ...` | `fj actions variables ...` |
| `gh label ...` | `fj repo labels ...` |
| `gh api` | No generic equivalent; use a supported `fj` command |

The table maps operations, not flags. Always inspect leaf-command help before composing the final invocation.

## Verified command shapes

Use non-interactive body options when available:

    fj issue search --remote origin --state open --assignee <username>
    fj issue create --repo <owner/repo> --body '<body>' '<title>'
    fj pr create --base <base> --head <head> --body '<body>' '<title>'
    fj pr create --base <base> --head <head> --autofill '<title>'
    fj pr status <id>
    fj pr status --wait <id>
    fj pr comment <id> '<body>'
    fj pr view <pr> --json
    fj pr review <pr> list --json
    fj pr review <pr> conversations --unresolved --json
    fj pr review <pr> create --file review.json
    fj pr review <pr> list --comments --all
    fj pr review <pr> conversations --unresolved
    fj pr review <pr> show <comment>
    fj pr review <pr> reply <comment> --body-file <file>
    fj pr review <pr> resolve <comment>...
    fj release create --repo <owner/repo> --tag <tag> --body '<body>' '<name>'
    fj actions tasks --repo <owner/repo>
    fj actions dispatch --repo <owner/repo> <workflow> <ref>

`fj issue`, `fj pr`, `fj release`, and `fj actions` accept repository context through their documented `--remote`/`--repo` options. Check the leaf command's help because option placement differs by command.

`fj release create` requires a positional release name even when `--tag` points to an existing tag. It has no `--generate-notes`; provide notes with `--body`.

## Common mistakes

- `fj pr list` is not a command in the installed CLI; use `fj pr search`.
- `gh pr checks` maps to `fj pr status`, not `fj pr checks`.
- `fj pr review create --file review.json` posts a review in one request: `body`, `event` (`COMMENT`, `APPROVED` or `REQUEST_CHANGES`; fj refuses anything else, since Forgejo would store it as a silent draft), an optional `commit_id` (may be abbreviated to 7 or more characters), and `comments` with `path`, `new_position`/`old_position` and `body`. A comment on a line the diff does not show goes into the review text under "Not placed" instead of failing the review. `reply`, `resolve` and `unresolve` need a server running our Forgejo fork (v16.0.6-dz.1 or later), as git.nasha.casa does; a stock Forgejo answers that it lacks the API. Any comment id of a conversation names it, with or without `#`.
- `--json` on `pr view`, `pr review list`, `conversations` and `show` prints the server's own objects (conversations: `id`, `review_id`, `path`, `line`, `resolved`, `resolver`, `comments`); read fields from it instead of parsing text.
- Up to fj 0.6.0-dz.1, `fj pr create --body` fails with `expected header` in a repo whose PR template is a form; 0.6.0-dz.2 fixes it. With an older fj, open the PR by AGit push instead: `git push <remote> <branch>:refs/for/<base> -o topic=<slug> -o title=<title> -o description=<body>`.
- Do not assume `--title`, `--state`, `--assignee`, or `--generate-notes` exists. Confirm it with leaf help.
- Use `--body` or `--body-file` where supported to avoid an editor. `fj release create` uses `--body` and has no documented `--body-file`.
- If no direct `fj` command exists, stop and report that gap. Do not silently fall back to `gh`, `glab`, or an unverified API call.

## Branches, commits, and safety

- Do not commit directly to `main` or `develop`. These branches are protected.
- Before the first commit task:
  1. Run `git branch --show-current`.
  2. If on `main` or `develop`, ask the user to confirm a feature/bugfix branch.
  3. Prefer project branch conventions, then `<type>/<concise-kebab-slug>`.
- Keep one logical change per commit.
- Do not push without explicit user confirmation.
- Do not run `fj pr create` or `fj pr merge` without explicit user confirmation.
- A request to create a pull request does not authorize pushing its branch. Ask separately before running `git push`.

## Work validation

Before committing or declaring work complete, run the widest applicable validation in this order:

1. Formatting
2. Linters/static analysis
3. Build/compilation
4. Tests

Skip a step only when the project has no corresponding setup. If a step fails, stop and fix it before proceeding.
