# Emacs Git Menu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `C-. g` opens a transient git menu that shows only the file, repository and pull request actions that apply in the current buffer, with a separate merge-conflict menu and a read-only PR view.

**Architecture:** `dz-config-git.el` (loaded at startup) keeps packages and git-gutter, drops the pretty-hydra, and binds `C-. g` to an autoloaded `dziman/git-menu`. Three files load on first use: `dz-config-git-menu.el` (context, default branch, main, hunk and conflict menus, file wrappers), `dz-config-git-pr.el` (finding the PR for a line, the one-key PR choice), `dz-config-git-pr-view.el` (the PR buffer). `dziman/git-menu` computes one context plist (`dziman/git-context`) per open, and each menu key's `:if` reads a flag from it, so opening the menu runs git a fixed number of times.

**Tech Stack:** Emacs 32 Lisp, built-in transient 0.13 and smerge-mode, MELPA magit, git-gutter, git-timemachine, git-link, markdown-mode (`gfm-mode`); CLIs `git`, `fj`, `gh` (optional); ERT.

**Spec:** `.dziman/docs/specs/2026-10-17-emacs-git-menu-design.md`

## Global Constraints

- Work in this checkout (`~/src/dziman/settings`), branch `feature/emacs-git-menu`. Paths are relative to the repo root. The live `~/.emacs` work tree is not touched.
- No new package. Transient is the built-in one; markdown-mode, git-link, git-timemachine and git-gutter are already installed.
- Startup stays at about 0.24 s (`emacs-init-time`): requiring transient alone costs ~67 ms, so neither transient nor magit may load at startup. Only `dz-config-git.el` is required from `.emacs`.
- Elisp files start with `;;; -*- lexical-binding: t -*-`, use the banner comments and closing-paren-on-own-line layout of `.emacs-dziman/configs/dz-config-git.el`, and end with a newline.
- Public names `dziman/git-…`, internal `dziman/git--…`; PR code `dziman/git-pr-…` / `dziman/git-pr--…`. Tests are named `dziman-git-<group>/<business-rule>`.
- Forge access only through CLIs, which own login: `gh` for `github.com`, `fj` for hosts in `fj auth list`. No tokens in Emacs. GitHub Enterprise and GitLab are out.
- Nothing writes to a forge, and nothing fetches into the repo behind the user's back.
- Default-branch comparisons use the merge base: `<default>...HEAD`.
- Commit subjects use the `[emacs]` / `[docs]` tags. Every commit ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. `git add` explicit paths only. No push.

**Test command** (from the repo root; `<file>` is the test file's feature name):

```bash
emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests \
  -l <file> -f ert-run-tests-batch-and-exit
```

Each test file runs in its own Emacs, so `dz-config-git-test` can check that the menu is not loaded at startup.

## Review Focus

- A merge conflict hit during a rebase: there git puts the commit being replayed (yours) in the lower part of the conflict, so "keep mine" must keep the lower part, not the upper one. Pinned in Task 3.
- Offline, or `fj` logged out, during a PR lookup: the failing step is skipped and the lookup ends at the commit fallback with a one-line note, never a Lisp error. Pinned in Task 4.
- PR lookup on a line below unsaved edits: blame runs on the buffer's text, so the line still maps to the right commit. Pinned in Task 4.
- A fresh `git init` with no commits yet: the menu opens, with no amend, no default-branch keys and no log keys that need a commit. Pinned in Task 1.
- Detached HEAD (a checked-out tag, or mid-rebase): no branch, so no default-branch keys, no pull and no push. Pinned in Task 1.

---

### Task 1: Context and default branch

**Files:**
- Create: `.emacs-dziman/configs/dz-config-git-menu.el`
- Create: `.emacs-dziman/tests/dz-git-test-fixtures.el`
- Test: `.emacs-dziman/tests/dz-config-git-menu-test.el`

**Interfaces:**
- Produces:
  - `(dziman/git-remote-host-and-path URL)` → `(HOST . "owner/repo")` or nil. Handles `ssh://user@host:port/owner/repo.git`, `user@host:owner/repo.git` and `https://host/owner/repo(.git)`; HOST has no user or port.
  - `(dziman/git-default-remote)` → remote name or nil: the current branch's push remote (`magit-get-push-remote`), else `upstream`, else `origin`, each only if it exists in `magit-list-remotes`.
  - `(dziman/git-default-branch)` → a revision string or nil: `git symbolic-ref --short refs/remotes/<remote>/HEAD` (e.g. `"origin/develop"`), else the first local branch of `develop`, `main`, `master` that exists.
  - `(dziman/git-context)` → plist, computed in the current buffer:
    `:repo` toplevel or nil · `:file` absolute file (the buffer's, or the dired file under the cursor; nil for a directory) · `:file-buffer` t when the buffer visits `:file` · `:tracked` · `:untracked` · `:unstaged` · `:staged` · `:conflicted` · `:region` (file buffer and active region) · `:branch` current branch or nil · `:remote` default remote · `:remote-host` · `:remote-path` · `:default-branch` · `:off-default` (`:branch` and `:default-branch` set and the branch is not the default's branch name) · `:upstream` · `:stash` · `:staged-any` · `:modified-any` · `:has-commits` · `:web-link` (a `git-link-remote-alist` regexp matches `:remote-host`) · `:commit-at-point` (sha from `magit-commit-at-point`, or a hex word at point of 7–40 chars that `magit-commit-p` accepts).
  - `dziman/git--context` — the plist the open menu reads; `(dziman/git--ctx KEY)` → `(plist-get dziman/git--context KEY)`.
  - Fixtures (in `dz-git-test-fixtures.el`): `dziman-git-test-with-repo`, `dziman-git-test-git`, `dziman-git-test-commit`.

- [ ] **Step 1: Create the branch and commit the spec and plan**

```bash
git switch -c feature/emacs-git-menu
git add .dziman/docs/specs/2026-10-17-emacs-git-menu-design.md .dziman/docs/plans/2026-10-17-emacs-git-menu.md
git commit -m "[docs] Emacs git menu: design and plan"
```

- [ ] **Step 2: Write the shared fixtures**

`.emacs-dziman/tests/dz-git-test-fixtures.el`, with the banner header of the other test files and `(provide 'dz-git-test-fixtures)`:

```elisp
(require 'cl-lib)
(require 'subr-x)

(defun dziman-git-test-git (&rest args)
  "Run git with ARGS in `default-directory'; return trimmed stdout. Errors on failure."
  (with-temp-buffer
    (let ((status (apply #'process-file "git" nil t nil args)))
      (unless (zerop status)
        (error "git %S failed: %s" args (buffer-string))
        )
      (string-trim (buffer-string))
      )
    )
  )

(defun dziman-git-test-commit (file content message)
  "Write CONTENT to FILE and commit it with MESSAGE. Return the commit id."
  (with-temp-file file (insert content))
  (dziman-git-test-git "add" file)
  (dziman-git-test-git "commit" "-q" "-m" message)
  (dziman-git-test-git "rev-parse" "HEAD")
  )

(defmacro dziman-git-test-with-repo (&rest body)
  "Run BODY in a new repo on branch main whose one commit adds a.txt.
The user's git config and hooks are ignored; buffers BODY opens are killed after."
  (let ((buffers (make-symbol "buffers")))
    `(let* ((process-environment
              (append '("GIT_CONFIG_GLOBAL=/dev/null" "GIT_CONFIG_NOSYSTEM=1") process-environment))
            (default-directory (file-name-as-directory (make-temp-file "dz-git-" t)))
            (,buffers (buffer-list)))
       (unwind-protect
           (progn
             (dziman-git-test-git "init" "-q" "-b" "main")
             (dziman-git-test-git "config" "user.name" "Test")
             (dziman-git-test-git "config" "user.email" "test@example.com")
             (dziman-git-test-commit "a.txt" "one\n" "Initial")
             ,@body
             )
         (dolist (buffer (buffer-list))
           (unless (memq buffer ,buffers)
             (with-current-buffer buffer (set-buffer-modified-p nil))
             (kill-buffer buffer)
             )
           )
         (delete-directory default-directory t)
         )
       )
    )
  )
```

A remote with a known default is faked without network: `git remote add origin ssh://git@git.example.org/me/repo.git`, `git update-ref refs/remotes/origin/develop HEAD`, `git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/develop`.

- [ ] **Step 3: Write the stub**

`.emacs-dziman/configs/dz-config-git-menu.el` requires `magit`, `git-link`, `dired`, defines every function in Produces returning nil (`dziman/git-context` returns `nil`), and ends with `(provide 'dz-config-git-menu)`.

- [ ] **Step 4: Write the failing tests**

`.emacs-dziman/tests/dz-config-git-menu-test.el` requires `ert`, `dz-git-test-fixtures`, `dz-config-git-menu`. Visit a file with `(find-file-noselect (expand-file-name "a.txt"))` and run `(with-current-buffer … (dziman/git-context))`. One test each:

| Test | Setup | Assertion |
|---|---|---|
| `dziman-git-remote/ssh-url-with-port` | `"ssh://git@git.example.org:2222/me/repo.git"` | `'("git.example.org" . "me/repo")` |
| `dziman-git-remote/scp-style-url` | `"git@github.com:me/repo.git"` | `'("github.com" . "me/repo")` |
| `dziman-git-remote/https-url` | `"https://github.com/me/repo"` | `'("github.com" . "me/repo")` |
| `dziman-git-remote/local-path-has-no-host` | `"/tmp/repo.git"` | nil |
| `dziman-git-default-branch/remote-default-wins-over-local-names` | fake origin with HEAD → develop; local `main` exists | `"origin/develop"` |
| `dziman-git-default-branch/push-remote-chosen-before-upstream-and-origin` | remotes `origin`, `upstream`, `fork`; `git config branch.main.pushRemote fork` | `(dziman/git-default-remote)` is `"fork"` |
| `dziman-git-default-branch/upstream-chosen-before-origin` | remotes `origin`, `upstream`, no push remote | `"upstream"` |
| `dziman-git-default-branch/no-remote-default-falls-back-to-develop` | no remote; local `develop` and `main` | `"develop"` |
| `dziman-git-default-branch/no-known-branch-gives-none` | rename `main` to `trunk` | nil |
| `dziman-git-context/outside-repo-has-no-repo` | `default-directory` a plain temp dir | `:repo` nil |
| `dziman-git-context/file-buffer-gives-its-file` | visit `a.txt` | `:file` is its path, `:file-buffer` t, `:tracked` t |
| `dziman-git-context/dired-gives-the-file-under-cursor` | `dired` on the repo, cursor on `a.txt` (`dired-goto-file`) | `:file` is its path, `:file-buffer` nil |
| `dziman-git-context/dired-on-a-directory-gives-no-file` | cursor on a subdirectory | `:file` nil |
| `dziman-git-context/new-file-is-untracked` | create `b.txt`, visit it | `:untracked` t, `:tracked` nil |
| `dziman-git-context/unchanged-file-has-nothing-to-stage` | visit `a.txt` | `:unstaged` nil, `:staged` nil |
| `dziman-git-context/edited-file-has-unstaged-changes` | change `a.txt` on disk | `:unstaged` t |
| `dziman-git-context/staged-file-has-staged-changes` | change and `git add` | `:staged` t, `:staged-any` t |
| `dziman-git-context/conflicted-file-is-flagged` | branch `other` and `main` both change line 1, `git merge other` (expect non-zero; call `process-file` directly) | `:conflicted` t |
| `dziman-git-context/stash-is-seen` | change, `git stash` | `:stash` t |
| `dziman-git-context/feature-branch-is-off-default` | `git switch -c feature` | `:off-default` t |
| `dziman-git-context/default-branch-is-not-off-default` | on `main` | `:off-default` nil |
| `dziman-git-context/detached-head-has-no-branch` | `git switch --detach` | `:branch` nil, `:off-default` nil |
| `dziman-git-context/empty-repo-has-no-commits` | fresh `git init` in a new temp dir, no commit | `:repo` set, `:has-commits` nil, `:default-branch` nil |
| `dziman-git-context/known-forge-host-allows-web-links` | origin `git@github.com:me/repo.git` | `:web-link` t |
| `dziman-git-context/unknown-host-has-no-web-links` | origin `ssh://git@git.example.org/me/repo.git` | `:web-link` nil |

- [ ] **Step 5: Run the tests to verify they fail**

Run the test command with `dz-config-git-menu-test`.
Expected: the assertions fail (e.g. `(should (equal (dziman/git-remote-host-and-path …) '("github.com" . "me/repo")))` with value nil); `dziman-git-remote/local-path-has-no-host`, `…/no-known-branch-gives-none` and `…/outside-repo-has-no-repo` may pass on the stub. Quote one failure message.

- [ ] **Step 6: Implement the functions in Produces**

Use magit's cheap readers (`magit-toplevel`, `magit-file-tracked-p`, `magit-anything-staged-p`/`-unstaged-p` with the file, `magit-unmerged-files`, `magit-get-current-branch`, `magit-get-upstream-branch`, `magit-rev-verify "refs/stash"`, `magit-rev-verify "HEAD"`, `magit-git-string`). Relative paths come from `magit-file-relative-name`. Every git query runs with `default-directory` set to `:repo`.

- [ ] **Step 7: Run the tests to verify they pass**

Expected: `Ran 25 tests, 25 results as expected`.

- [ ] **Step 8: Commit**

```bash
git add .emacs-dziman/configs/dz-config-git-menu.el .emacs-dziman/tests/dz-git-test-fixtures.el .emacs-dziman/tests/dz-config-git-menu-test.el
git commit -m "[emacs] Git menu: buffer context and default branch"
```

---

### Task 2: Main menu and hunk menu on `C-. g`

**Files:**
- Modify: `.emacs-dziman/configs/dz-config-git.el:31-63` (the hydra block)
- Modify: `.emacs-dziman/configs/dz-config-git-menu.el`
- Create: `.emacs-dziman/tests/dz-config-git-test.el`
- Test: `.emacs-dziman/tests/dz-config-git-menu-test.el`

**Interfaces:**
- Consumes: `dziman/git-context`, `dziman/git--context`, `dziman/git--ctx`, `dziman/git-default-branch`, `dziman/git-default-remote` (Task 1).
- Produces:
  - `dziman/git-menu` — interactive; binds `dziman/git--context` to `(dziman/git-context)` and opens `dziman/git--menu`. Autoloaded from `dz-config-git.el`, bound to `g` in `dziman/bind-map/hydra`.
  - `dziman/git--menu` — transient prefix; `dziman/git-hunks-menu` — transient prefix.
  - One predicate per context flag, no arguments, for `:if`: `dziman/git--repo-p`, `--tracked-p`, `--untracked-p`, `--unstaged-p`, `--staged-p`, `--modified-p` (unstaged or staged), `--conflicted-p`, `--file-buffer-tracked-p`, `--file-buffer-modified-p`, `--region-p`, `--off-default-p`, `--tracked-off-default-p`, `--branch-p`, `--branch-remote-p`, `--upstream-p`, `--stash-p`, `--staged-any-p`, `--modified-any-p`, `--has-commits-p`, `--remote-p`, `--web-link-p`, `--commit-at-point-p`.
  - File wrappers taking the file from `(dziman/git--ctx :file)`: `dziman/git-file-log`, `-blame`, `-diff-last-commit`, `-diff-default`, `-stage`, `-unstage`, `-add`, `-discard`, `-open-from-branch`, `-rename`, `-delete`.
  - Repo wrappers: `dziman/git-log-not-on-default`, `dziman/git-diff-branch-default`, `dziman/git-rebase-onto-default`, `dziman/git-refresh-default-branch`.
  - Keys `#` (PR) and `!` (conflicts) are added by Tasks 3 and 5.

Menu layout, keys matching `magit-file-dispatch` and `magit-dispatch` where the action is the same:

| Group | Key | Label | Command | `:if` |
|---|---|---|---|---|
| — | — | `Not a git repo` (`:info`) | — | `:if-not dziman/git--repo-p` |
| File | `l` | history | `dziman/git-file-log` | `--tracked-p` |
| File | `L` | history of selected lines | `magit-log-buffer-file` | `--region-p` |
| File | `b` | blame | `dziman/git-file-blame` | `--tracked-p` |
| File | `d` | diff with last commit | `dziman/git-file-diff-last-commit` | `--modified-p` |
| File | `D` | diff with default branch | `dziman/git-file-diff-default` | `--off-default-p` and tracked (one predicate `--tracked-off-default-p`) |
| File | `s` | stage | `dziman/git-file-stage` | `--unstaged-p` |
| File | `u` | unstage | `dziman/git-file-unstage` | `--staged-p` |
| File | `a` | add to git | `dziman/git-file-add` | `--untracked-p` |
| File | `k` | discard changes | `dziman/git-file-discard` | `--modified-p` |
| File | `o` | open from branch | `dziman/git-file-open-from-branch` | `--tracked-p` |
| File | `R` | rename | `dziman/git-file-rename` | `--tracked-p` |
| File | `K` | delete | `dziman/git-file-delete` | `--tracked-p` |
| File | `t` | step through history | `git-timemachine` | `--file-buffer-tracked-p` |
| File | `h` | changed hunks… | `dziman/git-hunks-menu` | `--file-buffer-modified-p` |
| Web link | `w f` | file and lines | `git-link` | `--web-link-p` |
| Web link | `w c` | commit at point | `git-link-commit` | `--commit-at-point-p` (implies web link) |
| Web link | `w h` | repo home page | `git-link-homepage` | `--web-link-p` |
| Repository | `g` | status | `magit-status` | `--repo-p` |
| Repository | `c` | commit | `magit-commit-create` | `--staged-any-p` |
| Repository | `C` | amend last commit | `magit-commit-amend` | `--has-commits-p` |
| Repository | `B` | switch branch | `magit-branch-checkout` | `--has-commits-p` |
| Repository | `N` | new branch | `magit-branch-and-checkout` | `--has-commits-p` |
| Repository | `f` | fetch | `magit-fetch-all` | `--remote-p` |
| Repository | `F` | pull | `magit-pull-from-upstream` | `--upstream-p` |
| Repository | `P` | push | `magit-push-current-to-pushremote` | `--branch-p` and remote (`--branch-remote-p`) |
| Repository | `z` | stash | `magit-stash-both` | `--modified-any-p` |
| Repository | `Z` | pop stash | `magit-stash-pop` | `--stash-p` |
| Repository | `r l` | branch log | `magit-log-current` | `--has-commits-p` |
| Repository | `r m` | commits not on default branch | `dziman/git-log-not-on-default` | `--off-default-p` |
| Repository | `r d` | branch diff with default branch | `dziman/git-diff-branch-default` | `--off-default-p` |
| Repository | `r r` | rebase onto default branch | `dziman/git-rebase-onto-default` | `--off-default-p` |
| Repository | `r h` | refresh default branch | `dziman/git-refresh-default-branch` | `--remote-p` |

Hunk menu `dziman/git-hunks-menu` keeps today's letters. Every key has `:transient t`, and `q` (`transient-quit-one`) closes the menu: `n` `git-gutter:next-hunk`, `p` `git-gutter:previous-hunk`, `e` `git-gutter:end-of-hunk`, `d` `git-gutter:popup-hunk`, `s` `git-gutter:stage-hunk`, `r` `git-gutter:revert-hunk`, `R` `git-gutter:update-all-windows`, `S` `git-gutter:set-start-revision`.

Wrapper behaviour, where the signature leaves a choice:
- `-log`: in a file buffer `magit-log-buffer-file` with follow; in dired `(magit-log-other '("HEAD") '("--follow") (list rel))`.
- `-blame`, `-rename`, `-delete`, `-open-from-branch`: in dired, act on the file under the cursor. Blame first visits the file (`find-file`), then calls `magit-blame-addition`. `-open-from-branch` calls `(magit-find-file (magit-read-branch-or-commit "Open from branch") rel)`.
- `-diff-last-commit`: `(magit-diff-working-tree "HEAD" nil (list rel))`. `-diff-default`: `(magit-diff-range (concat default "...HEAD") nil (list rel))`.
- `-stage` and `-add`: `(magit-stage-files (list rel))`. `-unstage`: `(magit-unstage-files (list rel))`.
- `-discard`: asks `(yes-or-no-p (format "Discard all local changes to %s? " rel))`; on yes, `(magit-file-checkout "HEAD" rel)`.
- `dziman/git-log-not-on-default`: `(magit-log-other (list (concat default "..HEAD")))`. `-diff-branch-default`: `(magit-diff-range (concat default "...HEAD"))`. `-rebase-onto-default`: `(magit-rebase-branch default nil)`. `-refresh-default-branch`: `(magit-run-git "remote" "set-head" remote "--auto")`, then a message naming the new default.

- [ ] **Step 1: Write the failing tests**

In `dz-config-git-menu-test.el`, add the test macro `dziman-git-test-key` with arguments `(name prefix key predicate)`. It defines `dziman-git-menu-keys/NAME`, which asserts `(eq (plist-get (cdr (transient-get-suffix PREFIX KEY)) :if) PREDICATE)`. Use one macro call per table row above. Name each case by the rule, e.g. `(dziman-git-test-key stage-needs-unstaged-changes dziman/git--menu "s" dziman/git--unstaged-p)` and `(dziman-git-test-key pull-needs-an-upstream dziman/git--menu "F" dziman/git--upstream-p)`.

Then one test each:
- `dziman-git-menu-keys/not-a-repo-note-shows-only-outside-repos`: the `:info` suffix has `:if-not dziman/git--repo-p`. Find it with `transient-get-suffix` on its location `'(0 0)`, or by scanning `(get 'dziman/git--menu 'transient--layout)`.
- `dziman-git-menu-hunks/every-hunk-key-keeps-the-menu-open`: for `n p e d s r R S`, `:transient` is t.
- `dziman-git-menu-hunks/hunk-keys-keep-todays-letters`: `n`→`git-gutter:next-hunk`, `s`→`git-gutter:stage-hunk`, `r`→`git-gutter:revert-hunk`.
- `dziman-git-menu/stage-in-dired-stages-file-under-cursor`: change `a.txt`, open dired with the cursor on it, bind `dziman/git--context` from `dziman/git-context`, call `dziman/git-file-stage`; `git diff --cached --name-only` is `"a.txt"`.
- `dziman-git-menu/discard-asks-first`: change `a.txt`, stub `yes-or-no-p` → nil, call `dziman/git-file-discard`; the file still holds the change.
- `dziman-git-menu/discard-restores-last-commit`: stub → t; the file reads `"one\n"`.
- `dziman-git-menu/file-diff-with-default-starts-where-branch-left`: fake origin HEAD → develop, on branch `feature`, stub `magit-diff-range` to record its arguments; recorded `("origin/develop...HEAD" nil ("a.txt"))`.
- `dziman-git-menu/rebase-targets-default-branch`: stub `magit-rebase-branch`; recorded target `"origin/develop"`.
- `dziman-git-menu/refresh-default-asks-remote-for-its-head`: stub `magit-run-git`; recorded `("remote" "set-head" "origin" "--auto")`.

New file `dz-config-git-test.el`, which requires only `dz-config-bind-maps` and `dz-config-git`:
- `dziman-git-startup/menu-opens-from-C-dot-g`: `(lookup-key dziman/bind-map/hydra "g")` is `dziman/git-menu`.
- `dziman-git-startup/menu-code-loads-on-first-use`: `(autoloadp (symbol-function 'dziman/git-menu))` and `(not (featurep 'dz-config-git-menu))`.
- `dziman-git-startup/old-hydra-is-gone`: `(not (fboundp 'dziman/hydra/git/body))`.

- [ ] **Step 2: Add stubs**

`dziman/git--menu` and `dziman/git-hunks-menu` with one group holding only `("g" "status" magit-status)`; the predicates and wrappers as no-op definitions. In `dz-config-git.el`, nothing changes yet.

- [ ] **Step 3: Run both test files to verify they fail**

Expected: e.g. `transient-get-suffix` errors with `Cannot find "s"`. A missing key is a lookup failure, not an assertion. So the macro wraps the lookup in `(ignore-errors …)` and asserts on the result, and the failure reads `(should (eq nil 'dziman/git--unstaged-p))`. `dziman-git-startup/menu-opens-from-C-dot-g` fails with value `dziman/hydra/git/body`. Quote one of each.

- [ ] **Step 4: Implement the layout, predicates and wrappers in `dz-config-git-menu.el`**

`dziman/git-menu` is the interactive entry: `(setq dziman/git--context (dziman/git-context))`, then `(transient-setup 'dziman/git--menu)`. It is a `setq`, not a `let`, because `transient-setup` returns before the user picks a key and suffixes run later.

- [ ] **Step 5: Rewire `dz-config-git.el`**

Delete `dziman/hydra/git--title`, the `pretty-hydra-define dziman/hydra/git` form and its `bind-key`/`put` lines. Add:

```elisp
(autoload 'dziman/git-menu "dz-config-git-menu" "File, repository and pull request actions that apply here." t)
(bind-key "g" #'dziman/git-menu dziman/bind-map/hydra)
```

Keep `(which-key-add-key-based-replacements "C-. g" "git menu")`. which-key shows the autoload docstring.

- [ ] **Step 6: Run both test files to verify they pass**

Expected: `dz-config-git-test` 3/3; `dz-config-git-menu-test` all results as expected.

- [ ] **Step 7: Run the hydra and other test files**

Run the test command for `dz-config-hydra-test`, `dz-config-emacs-generic-test`, `dz-config-prog-mode-test`. Expected: all pass.

- [ ] **Step 8: Commit**

```bash
git add .emacs-dziman/configs/dz-config-git.el .emacs-dziman/configs/dz-config-git-menu.el .emacs-dziman/tests/dz-config-git-test.el .emacs-dziman/tests/dz-config-git-menu-test.el
git commit -m "[emacs] Git menu on C-. g: only the actions that apply here"
```

---

### Task 3: Merge-conflict menu

**Files:**
- Modify: `.emacs-dziman/configs/dz-config-git-menu.el`
- Test: `.emacs-dziman/tests/dz-config-git-menu-test.el`

**Interfaces:**
- Consumes: `dziman/git--conflicted-p` (Task 2), `dziman-git-test-with-repo` (Task 1).
- Produces:
  - `(dziman/git-conflict-sides)` → `(MINE . THEIRS)`, each `smerge-keep-upper` or `smerge-keep-lower`. During a rebase (`magit-rebase-in-progress-p`) it is `(smerge-keep-lower . smerge-keep-upper)`; otherwise the reverse.
  - Commands `dziman/git-conflict-keep-mine`, `dziman/git-conflict-keep-theirs`. Each calls its side from `dziman/git-conflict-sides`.
  - `dziman/git-conflicts` — interactive; turns on `smerge-mode` and opens `dziman/git-conflict-menu`.
  - Transient `dziman/git-conflict-menu`. Every key has `:transient t`, and `q` closes the menu: `n` `smerge-next`, `p` `smerge-prev`, `m` keep mine, `t` keep theirs, `a` `smerge-keep-all` (keep both).
  - Main-menu key `!` "merge conflicts…" → `dziman/git-conflicts`, `:if dziman/git--conflicted-p`, at the end of the File group.

- [ ] **Step 1: Write the failing tests**

Fixture: on `main` set line 1 of `a.txt` to `"mine\n"`, on branch `other` to `"theirs\n"`.
- `dziman-git-conflict/merge-keep-mine-keeps-current-branch`: from `main`, run `git merge other` (non-zero exit expected), visit `a.txt`, `smerge-mode`, `smerge-next`, `dziman/git-conflict-keep-mine`; the buffer reads `"mine\n"`.
- `dziman-git-conflict/merge-keep-theirs-keeps-merged-branch`: same; `dziman/git-conflict-keep-theirs` → `"theirs\n"`.
- `dziman-git-conflict/rebase-keep-mine-keeps-the-replayed-commit`: from `other`, run `git rebase main` (conflicts), then `dziman/git-conflict-keep-mine` → `"theirs\n"`, which is the `other` branch's own text.
- `dziman-git-menu-keys/conflict-key-needs-a-conflicted-file`: via `dziman-git-test-key` (`"!"` → `dziman/git--conflicted-p`).
- `dziman-git-conflict/every-conflict-key-keeps-the-menu-open`: `n p m t a` have `:transient` t.

- [ ] **Step 2: Add stubs**

`dziman/git-conflict-sides` returns `(smerge-keep-upper . smerge-keep-lower)` unconditionally; the menu with only `n`.

- [ ] **Step 3: Run to verify they fail**

Expected: the rebase test fails with `(should (equal "mine\n" "theirs\n"))`-shaped output; the key tests fail with nil. Quote one.

- [ ] **Step 4: Implement the functions in Produces**

- [ ] **Step 5: Run to verify they pass**

Expected: all results as expected.

- [ ] **Step 6: Commit**

```bash
git add .emacs-dziman/configs/dz-config-git-menu.el .emacs-dziman/tests/dz-config-git-menu-test.el
git commit -m "[emacs] Git menu: merge-conflict menu, mine and theirs right during rebase"
```

---

### Task 4: Finding the pull request for a commit

**Files:**
- Create: `.emacs-dziman/configs/dz-config-git-pr.el`
- Test: `.emacs-dziman/tests/dz-config-git-pr-test.el`

**Interfaces:**
- Consumes: `dziman/git-remote-host-and-path`, `dziman/git-default-remote` (Task 1); fixtures (Task 1).
- Produces:
  - `(dziman/git-pr--run PROGRAM &rest ARGS)` → stdout string. On a non-zero exit it signals `user-error` with `"<program> failed: <first stderr line>"`. All `gh`, `fj` and `git ls-remote` calls go through it, which is what tests stub; local git goes through magit.
  - `(dziman/git-pr-host-tool HOST)` → `gh` (HOST is `"github.com"` and `(executable-find "gh")`), `fj` (`(executable-find "fj")` and HOST is in `(dziman/git-pr--fj-hosts)`), or nil.
  - `(dziman/git-pr--fj-hosts)` → list of host strings from `fj auth list`, one per line, cached in `dziman/git-pr--fj-hosts-cache` for the session.
  - `(dziman/git-pr-number-in-subject SUBJECT)` → integer or nil. It matches `(#N)` anywhere, or `Merge pull request #N`.
  - `(dziman/git-pr--merge-commit SHA)` → the merge commit that brought SHA into HEAD, or nil.
  - `(dziman/git-pr--github-number REPO-PATH SHA)` → integer or nil, via `gh api repos/REPO-PATH/commits/SHA/pulls --jq '.[0].number'`.
  - `(dziman/git-pr--pull-heads REMOTE)` → alist `(NUMBER . SHA)` from `git ls-remote REMOTE 'refs/pull/*/head'`.
  - `(dziman/git-pr--number-containing SHA HEADS)` → integer or nil.
  - `(dziman/git-pr-find SHA REMOTE)` → integer or nil. It runs the spec's steps in order: subject of SHA, subject of `--merge-commit`, `--github-number` when the host tool is `gh`, then `--pull-heads` + `--number-containing`. A `user-error` from a network step is caught and noted with `message`, and the next step runs.
  - `(dziman/git-pr-url HOST REPO-PATH NUMBER)` → `https://github.com/REPO-PATH/pull/N` for `github.com`, else `https://HOST/REPO-PATH/pulls/N`.
  - `(dziman/git-pr--line-commit)` → sha of the current line's commit, or nil when the line is not committed (blame sha all zeros).

Algorithms the signatures leave open:
- `--merge-commit`: the first commit present in both `git rev-list --ancestry-path --merges --reverse SHA..HEAD` and `git rev-list --first-parent --merges --reverse SHA..HEAD`.
- `--number-containing`: keep the heads whose sha exists locally (`magit-commit-p`) and where SHA is an ancestor or equal (`git merge-base --is-ancestor SHA HEAD-SHA`). Pick the one with the smallest `git rev-list --count SHA..HEAD-SHA`; break ties with the lowest number.
- `--line-commit`: `git blame --porcelain -L N,N --contents - -- FILE`, with the buffer's text on stdin (`call-process-region`), N = `(line-number-at-pos)`. The first word of the output is the sha.

- [ ] **Step 1: Write the failing tests**

`dz-config-git-pr-test.el` requires `ert`, `dz-git-test-fixtures`, `dz-config-git-pr`. Stub the CLIs with `(cl-letf (((symbol-function 'dziman/git-pr--run) (lambda (program &rest args) …))) …)`. For "no network" tests the stub calls `(ert-fail "network used")`.

| Test | Setup | Assertion |
|---|---|---|
| `dziman-git-pr-subject/squash-subject-names-pr` | `"Fix login (#42)"` | 42 |
| `dziman-git-pr-subject/github-merge-subject` | `"Merge pull request #42 from me/fix"` | 42 |
| `dziman-git-pr-subject/forgejo-merge-subject` | `"Merge pull request 'Fix login' (#42) from fix into main"` | 42 |
| `dziman-git-pr-subject/plain-subject-names-none` | `"Fix login"` | nil |
| `dziman-git-pr-host/github-needs-gh-installed` | stub `executable-find` → nil for `"gh"` | `(dziman/git-pr-host-tool "github.com")` nil |
| `dziman-git-pr-host/forgejo-host-is-one-fj-is-logged-into` | `--run` returns `"git.example.org\n"` for `fj auth list`, cache cleared | `fj` |
| `dziman-git-pr-host/unknown-host-has-no-tool` | same stub | `(dziman/git-pr-host-tool "gitlab.com")` nil |
| `dziman-git-pr-find/squash-commit-found-without-network` | commit `"Fix (#5)"`; stub fails on any call | 5 |
| `dziman-git-pr-find/merge-commit-found-without-network` | branch `feature` commit C; `main`: `git merge --no-ff -m "Merge pull request #7 from me/feature" feature`; stub fails | `(dziman/git-pr-find C "origin")` 7 |
| `dziman-git-pr-find/github-asks-gh` | origin `git@github.com:me/repo.git`, `executable-find` stubbed to find `gh`; `--run` returns `"9\n"` for `gh api …` | 9 |
| `dziman-git-pr-find/fast-forward-pr-found-from-pull-heads` | commits C1, C2 on `main`; origin `ssh://git@git.example.org/me/repo.git`; `ls-remote` returns `C1\trefs/pull/3/head\nC2\trefs/pull/4/head\n` | C1 → 3 |
| `dziman-git-pr-find/later-pr-does-not-claim-earlier-commit` | same | C2 → 4 |
| `dziman-git-pr-find/pull-head-not-fetched-is-skipped` | `ls-remote` returns only an unknown sha `"0123…ef"` (40 hex) | nil |
| `dziman-git-pr-find/offline-falls-back-to-no-pr` | `--run` signals `(user-error "git failed: Could not resolve host")` | nil, no error |
| `dziman-git-pr-url/github-link` | `"github.com" "me/repo" 42` | `"https://github.com/me/repo/pull/42"` |
| `dziman-git-pr-url/forgejo-link` | `"git.example.org" "me/repo" 42` | `"https://git.example.org/me/repo/pulls/42"` |
| `dziman-git-pr-line/committed-line-gives-its-commit` | commit `b.txt` `"x\ny\n"`, visit, line 2 | that commit's sha |
| `dziman-git-pr-line/new-line-has-no-commit` | insert `"z\n"` at the top, unsaved, stay on line 1 | nil |
| `dziman-git-pr-line/unsaved-edits-above-keep-the-right-commit` | insert two lines at the top unsaved, go to the line holding `"y"` | the `b.txt` commit's sha |

- [ ] **Step 2: Write the stub**

`dz-config-git-pr.el` requires `dz-config-git-menu`, defines every Produces function returning nil, and provides `dz-config-git-pr`.

- [ ] **Step 3: Run to verify they fail**

Expected: e.g. `(should (eql (dziman/git-pr-number-in-subject "Fix login (#42)") 42))` with value nil. The tests that expect nil may pass on the stub. Quote one failure.

- [ ] **Step 4: Implement the functions in Produces**

- [ ] **Step 5: Run to verify they pass**

Expected: `Ran 19 tests, 19 results as expected`.

- [ ] **Step 6: Commit**

```bash
git add .emacs-dziman/configs/dz-config-git-pr.el .emacs-dziman/tests/dz-config-git-pr-test.el
git commit -m "[emacs] Git menu: find the pull request behind a commit"
```

---

### Task 5: PR key and the one-key choice

**Files:**
- Modify: `.emacs-dziman/configs/dz-config-git-pr.el`
- Modify: `.emacs-dziman/configs/dz-config-git-menu.el`
- Test: `.emacs-dziman/tests/dz-config-git-pr-test.el`

**Interfaces:**
- Consumes: `dziman/git-pr-find`, `dziman/git-pr--line-commit`, `dziman/git-pr-url`, `dziman/git-pr-host-tool` (Task 4); `dziman/git--ctx` (Task 1).
- Produces:
  - `(dziman/git-pr-available-p)` → non-nil when `(dziman/git--ctx :file-buffer)`, `:tracked`, and `(dziman/git-pr-host-tool (dziman/git--ctx :remote-host))`.
  - `dziman/git-pr-at-line` — interactive. A nil line commit raises `user-error "This line is not committed yet"`. Otherwise it messages `"Looking for the pull request…"` and runs `dziman/git-pr-find`. If a PR is found, it opens `dziman/git-pr-choice` with scope plist `(:tool :root :host :repo-path :remote :number :url)` (`:root` is the repo toplevel; CLI calls run there) via `(transient-setup 'dziman/git-pr-choice nil nil :scope SCOPE)`. If none is found, it asks `(y-or-n-p (format "No pull request found for %s. Show the commit? " short-sha))` and on yes calls `(magit-show-commit sha)`.
  - Transient `dziman/git-pr-choice` (reads `(transient-scope)`): `l` `dziman/git-pr-copy-link` (does `kill-new` and messages the URL), `b` `dziman/git-pr-browse` (`browse-url`), `e` `dziman/git-pr-show` (calls `dziman/git-pr-view` from Task 6; until Task 6 lands, it messages the URL).
  - Main-menu key `#` "pull request for this line" → `dziman/git-pr-at-line`, `:if dziman/git-pr-available-p`. In `dz-config-git-menu.el` add `(autoload 'dziman/git-pr-at-line "dz-config-git-pr" nil t)` and `(autoload 'dziman/git-pr-available-p "dz-config-git-pr")`, since `dz-config-git-pr` requires the menu file.

- [ ] **Step 1: Write the failing tests**

- `dziman-git-pr-at-line/found-pr-opens-the-choice`: stub `dziman/git-pr--line-commit` → `"abc"`, `dziman/git-pr-find` → 3, and `transient-setup` recording its `:scope`. Context from a repo with origin `ssh://git@git.example.org/me/repo.git`. The recorded scope's `:url` is `"https://git.example.org/me/repo/pulls/3"`.
- `dziman-git-pr-at-line/no-pr-offers-the-commit`: `--find` → nil, `y-or-n-p` → t, `magit-show-commit` recording; recorded `"abc"`.
- `dziman-git-pr-at-line/uncommitted-line-says-so`: `--line-commit` → nil; `(should-error (dziman/git-pr-at-line) :type 'user-error)`.
- `dziman-git-pr-choice/link-is-copied`: call `dziman/git-pr-copy-link` with `transient-scope` stubbed to the scope; `(current-kill 0)` is the URL.
- `dziman-git-pr-choice/browser-gets-the-link`: stub `browse-url` recording; recorded the URL.
- `dziman-git-menu-keys/pr-key-needs-a-pr-tool`: `dziman-git-test-key` for `"#"` → `dziman/git-pr-available-p`, in `dz-config-git-menu-test.el`.
- `dziman-git-pr-available/directory-listing-has-no-pr-key`: context with `:file-buffer` nil, host tool stubbed to `fj`; nil.

- [ ] **Step 2: Add stubs**

The command and suffixes as no-ops; `dziman/git-pr-available-p` → nil.

- [ ] **Step 3: Run to verify they fail**

Expected: e.g. `(should (equal nil "https://git.example.org/me/repo/pulls/3"))`. Quote one.

- [ ] **Step 4: Implement the functions in Produces**

- [ ] **Step 5: Run `dz-config-git-pr-test` and `dz-config-git-menu-test` to verify they pass**

Expected: all results as expected in both.

- [ ] **Step 6: Commit**

```bash
git add .emacs-dziman/configs/dz-config-git-pr.el .emacs-dziman/configs/dz-config-git-menu.el .emacs-dziman/tests/dz-config-git-pr-test.el .emacs-dziman/tests/dz-config-git-menu-test.el
git commit -m "[emacs] Git menu: pull request for this line, as link, browser or buffer"
```

---

### Task 6: Pull request view in Emacs

**Files:**
- Create: `.emacs-dziman/configs/dz-config-git-pr-view.el`
- Modify: `.emacs-dziman/configs/dz-config-git-pr.el` (`dziman/git-pr-show`)
- Test: `.emacs-dziman/tests/dz-config-git-pr-view-test.el`

**Interfaces:**
- Consumes: `dziman/git-pr--run` (Task 4); the scope plist (Task 5).
- Produces:
  - `(dziman/git-pr-fetch SCOPE)` → plist `(:number :title :author :state :base :head :url :body :commits ((SHA . SUBJECT) …) :files ((PATH ADDED DELETED) …))`, `:state` one of `"open"`, `"merged"`, `"closed"`.
    - `fj` (run in the repo root): `fj pr -R REMOTE view N --json` gives `title`, `user.login`, `state` plus `merged` (true means `"merged"`), `base.ref`, `head.label`, `html_url`, `body`. Commits come from `fj pr -R REMOTE view N commits`, files from `fj pr -R REMOTE view N files`.
    - `gh`: `gh pr view N -R REPO-PATH --json number,title,author,state,baseRefName,headRefName,url,body,commits,files`. Commits come from `commits[].oid` / `messageHeadline`, files from `files[].path` / `additions` / `deletions`. Lowercase `state`.
  - `(dziman/git-pr--parse-fj-commits TEXT)` → `((SHA . SUBJECT) …)`. Each block starts `commit <sha> (+a, -d)`, and the subject is the first 4-space-indented line after it.
  - `(dziman/git-pr--parse-fj-files TEXT)` → `((PATH ADDED DELETED) …)`, from lines `+N -M path` (whitespace-separated).
  - `(dziman/git-pr-diff SCOPE)` → unified diff string (`fj pr -R REMOTE view N diff` / `gh pr diff N -R REPO-PATH`). `(dziman/git-pr--file-diff DIFF PATH)` → that file's section, from its `diff --git a/PATH ` line to the next `diff --git` line.
  - `(dziman/git-pr-conversation SCOPE)` → string (`fj pr -R REMOTE view N comments` / `gh pr view N -R REPO-PATH --comments`). An empty result shows as `"No comments."`.
  - `(dziman/git-pr--render-markdown TEXT)` → propertized string. Insert TEXT into a temp buffer in `gfm-mode`, run `font-lock-ensure`, copy each `face` to `font-lock-face`, and return the buffer string.
  - `dziman/git-pr-view-mode` (derived from `special-mode`), buffer `*PR REPO-PATH#N*`, and `(dziman/git-pr-view SCOPE)`, which fills it and shows it. Buffer-local `dziman/git-pr--scope`; the diff is fetched on first file `RET` and cached buffer-locally.
  - Layout, top to bottom: title, then `author · state · head → base`, then the URL, the description, a `Commits` heading with one line `SHORT-SHA SUBJECT` each, a `Files` heading with lines `+A -D PATH`, and a closing hint `c: load conversation`.
  - Keys: `RET` on a commit → `magit-show-commit` when `(magit-commit-p sha)`, else `message "Commit %s is not fetched"`; `RET` on a file → buffer `*PR REPO-PATH#N: PATH*` in `diff-mode` with that file's section; `c` appends the conversation once; `b` browse; `l` copy link; `g` refetch and redraw; `q` `quit-window`.

- [ ] **Step 1: Write the failing tests**

Fixtures in the test file: a short fj JSON string (number 1, title `"Add profiles"`, `user.login` `"me"`, `state` `"closed"`, `merged` true, `base.ref` `"main"`, `head.label` `"profile/mechanism"`, `html_url`, `body` `"## What\nOne link."`); fj commits text with two blocks; fj files text with two lines; a gh JSON string with the same PR; a two-file diff. Stub `dziman/git-pr--run` to return them by argument.

- `dziman-git-pr-view-parse/fj-merged-pr-reads-as-merged`: `:state` `"merged"`, `:head` `"profile/mechanism"`, `:author` `"me"`.
- `dziman-git-pr-view-parse/fj-commits-give-sha-and-subject`: first element `("cddf088d…" . "[profile] Add machine profile mechanism")`.
- `dziman-git-pr-view-parse/fj-files-give-counts`: `(".emacs" 1 0)` present.
- `dziman-git-pr-view-parse/gh-pr-reads-the-same`: same `:title`, `:state` `"merged"`, `:files`.
- `dziman-git-pr-view-parse/file-diff-is-cut-from-the-pr-diff`: section of the second file starts with its `diff --git` line and does not contain the first file's path.
- `dziman-git-pr-view/buffer-shows-title-state-branches-commits-files`: after `dziman/git-pr-view`, the buffer text contains `"Add profiles"`, `"merged"`, `"profile/mechanism → main"`, `"Commits"`, `".emacs"`.
- `dziman-git-pr-view/conversation-waits-for-its-key`: a counter in the stub; it stays 0 for `comments` after the view opens, and is 1 after `c`.
- `dziman-git-pr-view/unfetched-commit-is-reported-not-fetched`: `RET` on a commit line with `magit-commit-p` → nil and `magit-show-commit` stubbed to fail. `(current-message)` matches `"not fetched"`.
- `dziman-git-pr-view/file-opens-its-diff`: `RET` on the `.emacs` line; a buffer in `diff-mode` holding `".emacs"`.

- [ ] **Step 2: Write the stub**

Every Produces function returns nil or does nothing; the mode is defined.

- [ ] **Step 3: Run to verify they fail**

Expected: `(should (equal nil "merged"))`-shaped failures. Quote one.

- [ ] **Step 4: Implement the functions in Produces; point `dziman/git-pr-show` at `dziman/git-pr-view`**

`dz-config-git-pr.el` adds `(autoload 'dziman/git-pr-view "dz-config-git-pr-view")`.

- [ ] **Step 5: Run `dz-config-git-pr-view-test` and `dz-config-git-pr-test` to verify they pass**

Expected: all results as expected.

- [ ] **Step 6: Commit**

```bash
git add .emacs-dziman/configs/dz-config-git-pr-view.el .emacs-dziman/configs/dz-config-git-pr.el .emacs-dziman/tests/dz-config-git-pr-view-test.el
git commit -m "[emacs] Git menu: read-only pull request view"
```

---

### Task 7: Cheat sheet and live check

**Files:**
- Modify: `.dziman/docs/emacs-prog-cheatsheet.org` (line 12 `C-.` row, the `* Git` section lines 195–212)

- [ ] **Step 1: Update the cheat sheet**

Line 12 stays `=g= git`. In `* Git`, replace the `C-. g` row's text with `git menu: only what applies here (below)`. Replace the "stays open until =q=" table with three tables in the existing style: File keys, Repository keys, Web link keys (from Task 2's layout). Add `=#=` "pull request for this line (=l= link, =b= browser, =e= in Emacs)" and `=!=` "merge conflicts". Add two short tables: "=h= hunks, stays open until =q=" (today's letters) and "=!= conflicts, stays open until =q=" (`n` `p` `m` `t` `a`).

- [ ] **Step 2: Run every test file**

```bash
for t in dz-config-git-test dz-config-git-menu-test dz-config-git-pr-test dz-config-git-pr-view-test dz-config-hydra-test dz-config-emacs-generic-test dz-config-prog-mode-test dz-config-fly-test dz-config-org-test dz-config-swift-test; do
  emacs --batch -f package-initialize -L .emacs-dziman/configs -L .emacs-dziman/tests -l $t -f ert-run-tests-batch-and-exit 2>&1 | tail -1
done
```

Expected: every line reads `Ran N tests, N results as expected`.

- [ ] **Step 3: Live check against the checkout**

From the repo root, start Emacs against the checkout:

```bash
DZIMAN_EMACS_SETTINGS_DIR=$PWD/.emacs-dziman emacs -q --eval '(package-activate-all)' -l $PWD/.emacs
```

Check each of these:
- `(emacs-init-time)` is about 0.24 s, and `(featurep 'transient)` is nil before the first `C-. g`.
- `C-. g` in `.emacs-dziman/configs/dz-config-git.el`: File, Web link and Repository groups show. There is no `s`/`u`/`k`/`d` while the file is clean, and no `r m`/`r d`/`r r` on `main`.
- On `.emacs` line 80 (`(require 'dz-config-profile)`, from PR 1's commit `cddf088`), `#` finds PR 1 through the remote's PR heads. `l` copies `https://git.nasha.casa/ai-mirrors/settings/pulls/1`, and `e` shows the PR buffer with title `[profile] Add machine profile mechanism`.
- In `*scratch*`: only the Repository group shows, or "Not a git repo" if the directory isn't one.

If line 80 no longer blames to `cddf088`, use any line `git blame` attributes to that commit.

- [ ] **Step 4: Commit**

```bash
git add .dziman/docs/emacs-prog-cheatsheet.org
git commit -m "[docs] Cheat sheet: git menu, pull request and conflict keys"
```
