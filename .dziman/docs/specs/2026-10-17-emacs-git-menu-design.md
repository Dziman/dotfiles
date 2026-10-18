# Emacs git menu — design

Date: 2026-10-17
Status: approved design, implemented

## Goal

One key, `C-. g`, opens a git menu that shows only the actions that apply where you
are: this file, this repository, and the pull request that brought in the current
line. Merge conflicts get a separate menu, since they are rare and obvious.

Why: the daily file jobs — file history, blame, diff of this file against the
default branch — have no key today, and finding the PR behind a line means leaving
Emacs and digging through the forge's web UI.

## Scope

In:

- File actions, repository actions, pull request lookup, and a merge-conflict menu.
- Forges: github.com, and Forgejo and Gitea instances, self-hosted included.
- A read-only pull request view inside Emacs.
- Cheat sheet update (`.dziman/docs/emacs-prog-cheatsheet.org`, the `* Git` section).

Out (non-goals):

- Writing to a forge from Emacs: replying, approving, merging, creating PRs.
- GitLab, GitHub Enterprise and other forges.
- Tokens or login handling in Emacs: the forge CLIs (`fj`, `gh`) own auth.
- `git init` and `git clone` from the menu.
- Magit's Forge package (`magit/forge`): it fully supports only GitHub and GitLab,
  and lists Gitea and Forgejo as partial (https://docs.magit.vc/forge/).

Anti-goals (failure even if it works):

- A menu cluttered with keys that do nothing in the current buffer.
- Conflict keys taking space in the daily menu.
- Slower Emacs startup. Packages stay deferred, as in `dz-config-git.el` today.

## Current state (2026-10-17)

- `.emacs-dziman/configs/dz-config-git.el` defines `dziman/hydra/git` (pretty-hydra,
  `:color amaranth`, on `C-. g`): changed-hunk jump, show, stage and revert
  (git-gutter), set gutter start revision, git-timemachine, and web links (git-link
  for file and lines, commit, repo home page).
- Installed: magit (with transient), git-gutter, git-timemachine, git-link,
  git-modes, magit-todos, markdown-mode.
- Magit's own keys stay as they are: `C-x g` status, `C-x M-g` all commands,
  `C-c M-g` file commands.
- No blame, file log, branch comparison or conflict keys of our own.
- `fj` (Forgejo CLI) is installed and logged in; `gh` is not installed. `fj pr view
  <number>` gives the PR as JSON (`--json`) and has `body`, `files`, `commits`,
  `diff` and `comments` subcommands. `fj` has no generic API call and no
  commit-to-PR lookup.
- The other `C-.` menus (`t` toggles, `h` mode menu) stay pretty-hydra.

## Design

### Menu library

Transient, the menu library Magit uses. Each key carries its own condition and is
hidden when it does not apply. This replaces the pretty-hydra on `C-. g`; the look
differs from the other `C-.` menus, which is accepted.

### Context rules

Which keys show:

- **A file in a repo:** file actions plus repository actions.
- **Not a file** (Magit status, terminal, scratch): repository actions only.
- **Directory listing (dired):** file actions apply to the file under the cursor.
- **File git does not track:** only "add to git" from the file group; no history,
  blame or PR.
- **File with no local changes:** no stage, unstage, discard, or diff against the
  last commit.
- **On the default branch:** no diff with default branch, no "commits not on default
  branch", no rebase onto default branch.
- **No PR tool for the remote's host:** no PR key. See "Forge and CLI per host".
- **Web links:** shown when git-link knows the remote's host, or `fj` is logged into it
  (Forgejo and Gitea links).
- **Outside any repo:** the menu says "not a git repo" and nothing else.
- **File has merge conflicts:** one key opens the conflict menu.

### File actions

- History of this file.
- Blame.
- History of the selected lines (`git log -L`).
- Diff against the last commit.
- Diff against the default branch: what this branch changed in the file since it
  left the default branch (merge base, like `git diff main...HEAD -- file`).
- Stage or unstage the whole file.
- Discard all local changes to the file.
- Open this file as it is on another branch, read-only.
- Rename or delete the file through git.
- Step through file history (git-timemachine) — kept from today's menu.
- Changed hunks: next, previous, end, show, stage, revert, refresh, set gutter start
  revision — kept from today's menu, and they keep the menu open so you can step
  through hunks.
- Web links: file and lines, commit at point, repo home page — kept.

### Repository actions

- Status.
- Commit; amend the last commit.
- Switch branch; create a branch.
- Log of the current branch.
- Commits not yet on the default branch.
- Diff of the whole branch against the default branch (merge base, as above).
- Fetch, pull, push.
- Stash; pop.
- Rebase onto the default branch.
- Refresh the remembered default branch (`git remote set-head <remote> --auto`).

### Default branch

Taken from git, not guessed by name:

1. Pick the remote: the one the current branch pushes to; else `upstream`; else
   `origin`.
2. Read that remote's default (`refs/remotes/<remote>/HEAD`), recorded at clone time.
3. If unset (repo made with `git init`, or never recorded), the first of `develop`,
   `main`, `master` that exists.

### Forge and CLI per host

Emacs talks to forges only through their CLIs, which handle login:

- **github.com:** `gh`, when installed.
- **Forgejo and Gitea:** `fj`, for hosts listed by `fj auth list`. Gitea is assumed
  to work through `fj`, since its API matches Forgejo's for these calls.
- **Any other host, or the CLI missing:** no PR key.

### Pull request for a line

On a line, one key finds the PR that brought it in. Rule: best effort to find the
PR, the commit as fallback. Blame the line to get the commit, then try each way in
order, cheapest first, stopping at the first PR found. They are not exclusive: each
catches a different merge style.

1. **Squash merges:** the commit's own message names a PR — "(#42)" in the subject.
2. **Merge commits:** the merge commit that brought the commit into the current
   branch names a PR — "Merge pull request #42 …" (GitHub) or "… (#42) from …"
   (Forgejo, Gitea). Local git only.
3. **github.com:** ask `gh`: `gh api repos/{owner}/{repo}/commits/{sha}/pulls`
   (https://docs.github.com/rest/commits).
4. **Fast-forward merges:** list every PR's last commit from the remote
   (`git ls-remote <remote> 'refs/pull/*/head'`; Forgejo, Gitea and GitHub publish
   these) and pick the PR whose commits contain the line's commit. One network call.
5. **Fallback:** no PR found — say so and offer to open the commit instead. Still a
   gap on Forgejo and Gitea: rebase-merged PRs (the server rewrites commit ids) and
   commits pushed straight to the branch.

Then a one-key choice:

- `l` show the link (also copied).
- `b` open in browser.
- `e` show in Emacs.

### Pull request view in Emacs

A read-only buffer, filled from the CLI (`fj pr view <number> --json` and its
subcommands; `gh pr view <number> --json …` and `gh pr diff`):

- Top: title, author, state (open, merged, closed), target and source branches, link.
- Description, rendered as Markdown.
- Commits, one line each. `RET` opens the commit in Magit when it is in the local
  repo; otherwise it says the commit is not fetched. Nothing is fetched behind your
  back.
- Changed files with lines added and removed. `RET` shows that file's part of the
  PR's diff, taken from the CLI.
- Conversation (comments and reviews) loaded only on a key press in the buffer.
- Keys: `b` browser, `l` copy link, `g` refresh, `q` close.

### Merge-conflict menu

Separate from the daily menu, reached from it only when the file has conflicts:

- Next and previous conflict.
- Keep mine, keep theirs, keep both.

## Calls made by Claude, not yet confirmed

- "Diff against the default branch" means since the branch left it (merge base), not
  against the default branch's latest commit.
- Which host runs Forgejo or Gitea is taken from `fj auth list`; no probing, no
  host list to maintain.
- GitHub Enterprise is out of scope.
- The PR view never fetches commits; missing ones are reported, not fetched.
- Gitea is served through `fj`.
- `l` in the PR choice also copies the link.

## Left to the builder

- Key letters, as long as they are mnemonic and match Magit's letters where Magit
  has the same action.
- Where the new code lives (`dz-config-git.el` or a new config file).
- Tests: ERT under `.emacs-dziman/tests/`, as for the other configs.
