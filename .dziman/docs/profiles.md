# Machine profiles

One dotfiles branch (`unified`) for every machine. Per-machine differences live
in a profile directory; one untracked symlink selects the active profile:

```
~/.dziman/profile  →  ~/.dziman/profiles/<name>
```

Every shared config refers to `~/.dziman/profile/...`, so tracked content is
identical on all machines. Profiles: `main` (personal main machine), `apple`
(work machine), `ai` (AI virtual mac).

## Switch

```
config-profile <name>     # set the symlink, apply the profile's sparse-checkout list
config-profile --show     # print the active profile
```

`DZIMAN_PROFILE` holds the name in zsh (empty when no profile is set). Shared
files do not branch on it; put a difference in the profile directory instead.

## Where profile parts live

A profile directory mirrors `$HOME`: the part for `~/.gitconfig` is
`~/.dziman/profiles/<p>/.gitconfig`, and so on.

| app | shared file includes | profile part |
|---|---|---|
| zsh | `.zshrc` sources them after the shared extensions | `.dziman-zsh/*.zsh` |
| emacs | `dz-config-profile.el`, required last from `.emacs` | `.emacs-dziman/configs/*.el` (+ `org-templates/`) |
| git | `[include] path = ~/.dziman/profile/.gitconfig` | `.gitconfig`, `.gitconfig-apple*` |
| tmux | `source-file -q ~/.dziman/profile/.tmux.conf` | `.tmux.conf` |
| omp | the `omp` shell function adds `--config <profile config>`; the overlay outranks the shared file, so change models in the profile overlay. `/model` and preset saves inside omp write `modelRoles` into the shared `~/.omp/agent/config.yml`: they last one session and leave `config status` dirty; revert them there | `.omp/agent/config.yml` (models, presets, services), `.omp/agent/models.yml` |
| ssh, pip, maven, gradle, navi | tracked symlinks in `$HOME` point into the profile (dangling on other profiles) | `.ssh/config`, `.pip/pip.conf`, `.m2/settings.xml`, `.gradle/init.d/`, `.navi/cheats/apple.src.cheat` |
| zsh prompt | `right-prompt` calls `profile-prompt-status` when the profile defines it | `.dziman-zsh/910_prompt.zsh` |
| Claude Code | `~/.claude/CLAUDE.md` ends with `@~/.dziman/profile/.claude/CLAUDE.md`; `~/.claude/settings.json`, `~/.claude/skills/dz-git-forge-workflow`, `~/.claude/statusline-command.sh`, `~/.claude/dz-session-recap.local.md` and `~/.claude/apple/{filters-config.json,tool_allowlist.csv}` are symlinks into the profile (no layering in Claude Code) | `.claude/CLAUDE.md`, `.claude/settings.json`, `.claude/skills/dz-git-forge-workflow/` (main's are symlinks to ai's); apple only: `.claude/statusline-command.sh`, `.claude/dz-session-recap.local.md`, `.claude/apple/` |

Files that exist for one profile only (`Local/AS`, `src/apple`, omp's Java LSP,
`.pi`) are tracked as is; `profiles/<p>/sparse` lists what the *other* profiles
hide (git sparse-checkout, applied by `config-profile`).

Missing profile parts are no-ops everywhere: an absent include file, a dangling
symlink, an empty zsh glob.

## Add a profile

```
mkdir ~/.dziman/profiles/<name>
echo '# <name> profile — <description>' > ~/.dziman/profiles/<name>/README.md
cp ~/.dziman/profiles/main/sparse ~/.dziman/profiles/<name>/sparse   # if it should hide the apple-only dirs
config-profile <name>
```

Then add parts under the same relative paths as in `$HOME`.

## Rollout on a machine

First list untracked files in `$HOME` that `unified` tracks; git refuses to
overwrite them, and a plain `-f` would discard the machine's own copies
(`~/.ssh/config`, an edited omp theme, ...). Move each aside, or into the profile
where it belongs. Also commit or discard local edits to tracked files (Claude Code
edits `~/.claude/settings.json` itself); on the apple machine diff the live
`~/.claude/settings.json` against the profile's before moving it aside:

```
config fetch origin unified
config ls-tree -r --name-only origin/unified | while read -r p; do
  { [ -e "$HOME/$p" ] || [ -L "$HOME/$p" ]; } && ! config ls-files --error-unmatch -- ":/$p" >/dev/null 2>&1 && echo "$p"
done
```

Then (full path: `~/.local/bin` is not on PATH until the new zsh config runs):

```
config switch unified
~/.local/bin/config-profile <name>
exec zsh
```

Check `config status` is clean afterwards. `config-profile` enables
sparse-checkout in the bare repo for profiles that have a `sparse` file; git
records that in the repo config (`extensions.worktreeConfig`, `core.sparseCheckout`). Files that were tracked on the old
branch and are not on `unified` disappear from `$HOME` on switch:

- from `main-computer`: `.dziman-zsh/.editorconfig`, `.dziman-zsh/578_swift.enabled.zsh`
- from `work-computer`: `.dziman-zsh/550_aws.enabled.zsh`, `.dziman-zsh/577_js.enabled.zsh`,
  `.dziman/list-installed.sh`, `.emacs-dziman/configs/dz-config-helm.el`,
  `.local/share/navi/apple.src.cheat`; moved into the apple profile:
  `.gitconfig-apple*`, `.gradle/init.d/*`, `journal-apple-meeting.tmpl.org`
- from `mirror/ai-dev`: Kilo (`.config/kilo`, `.kilo`), `.codex/config.toml`,
  `.agents/*`, `.dziman-zsh/.editorconfig`, `.dziman-zsh/578_swift.enabled.zsh`

On the apple machine, iTerm keeps the shared plist; the work-only iTerm profiles
("Dziman Claude", "Emacs fonts") and triggers were not carried over.

Deferred: splitting the Homebrew / VS Code package lists into common + per-profile
sets (`list-installed` still writes the shared files).
