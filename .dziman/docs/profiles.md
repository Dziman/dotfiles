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

`config` (`~/.local/bin/config`) is git on the dotfiles repo (`~/.dziman-dotfiles`,
work tree `$HOME`). `config status` names a file the profile links by its `$HOME`
path, and such a link given as an argument (`config add ~/.ssh/config`) is
translated to the tracked file. `config profile` is the profile tool
(`~/.local/bin/git-profile`, a git subcommand):

```
config profile <name>             # set the symlink, link the profile's files into $HOME
config profile --show             # print the active profile
config profile status             # each link: ok / broken / shadowed / missing; untracked profile files
config profile links              # the active profile's linked files
config profile adopt <path>...    # move a file or directory into the active profile, list and link it
config profile unadopt <path>...  # move it back into $HOME, tracked there (config rm --cached to untrack)
config profile --help             # the gist of this page, with the active profile
```

`DZIMAN_PROFILE` holds the name in zsh (empty when no profile is set). Shared
files do not branch on it; put a difference in the profile directory instead.

## Where profile parts live

A profile directory mirrors `$HOME`: the part for `~/.gitconfig` is
`~/.dziman/profiles/<p>/.gitconfig`, and so on.

| app | shared file includes | profile part |
|---|---|---|
| zsh | `.zshrc` sources them after the shared extensions | `.zsh-dziman/*.zsh` |
| emacs | `dz-config profile.el`, required last from `.emacs` | `.emacs-dziman/configs/*.el` (+ `org-templates/`) |
| git | `[include] path = ~/.dziman/profile/.gitconfig` | `.gitconfig`, `.gitconfig-apple*` |
| tmux | `source-file -q ~/.dziman/profile/.tmux.conf` | `.tmux.conf` |
| omp | the `omp` shell function adds `--config <profile config>`; the overlay outranks the shared file, so change models in the profile overlay. `/model` and preset saves inside omp write `modelRoles` into the shared `~/.omp/agent/config.yml`: they last one session and leave `config status` dirty; revert them there | `.omp/agent/config.yml` (models, presets, services), `.omp/agent/models.yml` |
| ssh, pip, maven, gradle, navi, omp extras | whole files: linked into `$HOME` by `config profile` (see below) | `.ssh/config`, `.pip/pip.conf`, `.m2/settings.xml`, `.gradle/init.d/`, `.navi/cheats/apple.src.cheat`, `.omp/agent/{lsp.json,bin/,rules/zmx-session-safety.md}` |
| zsh prompt | `right-prompt` calls `profile-prompt-status` when the profile defines it | `.zsh-dziman/910_prompt.zsh` |
| Claude Code | `~/.claude/CLAUDE.md` ends with `@~/.dziman/profile/.claude/CLAUDE.md`; settings, the forge skill and the apple-only files are linked into `~/.claude/` by `config profile` (no layering in Claude Code) | `.claude/CLAUDE.md`, `.claude/settings.json`, `.claude/skills/dz-git-forge-workflow/` (main's `.claude` is a symlink to ai's); apple only: `.claude/statusline-command.sh`, `.claude/dz-session-recap.local.md`, `.claude/apple/` |
| work-machine data | linked the same way | `Local/AS/`, `src/apple/` (module lists) |
| package lists | `list-installed` writes this machine's snapshot into its profile; nothing reads them | `.dziman/brew.packages`, `.dziman/brew.cask.packages`, `.dziman/brew.taps`, `.dziman/vs.code.extensions` |

Two kinds of profile file:

- **Parts** that a shared file includes through `~/.dziman/profile/...` (zsh
  extensions, emacs configs, `.gitconfig`, `.tmux.conf`, omp overlay, Claude
  rules). Nothing links them; an absent part is a no-op.
- **Whole files** that must appear at their `$HOME` path (`~/.ssh/config`,
  `~/.claude/settings.json`, `~/Local/AS/...`). `profiles/<p>/links` lists
  them, one `$HOME`-relative file or directory per line. `config profile <p>`
  makes one symlink per file, through `~/.dziman/profile/...` so every link is
  the same on every machine, removes the previous profile's links first, and
  lists the link paths in the bare repo's `info/exclude` so `config status`
  stays clean. A directory entry links each file inside it, so untracked
  neighbours in `$HOME` are untouched; a file added to the directory on the
  profile side is linked on the next `config profile <p>`, one that appears in
  `$HOME` needs `adopt`. A real file already at a link's path is kept and
  reported (exit 1), as is a listed file missing from the profile.

`config profile adopt ~/.foo/bar.conf` does the move for you: into
`profiles/<active>/.foo/bar.conf`, a line in `links`, the link. A file that is
tracked (shared by every machine) is moved with `git mv` after a y/N prompt,
since the other profiles lose it; when only part of it differs, keep it shared
and put the difference in a profile part instead. `unadopt` moves it back and leaves it
tracked at the `$HOME` path. Both refuse a path that runs through a symlinked
profile directory (main's `.claude` is ai's): adopt such a file in ai.

A tool that replaces a file by rename turns the link back into a real file;
`config profile status` shows it as `shadowed`. Recover with

```
diff ~/.foo/bar.conf ~/.dziman/profile/.foo/bar.conf
mv ~/.foo/bar.conf ~/.dziman/profile/.foo/bar.conf   # keep the newer one
config profile <p>
```

## Add a profile

```
mkdir ~/.dziman/profiles/<name>
echo '# <name> profile — <description>' > ~/.dziman/profiles/<name>/README.md
config profile <name>
```

Then add parts under the same relative paths as in `$HOME`, and `config profile
adopt` the whole files that belong to it.

## Rollout on a machine

One command, run from `$HOME`, after fetching the branch from your remote
(`config remote -v` tells its name; `origin` below):

```
config fetch origin unified
config show origin/unified:.local/bin/git-profile > /tmp/git-profile   # the script is not on the old branch yet
sh /tmp/git-profile rollout origin/unified <name>
exec zsh
```

What `rollout` does, in order:

1. Refuses unless run from `$HOME`, and while `config status` shows modified
   tracked files (commit or discard them; Claude Code edits
   `~/.claude/settings.json` itself, so on the apple machine diff the live one
   against the profile's first).
2. Moves every untracked file that the branch tracks to
   `~/.dziman/rollout-backup/<time>/<same path>` (git would refuse to overwrite
   it, and `-f` would lose the machine's copy: `~/.ssh/config`, an edited omp
   theme, the cmux config).
3. Switches the dotfiles checkout to the branch.
4. Activates the profile; a real file sitting at a link path is backed up the
   same way instead of blocking.
5. Removes `~/.zcompdump` and directories the old branch left empty, then
   prints one `diff` line per backup so you can compare and carry over what
   matters. Delete the backup directory when done.

Afterwards `config status` is clean and `config profile status` shows every
link `ok`. Files that were tracked on the old branch and are not on `unified`
disappear from `$HOME` on switch (the apple-only ones among them come back as
links). The zsh extensions move from `~/.dziman-zsh/` to `~/.zsh-dziman/`; the
old directory stays only if untracked files linger in it:

- from `main-computer`: `.dziman-zsh/.editorconfig`, `.dziman-zsh/578_swift.enabled.zsh`
- from `work-computer`: `.dziman-zsh/550_aws.enabled.zsh`, `.dziman-zsh/577_js.enabled.zsh`,
  `.dziman/list-installed.sh`, `.pi/agent/settings.json`, `.emacs-dziman/configs/dz-config-helm.el`,
  `.local/share/navi/apple.src.cheat`; moved into the apple profile:
  `.gitconfig-apple*`, `.gradle/init.d/*`, `journal-apple-meeting.tmpl.org`
- from `mirror/ai-dev`: Kilo (`.config/kilo`, `.kilo`), `.codex/config.toml`,
  `.agents/*`, `.dziman-zsh/.editorconfig`, `.dziman-zsh/578_swift.enabled.zsh`

On the apple machine, iTerm keeps the shared plist; the work-only iTerm profiles
("Dziman Claude", "Emacs fonts") and triggers were not carried over.
