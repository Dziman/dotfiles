# Profile Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** executed 2026-10-09/10; profile `work` was renamed `apple` and profile dirs mirror `$HOME` (decided during execution).

**Goal:** Build branch `unified` = `main-computer` + reviewed `mirror/ai-dev` commits + reviewed `work-computer` features, with per-machine differences expressed through the profile mechanism instead of branches.

**Architecture:** One untracked symlink `~/.dziman/profile → profiles/<name>` selects the machine profile; every tracked file refers to `~/.dziman/profile/…`. Shared files include a profile part where the app supports it (zsh, emacs, git, tmux), a git clean/smudge filter where it does not, and sparse-checkout hides directories that exist on one profile only. The branch is built in two stages: cherry-pick ai-dev commit by commit with per-commit user review, then port work-computer feature by feature in four area passes with per-feature user decisions.

**Tech Stack:** git (worktrees, cherry-pick, filters, sparse-checkout), zsh, Emacs Lisp, POSIX sh, tmux 3.8.

**Spec:** `.dziman/docs/specs/2026-10-09-profile-unification-design.md`

## Global Constraints

- Repo work-tree is `$HOME` on every machine (bare repo `~/.dziman-dotfiles`, alias `config`). Every path in this plan is relative to the work-tree root = `$HOME`.
- Branches `main-computer`, `work-computer`, `mirror/ai-dev`, `main` are never modified, rebased, or deleted. All work lands on the new branch `unified`.
- No `git push` without the user's explicit request for that push. No `git add -A` / `git add .` — add explicit paths only (the validation harness leaves untracked files in the worktree).
- Every decision point (per commit in stage 1, per feature in stage 2) is put to the user with `AskUserQuestion`; never decided silently. Batch ≤ 4 questions per call.
- Secrets are not touched: `888_ai.enabled.zsh` keeps its content; never print the OpenRouter key in chat (mask with `sed` when showing diffs of that file).
- Commit subjects use the repo's existing area tags (`[emacs]`, `[zsh]`, `[git]`, `[tmux]`, `[ai]`, `[profile]` for the mechanism). Cherry-picked commits keep the original subject; the body gets `Source: <hash>`. Every commit ends with a `Co-Authored-By:` trailer per the user's global rule.
- Files end with a newline (`.editorconfig` `insert_final_newline = true`).
- Shell scripts: POSIX `sh` for `config-profile` (runs before zsh config is loaded); existing zsh files stay zsh. Elisp files start with `;;; -*- lexical-binding: t -*-` and the banner-comment style of `dz-config-crux.el`.

## Review Focus

1. `~/.dziman/profile` missing (fresh machine before `config-profile` ran): zsh, emacs, git, tmux must start without errors or warnings — pinned by Task 2 step 8.
2. `config-profile <unknown>` must exit non-zero, print the available profiles, and leave an existing symlink untouched — pinned by Task 2 step 3.
3. A profile-only tracked symlink that dangles on other profiles (`.ssh/config` style, tier 3) must not break the app that reads it — pinned by Task 5 (ssh `-G` check) when such a file is introduced.
4. Sparse-checkout patterns are local state; `config-profile` must apply them idempotently and `config status` must stay clean afterwards — pinned by Task 5 step for sparse support.
5. Fake-`HOME` validation must not touch the live `$HOME` of this machine — pinned by Task 1's harness (`HOME` override on every command, worktree outside `$HOME`'s dotfiles).

---

## File structure (new or changed by the mechanism)

| path | responsibility |
|---|---|
| `.local/bin/config-profile` | select profile (symlink), apply sparse patterns and filters for it |
| `.dziman/profiles/{main,apple,ai}/README.md` | one-line description of the profile; keeps the directory tracked |
| `.dziman/profiles/<p>/.gitconfig` | git profile part, included from `.gitconfig` |
| `.dziman/profiles/<p>/.tmux.conf` | tmux profile part |
| `.dziman/profiles/<p>/.emacs-dziman/configs/*.el` | emacs profile parts, loaded by `dz-config-profile.el` |
| `.dziman/profiles/<p>/sparse` | sparse-checkout exclude patterns for that profile (optional) |
| `.dziman/profiles/<p>/.dziman-zsh/*.zsh` | zsh profile parts, sourced last by `.zshrc` |
| `.emacs-dziman/configs/dz-config-profile.el` | loads the emacs profile parts |
| `.zshrc` | exports `DZIMAN_PROFILE`, sources zsh profile parts |
| `.gitconfig` | `[include] path = ~/.dziman/profile/.gitconfig` |
| `.tmux.conf` | `source-file -q ~/.dziman/profile/.tmux.conf` |
| `.gitignore` | ignores `.dziman/profile` (the symlink) |
| `.dziman/docs/profiles.md` | user documentation of the mechanism |

---

### Task 1: Working branch, backup tags, validation harness

**Files:**
- Worktree: `~/src/dziman/settings/.claude/worktrees/unified` (branch `unified`)
- Scratch (session scratchpad, not tracked): `validate.sh`

**Interfaces:**
- Produces: `$WT` = `~/src/dziman/settings/.claude/worktrees/unified`; `validate.sh <profile>` runs all checks against `$WT` as a fake `HOME` and prints PASS/FAIL per check. Every later task ends with `validate.sh ai` (and `main`, `work` where the task touches profile files).

- [ ] **Step 1: Create backup tags and the branch**

```bash
cd ~/src/dziman/settings
git fetch --prune origin
for b in main-computer work-computer mirror/ai-dev; do
  git tag "backup/${b//\//-}-2026-10-09" "origin/$b"
done
git tag | grep backup/
git branch unified 34e8c40
git worktree add ~/src/dziman/settings/.claude/worktrees/unified unified
```
Expected: three `backup/*` tags; worktree at `~/src/dziman/settings/.claude/worktrees/unified` on `unified` with HEAD `34e8c40`.

- [ ] **Step 2: Keep validation residue out of `git status`**

```bash
cat >> ~/src/dziman/settings/.git/info/exclude <<'EOF'
.zsh/
.zcompdump*
.emacs.d/elpa
.emacs.d/eln-cache
.emacs.d/package-quickstart.el*
.emacs.d/*.eld
.emacs.d/var/
.emacs.d/tramp
.dziman/profile
EOF
```

- [ ] **Step 3: Link the real Emacs package store into the fake HOME**

```bash
WT=~/src/dziman/settings/.claude/worktrees/unified
mkdir -p "$WT/.emacs.d"
for e in elpa eln-cache; do ln -sfn "$HOME/.emacs.d/$e" "$WT/.emacs.d/$e"; done
ls -la "$WT/.emacs.d"
```

- [ ] **Step 4: Write the harness** (scratchpad `validate.sh`)

```sh
#!/bin/sh
# validate.sh <profile> — run the dotfiles in the worktree as a fake HOME.
# Never touches the real $HOME.
set -u
WT=${WT:-$HOME/src/dziman/settings-unified}
PROFILE=${1:?usage: validate.sh <profile>}
fail=0
check() { # check <name> <command...>
  name=$1; shift
  if "$@" >"$WT/.validate.log" 2>&1; then echo "PASS $name"; else echo "FAIL $name"; sed 's/^/     /' "$WT/.validate.log"; fail=1; fi
}

export HOME="$WT"
check "config-profile $PROFILE"  "$WT/.local/bin/config-profile" "$PROFILE"
check "zsh -n all"               sh -c 'for f in "$HOME"/.zshrc "$HOME"/.dziman-zsh/*.zsh "$HOME"/.dziman/profiles/*/.dziman-zsh/*.zsh; do [ -e "$f" ] || continue; zsh -n "$f" || exit 1; done'
check "zsh interactive"          zsh -i -c 'exit'
check "zsh profile var"          zsh -i -c '[ "$DZIMAN_PROFILE" = "'"$PROFILE"'" ]'
check "git config"               git config --list
check "tmux parse"               sh -c 'tmux -L validate -f "$HOME/.tmux.conf" start-server \; kill-server'
check "emacs load"               emacs --batch -l "$HOME/.emacs.d/early-init.el" --eval '(package-activate-all)' -l "$HOME/.emacs" --eval '(message "init ok")'
printf 'zsh startup: '; /usr/bin/time -p zsh -i -c exit 2>&1 | awk '/real/ {print $2 "s"}'
rm -f "$WT/.validate.log"
exit $fail
```
`chmod +x` it. Note: `emacs --batch` implies `-q`, which is why early-init and `package-activate-all` are loaded explicitly; it catches load errors, not timing. Interactive timing (spec: ≤ 0.24 s) is measured in Task 9.

- [ ] **Step 5: Run the harness on the untouched seed**

Run: `validate.sh ai`
Expected: `FAIL config-profile ai` (script does not exist yet), all other checks PASS. This is the baseline; record the zsh startup figure.

- [ ] **Step 6: Nothing to commit** — tags and worktree are local state.

---

### Task 2: Profile mechanism

**Files:**
- Create: `.local/bin/config-profile`
- Create: `.dziman/profiles/main/README.md`, `.dziman/profiles/apple/README.md`, `.dziman/profiles/ai/README.md`
- Create: `.emacs-dziman/configs/dz-config-profile.el`
- Modify: `.zshrc` (before and after the extensions loop), `.emacs` (last `require`), `.gitconfig` (append), `.tmux.conf` (append), `.gitignore` (append)

**Interfaces:**
- Produces: `config-profile <name>` (exit 0, symlink set; exit 2 on usage/unknown name); `config-profile --show` prints the active name; env `DZIMAN_PROFILE`; include points `~/.dziman/profile/{gitconfig,tmux.conf,emacs/*.el}` and `~/.dziman-zsh/profiles/<p>/*.zsh`. Later tasks put profile residue in exactly these places.

- [ ] **Step 1: Write the failing check**

Run: `validate.sh ai`
Expected: `FAIL config-profile ai` (no such file).

- [ ] **Step 2: Create `config-profile`**

`.local/bin/config-profile`:
```sh
#!/bin/sh
# Select the dotfiles profile of this machine.
#
#   config-profile <name>   point ~/.dziman/profile at ~/.dziman/profiles/<name>
#   config-profile --show   print the active profile name
#
# Every shared config file refers to ~/.dziman/profile/..., so this symlink is
# the only per-machine state. Profiles live in ~/.dziman/profiles/<name>/.
set -eu

profiles_dir="$HOME/.dziman/profiles"
link="$HOME/.dziman/profile"

usage() {
  echo "usage: config-profile <name> | --show" >&2
  echo "profiles: $(ls "$profiles_dir" | tr '\n' ' ')" >&2
  exit 2
}

[ $# -eq 1 ] || usage

if [ "$1" = "--show" ]; then
  basename "$(readlink "$link")"
  exit 0
fi

name=$1
if [ ! -d "$profiles_dir/$name" ]; then
  echo "config-profile: no such profile: $name" >&2
  usage
fi

ln -sfn "profiles/$name" "$link"
echo "profile: $name"
```
`chmod +x .local/bin/config-profile`.

- [ ] **Step 3: Pin the unknown-profile behaviour**

```bash
cd ~/src/dziman/settings/.claude/worktrees/unified
mkdir -p .dziman/profiles/main .dziman/profiles/apple .dziman/profiles/ai
for p in main apple ai; do printf '# %s profile\n' "$p" > .dziman/profiles/$p/README.md; done
HOME=$PWD .local/bin/config-profile ai; readlink .dziman/profile          # → profiles/ai
HOME=$PWD .local/bin/config-profile bogus; echo "exit=$?"; readlink .dziman/profile
```
Expected: second call prints `no such profile: bogus`, usage with `ai main work`, `exit=2`, symlink still `profiles/ai`. Replace the README one-liners with a real sentence each: main = "Personal main machine", work = "Work (Apple) machine", ai = "AI virtual mac (m6m-ai-dev)".

- [ ] **Step 4: zsh hook**

In `.zshrc`, directly above `# Include all enabled extensions`:
```zsh
# Machine profile, selected with `config-profile <name>` (~/.dziman/profile -> profiles/<name>)
export DZIMAN_PROFILE="${$(readlink ~/.dziman/profile 2>/dev/null):t}"
```
Directly below the extensions `for` loop (inside the same `Extensions` banner):
```zsh
# Profile-specific extensions, sourced last so they can override shared ones
for extension_file in ~/.dziman/profile/.dziman-zsh/*.zsh(N); do
    source "$extension_file"
done
```

- [ ] **Step 5: emacs hook**

`.emacs-dziman/configs/dz-config-profile.el`:
```elisp
;;; -*- lexical-binding: t -*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Machine profile overrides: every *.el in ~/.dziman/profile/.emacs-dziman/configs/
;;;;;; (profile chosen with `config-profile`). Required last from ~/.emacs so
;;;;;; profile files can override the shared configs.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(let ((dir (expand-file-name "~/.dziman/profile/.emacs-dziman/configs/")))
  (when (file-directory-p dir)
    (dolist (file (directory-files dir t "\\.el\\'"))
      (load file nil 'nomessage))))

(provide 'dz-config-profile)
```
In `.emacs`, add `(require 'dz-config-profile)` as the last `require` (after `dz-config-doom-modeline` on the seed; after `dz-config-preload` once Task 3 lands it).

- [ ] **Step 6: git and tmux hooks**

Append to `.gitconfig`:
```
[include]
  path = ~/.dziman/profile/.gitconfig
```
Append to `.tmux.conf`:
```
# machine profile part, selected with `config-profile`
source-file -q ~/.dziman/profile/.tmux.conf
```
Append to `.gitignore`:
```

# Active machine profile (symlink made by `config-profile`)
.dziman/profile
```

- [ ] **Step 7: Verify with a profile that overrides something**

Temporarily (not committed) create `$WT/.dziman/profiles/ai/.gitconfig` with `[user]\n  email = probe@example.com`, run:
```bash
WT=~/src/dziman/settings/.claude/worktrees/unified
HOME=$WT git config --get user.email       # probe@example.com
rm $WT/.dziman/profiles/ai/.gitconfig
HOME=$WT git config --get user.email       # dzmitry.rusak@gmail.com
```
Then `validate.sh ai`, `validate.sh main`, `validate.sh apple` → all PASS.

- [ ] **Step 8: Verify the no-symlink case (Review Focus 1)**

```bash
rm $WT/.dziman/profile
HOME=$WT zsh -i -c 'echo "[$DZIMAN_PROFILE]"'                        # prints "[]" and no error
HOME=$WT git config --list >/dev/null && echo git-ok
HOME=$WT sh -c 'tmux -L v -f $HOME/.tmux.conf start-server \; kill-server' && echo tmux-ok
HOME=$WT emacs --batch -l $WT/.emacs.d/early-init.el --eval '(package-activate-all)' -l $WT/.emacs --eval '(message "ok")' 2>&1 | tail -1
```
Expected: no errors. Restore with `HOME=$WT $WT/.local/bin/config-profile ai`.

- [ ] **Step 9: Commit**

```bash
cd ~/src/dziman/settings/.claude/worktrees/unified
git add .local/bin/config-profile .dziman/profiles .emacs-dziman/configs/dz-config-profile.el .zshrc .emacs .gitconfig .tmux.conf .gitignore
git commit -m "[profile] Add machine profile mechanism

One untracked symlink ~/.dziman/profile -> profiles/<name> selects the
machine profile; zsh, emacs, git and tmux include the profile part from
there. Switch with \`config-profile <name>\`.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Stage 1 — cherry-pick `mirror/ai-dev` with per-commit review

**Files:** whatever each commit touches; AI-mac residue goes to `.dziman/profiles/ai/.gitconfig`, `.dziman/profiles/ai/.dziman-zsh/*.zsh`.

**Interfaces:**
- Consumes: profile include points from Task 2.
- Produces: `unified` containing the accepted parts of all 31 commits.

**Procedure for every commit** (repeat 31 times, oldest first):

- [ ] **a. Show the review** — in chat, for commit `<h>`: subject, `git show --stat`, and for each hunk group one line + the proposal from the table below. Mask the key: `git show <h> | sed -E 's/(OPENROUTER_API_KEY=)"[^"]*"/\1"<masked>"/'`.
- [ ] **b. Ask** — `AskUserQuestion`: accept as proposed / accept verbatim / amend (user says what) / drop. Up to 4 commits per call when the proposals are plain "keep".
- [ ] **c. Apply** — `git cherry-pick -n <h>`; perform the amendments (move lines into the profile file, `git add` both sides); for a *drop*, `git cherry-pick --abort` is not needed with `-n`: `git reset --hard` instead.
- [ ] **d. Commit** — `git commit -C <h>` then `git commit --amend` to append `Source: <h>` and the `Co-Authored-By:` trailer. Amended commits add a line describing what was moved, e.g. `Moved git identity to profiles/ai/.gitconfig`.
- [ ] **e. Validate** — `validate.sh ai` after every commit touching zsh/emacs/git/tmux; after other commits every 5th commit is enough.

**Per-commit proposals** (what is machine-specific is the proposal, the user decides):

| # | hash | subject | proposal |
|---|---|---|---|
| 1 | `5a5c1d9` | Setting up AI virtual mac | keep kilo files, `578_swift` swiftly guard, `888_ai` (as is); **move** `.gitconfig` `[user]` change → `.dziman/profiles/ai/.gitconfig` containing only `[user]\n  email = dzmitry.rusak+ai@gmail.com` (the `name = AI Clone…` line is reverted by #21, so skip it) |
| 2 | `ea5cdca` | Kilo CLI fine tuning | keep |
| 3 | `578c3f3` | Agents and settings | keep |
| 4 | `ee07297` | Agents and settings | keep |
| 5 | `7f05741` | Claude files | keep |
| 6 | `ead03b6` | Add skills and agents | keep |
| 7 | `b61414e` | Update global AGENTS.md. Remove local-dev agent | keep |
| 8 | `4df5810` | [zsh] Minor updates | keep `compinit -u`, Toolbox PATH; **ask** on nvm→fnm (work branch added nvm support; is `fnm` installed on main and work?). If not: nvm/fnm block → tier 1, `.dziman/profiles/ai/.dziman-zsh/060_development.zsh` gets the `fnm` line, shared file keeps nvm |
| 9 | `5bdf17f` | [tmux][git][iterm] Minor updates | keep `.gitignore`, iTerm `AiModel`; **ask** tmux `default-shell /bin/zsh` vs `/opt/homebrew/bin/zsh` (work has it commented out) — proposal: `/bin/zsh` common |
| 10 | `0226dc4` | Suppress zsh completion warning | keep |
| 11 | `46fd7b1` | A bunch of everything | keep (omp reconciled with work in Task 8) |
| 12 | `5c1130a` | [zsh][tmux] Latest | keep cargo PATH + tmux; **move** `EDITOR="emacs --no-window-system"` → `.dziman/profiles/ai/.dziman-zsh/004_env.zsh` (shared keeps `emacsclient`) |
| 13 | `d359425` | Configure auto-mode policy | keep |
| 14 | `facfabe` | Rewrite dz-git-forge-workflow skill | keep |
| 15 | `58e610a` | Add ccstatusline configuration | keep |
| 16 | `fee8084` | omp setupVersion 2 | keep |
| 17 | `37b1fc1` | Add openai-usage extension | keep verbatim (removed again in #23; verbatim keeps history simple) |
| 18 | `ff8ebd7` | Scope F-Sy-H sourcing | keep |
| 19 | `4eaa9ff` | Add just completion | keep |
| 20 | `c41abd9` | claude with dedicated emacsclient socket | keep |
| 21 | `2eccd0b` | Use real name for AI git identity | **drop** — empty after #1's amendment (verify: `git cherry-pick -n` leaves no diff) |
| 22 | `6da8f08` | tmux extended keys | keep |
| 23 | `e2b0b10` | Latest, mostly AI | keep all; mkcert `NODE_EXTRA_CA_CERTS` is guarded by file existence → common (**ask** if the user prefers `profiles/ai`) |
| 24 | `7597db8` | Latest Claude settings | keep |
| 25 | `d7b0acf` | Latest Claude refinements | keep |
| 26 | `2069f44` | Model presets for omp | keep |
| 27 | `9859c0d` | emacs defer package loading | keep; afterwards move `(require 'dz-config-profile)` below the new `(require 'dz-config-preload)` |
| 28 | `631c320` | Track codex/omp/shared skills | keep verbatim (teamcity script removed again in #30) |
| 29 | `d63c065` | emacs defer remaining eager modes | keep |
| 30 | `c11ba66` | zsh startup 0.52→0.09 s | keep |
| 31 | `a1ad581` | Restore jenv completion | keep |

- [ ] **Final step: fold this machine's two uncommitted edits**

```bash
cd ~/src/dziman/settings/.claude/worktrees/unified
git --git-dir=$HOME/.dziman-dotfiles --work-tree=$HOME diff -- .config/ccstatusline/settings.json .omp/agent/config.yml | git apply
git add .config/ccstatusline/settings.json .omp/agent/config.yml
git commit -m "[ai] ccstatusline widget path via ~, omp theme zenburn

Uncommitted edits found on m6m-ai-dev at unification time.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
validate.sh ai
```
Expected: PASS; zsh startup ≈ 0.09 s.

---

### Task 4: Stage 2 report tooling (used by Tasks 5–8)

**Files:** scratchpad `feature-report.sh` (not tracked)

**Interfaces:**
- Produces: `feature-report.sh <path>...` prints, for each path, presence on `unified` and `origin/work-computer` and the diff `unified → work` (`-w` for `.gitconfig`), masked. The executor reads these diffs, groups hunks into features, and writes the report table in chat.

- [ ] **Step 1: Write the script**

```sh
#!/bin/sh
# feature-report.sh <path>... — diff unified -> work-computer per path, for feature reconstruction
cd ~/src/dziman/settings/.claude/worktrees/unified
for p in "$@"; do
  echo "################ $p"
  u=$(git rev-parse -q --verify "unified:$p" 2>/dev/null || echo -)
  w=$(git rev-parse -q --verify "origin/work-computer:$p" 2>/dev/null || echo -)
  echo "unified=${u%${u#???????}} work=${w%${w#???????}}"
  case $p in *.gitconfig) opt=-w;; *) opt=;; esac
  git diff $opt unified origin/work-computer -- "$p" \
    | sed -E 's/(OPENROUTER_API_KEY=)"[^"]*"/\1"<masked>"/; s/(IdentityFile|HostName|password) .*/\1 <masked>/'
done
```

- [ ] **Step 2: Report format** (identical for every pass; written in chat, not to a file)

```
| id | feature | origin | files there | files in unified | status | tier | owner |
| O1 | git `switch` aliases swd/swm (+cd/cm kept) | work | .gitconfig | .gitconfig | independent | 0 | common |
| O3 | `pushf` --force vs --force-with-lease | work vs mc | .gitconfig | .gitconfig | conflict | 0 | ask |
...
Drop (no feature): tabs→spaces in .gitconfig; comment removal on `diffr`.
Files only on work (tier 3 candidates): ...
```
`status` ∈ independent / conflict with `<id>`; `owner` ∈ common / profile:<name> / drop / ask.

- [ ] **Step 3: Decision step** — `AskUserQuestion`, ≤ 4 questions per call, one question per *conflict* or *ask* row; independent rows are listed once with a single "veto any?" question.

- [ ] **Step 4: Port step** — one commit per accepted feature, re-implemented by hand against `unified` (never `git checkout origin/work-computer -- <file>` for shared files; whole-file take-over is allowed only for tier-3 profile-only files). Subject: area tag + feature; body: `Source: work-computer <hash(es)>` found with `git log --oneline origin/work-computer -- <file>`.

---

### Task 5: Pass 1 — other apps

**Files:** `.gitconfig`, `.gitconfig-apple`, `.gitconfig-apple-templates`, `.gitignore`, `.tmux.conf`, `.iterm/com.googlecode.iterm2.plist`, `.editorconfig`, `.dziman-zsh/.editorconfig`, `.config/cmux/cmux.json`, `Library/Application Support/com.mitchellh.ghostty/config.ghostty`, `Library/Application Support/com.cmuxterm.app/config.ghostty`, `Library/Application Support/Code/User/settings.json`, `.dziman/brew.packages`, `.dziman/brew.cask.packages`, `.dziman/brew.taps`, `.dziman/list-installed.sh`, `.navi/cheats/apple.src.cheat`, `.local/share/navi/apple.src.cheat`, `.gradle/init.d/*`, `.m2/settings.xml`, `.pip/pip.conf`, `.ssh/config`, `Local/AS/**`, `src/apple/**`; mechanism additions: `.local/bin/config-profile` (sparse), `.dziman/profiles/<p>/sparse`.

**Interfaces:**
- Consumes: `feature-report.sh`, include points from Task 2.
- Produces: `config-profile` applies `~/.dziman/profiles/<p>/sparse` when present (exit code unchanged); profile dirs populated for work.

- [ ] **Step 1: Generate the diffs**

Run: `feature-report.sh .gitconfig .gitignore .tmux.conf .editorconfig .dziman-zsh/.editorconfig .config/cmux/cmux.json 'Library/Application Support/com.mitchellh.ghostty/config.ghostty' 'Library/Application Support/Code/User/settings.json' .dziman/brew.taps .dziman/list-installed.sh` and `git diff --stat unified origin/work-computer -- .iterm`.

- [ ] **Step 2: Write the report.** Seed from exploration (verify against the diffs, extend as needed):

| id | feature | origin | status | proposed tier/owner |
|---|---|---|---|---|
| O1 | Apple `includeIf` ×3 + `.gitconfig-apple`, `.gitconfig-apple-templates` | work | independent | tier 1 → `profiles/apple/.gitconfig` holds the includeIf lines; the two files move to `profiles/apple/.gitconfig-apple{,-templates}` and the includeIf paths point there |
| O2 | `switch` aliases `swd`/`swm`, `cd`/`cm` kept | work | independent | common |
| O3 | `pushf` uses `--force` (work) vs `--force-with-lease` (unified) | conflict | ask; proposal: keep `--force-with-lease` |
| O4 | delta `blame-palette` `#4B6C5A` vs `#486C5A` | conflict | ask (cosmetic) |
| O5 | tabs→spaces reformat, comment removal on `diffr`, comment "shortcut for fetch" | work | — | drop |
| O6 | tmux stripped on work: prefix `C-z` block removed, `default-shell` commented, overrides removed | conflict with ai-dev tmux features | ask; proposal: common = unified; if work needs `C-b`, `profiles/apple/tmux.conf` sets `set -g prefix C-b` |
| O7 | `.gitignore`: IDEA `out/ .run/`, `test-env/`, gradle entries, `*.swp`, `.factorypath` | work | independent | common |
| O8 | `.gitignore`: `.claude/` (whole dir) | work | conflict with tracked `~/.claude/**` and `**/.claude/settings.local.json` | ask; proposal: drop |
| O9 | `.editorconfig`: 4-space default, `[*.zsh] [*.el] [*.json] [*.plist]` = 2; removed `end_of_line`/`insert_final_newline`; `.dziman-zsh/.editorconfig` deleted | conflict | ask; proposal: keep unified's lf/final-newline/2-space default, add work's `[*.json]`/`[*.plist]` sections; if 4-space default is wanted for work only: tier 2 is not available for editorconfig → decide common |
| O10 | cmux: `option: true` for ctrl-c binding | conflict | ask (cosmetic) |
| O11 | VS Code: theme `Zenburn` vs `Higher Contrast Zenburn`; `renderWhitespace boundary` vs `all`; font FuraCode vs JetBrainsMono; `claudeCode.preferredLocation`, `intellij.*` added; go/java/python/swift/kilo settings removed | mixed | ask per item; swift/Xcode-beta paths → `ask` whether main-only (would need tier 2 filter — avoid; prefer common) |
| O12 | ghostty: font family list + size 18 vs 22, cursor-style block, `shell-integration-features = no-cursor`, commented theme block | conflict | ask; proposal: common = work's cursor/shell-integration lines; font size ask (display-specific → if profile-specific, ghostty supports `config-file = ~/.dziman/profile/ghostty` include → tier 1) |
| O13 | `list-installed.sh` script (work) vs `list-installed()` fn in `999_helpers` (unified); `brew.taps` not written on work | conflict | ask; proposal: keep the function (unified), writes brew lists to `~/.dziman/profile/brew.*` → brew lists become per profile (tier 1 data), move existing lists: unified's → `profiles/main/`, work's → `profiles/apple/`, this machine regenerates `profiles/ai/` later |
| O14 | iTerm plist: 1618+/1873− vs unified | conflict | ask: pick one version as common (proposal: unified's); list work-only iTerm features the user may want re-applied by hand in the GUI (AI disabled, checkstyle highlight trigger) |
| O15 | navi Apple cheat (two copies) | work | independent | tier 3: `profiles/apple/navi/apple.src.cheat`, symlink `.navi/cheats/apple.src.cheat → ../../.dziman/profile/navi/apple.src.cheat`; `.local/share/navi/...` copy → drop (ask) |
| O16 | `.ssh/config` (Apple GitHub hosts) | work | independent | tier 3 symlink `.ssh/config → ../.dziman/profile/ssh_config`; verify `HOME=$WT ssh -G example.com` succeeds on `main` (dangling) and `work` |
| O17 | `.m2/settings.xml`, `.pip/pip.conf`, `.gradle/init.d/*` | work | independent | tier 3 symlinks through `~/.dziman/profile/` (`.m2/settings.xml → ../.dziman/profile/m2-settings.xml`, `.pip/pip.conf → ../.dziman/profile/pip.conf`, `.gradle/init.d → ../.dziman/profile/gradle-init.d`) |
| O18 | `Local/AS/**`, `src/apple/**` | work | independent | tier 3 sparse: tracked as is; `profiles/main/sparse` and `profiles/ai/sparse` exclude `/Local/` and `/src/apple/` |

- [ ] **Step 3: Decisions** — `AskUserQuestion` on O3, O4, O6, O8, O9, O10, O11, O12, O13, O14, O15 (≤ 4 per call), one veto question for the independent rows.

- [ ] **Step 4: Add sparse-checkout support to `config-profile`** (needed by O18; skip only if the user drops O18)

Insert before the final `echo "profile: $name"` in `.local/bin/config-profile`:
```sh
# Hide directories that exist for other profiles only (patterns in profiles/<name>/sparse).
# Local repo state, applied idempotently; absent file = full checkout.
git_dir=${DZIMAN_DOTFILES:-$HOME/.dziman-dotfiles}
if [ -d "$git_dir" ]; then
  sparse="$profiles_dir/$name/sparse"
  if [ -r "$sparse" ]; then
    git --git-dir="$git_dir" --work-tree="$HOME" sparse-checkout set --no-cone --stdin < "$sparse"
  else
    git --git-dir="$git_dir" --work-tree="$HOME" sparse-checkout disable
  fi
fi
```
`profiles/main/sparse` and `profiles/ai/sparse`:
```
/*
!/Local/
!/src/apple/
```
Test in the fake HOME with a throwaway bare clone:
```bash
WT=~/src/dziman/settings/.claude/worktrees/unified
git clone --bare ~/src/dziman/settings /tmp/claude-502/-Users-m6-ai-dev-src-dziman-settings/*/scratchpad/dotfiles.git
BARE=$(ls -d /tmp/claude-502/-Users-m6-ai-dev-src-dziman-settings/*/scratchpad/dotfiles.git)
HOME=$WT DZIMAN_DOTFILES=$BARE $WT/.local/bin/config-profile ai
git --git-dir=$BARE sparse-checkout list                                   # shows the 3 patterns
HOME=$WT DZIMAN_DOTFILES=$BARE $WT/.local/bin/config-profile ai; echo $?  # idempotent, 0
HOME=$WT DZIMAN_DOTFILES=$BARE $WT/.local/bin/config-profile apple
git --git-dir=$BARE config --get core.sparseCheckout                       # false / unset
```
(The bare clone has no work-tree checkout; this verifies pattern handling only. Review Focus 4's `config status` check is done at rollout, Task 9.)

- [ ] **Step 5: Port accepted features**, one commit each, e.g.:

```bash
git add .gitconfig .dziman/profiles/apple/.gitconfig .dziman/profiles/apple/.gitconfig-apple .dziman/profiles/apple/.gitconfig-apple-templates
git commit -m "[git] Apple includes move to the work profile

Source: work-computer ce2934f 693fe6d

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```
For every tier-3 symlink: `ln -s ../.dziman/profile/<file> <path>` (relative), `git add <path>`; check `git ls-files -s <path>` shows mode `120000`.

- [ ] **Step 6: Validate** — `validate.sh main`, `validate.sh apple`, `validate.sh ai`; plus for O16: `HOME=$WT ssh -G example.com >/dev/null && echo ssh-ok` under both `config-profile main` (dangling) and `work`.

---

### Task 6: Pass 2 — emacs

**Files:** `.emacs`, `.emacs.d/early-init.el`, `.emacs-dziman/custom.el`, `.emacs-dziman/abbrevs.def`, `.emacs-dziman/configs/*.el`, `.emacs-dziman/configs/org-templates/*`, `.emacs-dziman/configs/dz-config-helm.el` (work only).

- [ ] **Step 1: Generate the diffs**

```bash
feature-report.sh .emacs .emacs.d/early-init.el .emacs-dziman/custom.el .emacs-dziman/abbrevs.def \
  $(cd ~/src/dziman/settings/.claude/worktrees/unified && git diff --name-only unified origin/work-computer -- .emacs-dziman/configs)
git log --oneline origin/main-computer..origin/work-computer -- .emacs .emacs-dziman   # feature names from subjects
```

- [ ] **Step 2: Write the report.** Known seeds: `dz-config-helm.el` + commented `(require 'dz-config-helm)` → drop (Helm replaced by Vertico on all branches); `org-templates/journal-apple-meeting.tmpl.org` → tier 3 (`profiles/apple/emacs/org-templates/…` with the capture template registered from `profiles/apple/emacs/org.el`); `custom.el` `safe-local-variable-values` → common union; `journal-month.tmpl.org` diff → ask; the 10 modified `dz-config-*.el` → one feature per logical change found in the diff, cross-checked against the work commit subjects (`git-timemachine`, org soft wraps, `org-roam`, agenda refresh binding, TODO sequence, rainbow tags, capture templates, hydra debug, iOS/Swift minimal setup, temp files out of sight, undo-tree fix, keybinding conflict fix). Mark as *conflict* any change touching a region rewritten by the ai-dev defer commits (`9859c0d`, `d63c065`) — the deferred form wins structurally; the feature is re-expressed inside it.

- [ ] **Step 3: Decisions** — as in Task 4.

- [ ] **Step 4: Port**, one commit per feature, re-implemented in the deferred (`:defer`/`with-eval-after-load`) style of `unified`. Never undo a defer.

- [ ] **Step 5: Validate** — `validate.sh` for all three profiles; additionally byte-compile every changed file: `HOME=$WT emacs --batch -l $WT/.emacs.d/early-init.el --eval '(package-activate-all)' -L $WT/.emacs-dziman/configs -f batch-byte-compile <changed files>` → no errors (warnings acceptable), then `rm` the produced `.elc`.

---

### Task 7: Pass 3 — zsh

**Files:** `.zshrc`, `.dziman-zsh/*.zsh`, `.dziman-zsh/completions/*`, `.dziman/profiles/<p>/.dziman-zsh/*.zsh`.

- [ ] **Step 1: Generate the diffs**

```bash
feature-report.sh $(cd ~/src/dziman/settings/.claude/worktrees/unified && git diff --name-only unified origin/work-computer -- .zshrc .dziman-zsh)
git log --oneline origin/main-computer..origin/work-computer -- .zshrc .dziman-zsh
```

- [ ] **Step 2: Write the report.** Known seeds: work-only files `550_aws.enabled.zsh` (unified has `550_aws.disabled.zsh`) → ask enable/disable per profile (tier 1: profile file sources it); `577_js.enabled.zsh` (nvm) vs unified's `577_python.enabled.zsh` (deleted on work) and `fnm` in `060` → reconcile with the Task 3 #8 decision; `578_swift` and `999_helpers` deleted on work → keep (unified); Apple helpers (artifactory keychain, local redis, `.modules` management, DPE/merch PATH, personal SSH key to keychain, hydra prompt status) → tier 1 `.dziman-zsh/profiles/apple/*.zsh`; generic improvements (forgit, navi widget + keybindings, bulk git commands with gum confirm, `fd`/`fzf` wrappers, rg "UI", `rg` global config, IDEA launcher updates, jenv refresh, `command-exists` helper, trailing-space cleanup) → common, each re-expressed on top of the ai-dev startup-time work (`compinit -C`, lazy jenv); any work change that re-introduces eager init is a *conflict*, proposal: keep lazy.

- [ ] **Step 3: Decisions**; **Step 4: Port** (one commit per feature); **Step 5: Validate** — `validate.sh` ×3 and confirm `zsh startup` stays ≤ the Task 3 figure (±0.02 s). If a ported feature adds > 0.02 s, report it before committing and offer a lazy variant.

---

### Task 8: Pass 4 — AI

**Files:** `.omp/agent/**`, `.omp/plugins/**`, `.pi/agent/settings.json`, `.dziman-zsh/888_ai.enabled.zsh`, `.claude/**`, `.codex/config.toml`, `.config/kilo/**`, `.kilo/agent/**`, `.config/ccstatusline/settings.json`, `.agents/**`, `.local/bin/claude-editor`.

- [ ] **Step 1: Check omp's layering options** before proposing tiers: look for an include/overlay mechanism in omp (`omp --help`, `~/.omp/agent/config.yml` docs or schema, env like `OMP_CONFIG`). Record the finding in the report header.

- [ ] **Step 2: Generate the diffs**

```bash
feature-report.sh .dziman-zsh/888_ai.enabled.zsh .omp/agent/config.yml .omp/agent/models.yml .pi/agent/settings.json
cd ~/src/dziman/settings/.claude/worktrees/unified && git diff --stat unified origin/work-computer -- .omp .pi .claude .codex .config/kilo .kilo
```

- [ ] **Step 3: Write the report.** Known seeds: omp — work has 6 role agents (`impl-*`, `review-*`), `bin/jdtls-omp`, `lsp.json`, `rules/*`, `themes/zenburn.json`, 330-line `models.yml`; unified has setupVersion 2 config with model presets and `plugins/`. User intent: theme, roles, rules common; models, providers, sandbox per profile. Proposal: if omp supports an include → tier 1 (`profiles/<p>/omp/models.yml`); otherwise tier 2 filter for `config.yml`/`models.yml` (filter script `.dziman/bin/profile-yaml-filter` using `yq`, smudge merges `profiles/<p>/omp/*.patch.yml`, clean strips those keys) — present both and let the user pick. `.pi/agent/settings.json` → ask (common or work). `888_ai` work version vs unified version → union, key untouched. `.claude/**` exists only on unified → common.

- [ ] **Step 4: Decisions**; **Step 5: Port**; **Step 6: Validate** — `validate.sh` ×3; if a tier-2 filter was introduced: `git check-attr filter .omp/agent/models.yml` shows the filter, and a round trip `git show HEAD:.omp/agent/models.yml | git hash-object --stdin` equals `git ls-files -s .omp/agent/models.yml` after `git add` on the smudged file (clean restores the tracked bytes).

---

### Task 9: Documentation, final validation, rollout notes

**Files:**
- Create: `.dziman/docs/profiles.md`
- Modify: `.dziman/docs/specs/2026-10-09-profile-unification-design.md` (status line → implemented)

- [ ] **Step 1: Write `profiles.md`** — sections: *What it is* (the symlink, one paragraph); *Switch* (`config-profile <name>`, `--show`); *Where profile parts live* (the table from "File structure" above, only rows that exist after Tasks 5–8); *Add a profile* (mkdir + README + optional sparse + `config-profile`); *Rollout on a machine*:
```
config fetch
config switch unified
config-profile <name>
exec zsh
```
plus the list of files that leave `$HOME` on switch for each old branch (from the Task 5–8 reports, tier-3/drop rows).

- [ ] **Step 2: Final validation on this machine** — `validate.sh ai`, `validate.sh main`, `validate.sh apple` → all PASS; zsh startup ≤ 0.09 s + 0.02; emacs interactive startup:
```bash
HOME=$WT script -q /dev/null emacs -nw --eval '(add-hook (quote emacs-startup-hook) (lambda () (princ (format "init %s\n" (emacs-init-time)) (function external-debugging-output)) (kill-emacs)))' 2>&1 | grep init
```
Expected: ≤ 0.24 s + 0.05.

- [ ] **Step 3: Commit docs**

```bash
git add .dziman/docs/profiles.md .dziman/docs/specs/2026-10-09-profile-unification-design.md .dziman/docs/plans/2026-10-09-profile-unification.md
git commit -m "[docs] Profile mechanism and unification design

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

- [ ] **Step 4: Hand over** — report in chat: branch `unified` tip, commit count, the three validation results, and ask the user whether to push `unified` (the only push in this plan). Live rollout on this machine (`config switch unified && config-profile ai`) only on the user's explicit go; first `config status` must be clean (Review Focus 4), then `exec zsh`.
