# Profile unification — design

Date: 2026-10-09
Status: implemented on branch `unified` (2026-10-10); see `.dziman/docs/profiles.md`

## Goal

One shared dotfiles configuration for all machines. Per-machine ("profile")
differences are explicit, small, and live next to the shared config instead of on
diverging branches. Improvements made on one machine reach every machine on the
next `config pull`.

## Current state (2026-10-09)

Remote `ssh://git@git.nasha.casa/ai-mirrors/settings.git`. Each machine checks the
repo out as a bare repo `~/.dziman-dotfiles` with work-tree `$HOME` (`config` alias).

| branch | tip | relation |
|---|---|---|
| `main-computer` | `34e8c40` | reference point |
| `mirror/ai-dev` | `a1ad581` | `main-computer` + 31 commits, 0 behind |
| `work-computer` | `c267430` | forked 2020-04-28 (`b84bfd3`); +131 / −230 commits |

Branch `main` (the remote default) is out of scope.

147 tracked paths across the three branches; 136 differ in at least one branch.
Full table: regenerated on demand by a scratch script (session scratchpad, not tracked).

Machine `m6m-ai-dev` additionally has two uncommitted edits in `~/.dziman-dotfiles`
(`ccstatusline` path → `~`, omp theme → zenburn) to fold in.

## Decisions taken

- Shared base is seeded from `main-computer`. `mirror/ai-dev` is merged in
  first, `work-computer` second (see *Merge sequence*).
- The unit of decision is a **feature**: one logical change, possibly spanning
  several files, reconstructed from commits and content. Not a file, not a hunk.
  Independent features from different branches are taken by default and listed
  for veto; features that contradict each other are asked.
- A ported feature is **re-implemented against the unified layout**, not
  patch-applied: it may land in files that did not exist on its source branch
  (e.g. a Helm-era tweak expressed in the Vertico config).
- Work order: **other apps → emacs → zsh → AI**.
- Secrets stay as they are; a dedicated pass follows unification.
- Existing branches are not touched. Work happens on **new** branches.
- Pre-existing problems unrelated to unification are out of scope.

## Profile mechanism

Three profiles: `main`, `apple`, `ai`. Adding one later = one directory + one symlink.
A profile directory mirrors the `$HOME` layout: `profiles/apple/.gitconfig`,
`profiles/ai/.dziman-zsh/*.zsh`, `profiles/apple/.emacs-dziman/configs/*.el`.

### The switch

One untracked symlink per machine selects the profile:

```
~/.dziman/profile  →  ~/.dziman/profiles/<name>
```

Created by `config-profile <name>` (a script in `.local/bin`). Every tracked file
refers to `~/.dziman/profile/…`, so tracked content is identical on all machines.
`DZIMAN_PROFILE` is exported by zsh from the symlink target for scripts that need
the name.

### Tiers of per-profile difference

| tier | when | mechanism |
|---|---|---|
| 0 | difference not needed | unify: one shared file, no profile part |
| 1 | app can include/source | shared file ends with an include of `~/.dziman/profile/<same path as in $HOME>`; missing file is a no-op |
| 2 | app cannot include | shared file + git clean/smudge filter: smudge applies `profiles/<p>/<file>.patch` on checkout, clean strips it on commit |
| 3 | file exists on one profile only | tracked symlink `path → .dziman/profile/<file>` (dangling elsewhere), or sparse-checkout exclude for whole directories |

Tier 1 covers zsh (`~/.dziman/profile/.dziman-zsh/*.zsh` sourced last),
emacs (`dz-config-profile.el` loading `~/.dziman/profile/.emacs-dziman/configs/*.el`),
git (`[include] path = ~/.dziman/profile/.gitconfig`), tmux (`source-file -q`),
omp (`--config ~/.dziman/profile/.omp/agent/config.yml` added by a shell function).

Tier 2 was not needed: iTerm's plist and VS Code `settings.json` ended up fully
shared.

Tier 3 covers `.ssh/config`, `.m2/settings.xml`, `.gradle/init.d`, `.pip/pip.conf`,
navi's Apple cheat and omp's `models.yml` (tracked symlinks into the profile), and
`Local/AS/**`, `src/apple/**`, omp's Java LSP files, `.pi/` (sparse-checkout, patterns
in `profiles/<p>/sparse`).

Tier assignment per file is decided during the area passes, never in advance.

### Layout

```
~/.dziman/profile/            untracked symlink (the switch)
~/.dziman/profiles/main/      tracked
~/.dziman/profiles/apple/     tracked
~/.dziman/profiles/ai/        tracked
~/.dziman/profiles/<p>/...    profile parts, same relative paths as in $HOME
```

## Merge sequence

Two stages, in this order, because `mirror/ai-dev` is a clean descendant of
`main-computer` with well-structured commits, while `work-computer` is six years
diverged with mixed commits.

**Stage 1 — fold `mirror/ai-dev` into `unified`.**
`unified` starts at `34e8c40`. The 31 ai-dev commits are replayed one by one
(cherry-pick), oldest first. Before each lands, the user gets a review: subject,
files, a one-line summary per hunk group, and a proposal (keep / move to
`profiles/ai/` / drop) per group. The user may accept, amend (drop or relocate
any part), or drop the whole commit. Amended commits keep the original subject
and gain a body line naming the source hash. The profile mechanism
(`config-profile`, switch symlink, include hooks) is introduced here, at the
first commit that needs it. The two uncommitted edits on this machine are
committed at the end of the stage. Result: `unified` ⊇ the accepted parts of
ai-dev, with ai-specific residue in `profiles/ai/`.

**Stage 2 — port `work-computer` onto that result**, in four area passes
(below). Work's history is not replayed; features are reconstructed from its
diff against `unified` and re-implemented. Work-only residue goes to
`profiles/work/`.

`main-computer` needs no porting: it is the seed. Its profile dir starts empty.

## Area passes (stage 2)

Each pass follows the same protocol:

1. **Difference report** — a list of features found in the area. Per feature:
   one-line description, origin branch(es), files it touches there, files it
   would touch in `unified`, status *independent* or *conflicts with <feature>*,
   proposed tier and owner (common / profile / drop). Leftover differences that form no feature (reformat,
   noise) are listed once at the end as *drop*.
2. **Decisions** — the user resolves every conflict and may veto any
   independent feature or reassign its owner. Questions are batched per area.
3. **Port** — re-implement each accepted feature on the working branch. One
   commit per feature, subject prefixed with the area tag already used in this
   repo (`[emacs]`, `[zsh]`, …), body naming the source commit(s).
4. **Validate** — see below.

Order and scope:

| # | area | paths |
|---|---|---|
| 1 | other apps | `.gitconfig*`, `.gitignore`, `.tmux.conf`, `.iterm/`, `.editorconfig`, `.ripgreprc`, `.navi/`, `.config/cmux`, ghostty, VS Code settings, brew lists, `.dziman/*.sh`, `.gradle`, `.m2`, `.pip`, `.ssh`, `Local/`, `src/apple` |
| 2 | emacs | `.emacs`, `.emacs.d/early-init.el`, `.emacs-dziman/**` |
| 3 | zsh | `.zshrc`, `.dziman-zsh/**` |
| 4 | AI | `.claude/**`, `.codex/`, `.omp/**`, `.pi/`, `.kilo/`, `.config/kilo`, `.config/ccstatusline`, `.agents/`, `888_ai.enabled.zsh`, `.local/bin/claude-editor` |

## Branches

- `unified` — the new shared base. Starts at `34e8c40` (`main-computer`).
- No existing branch is rewritten or deleted. Backup tags are still created
  before anything is pushed: `backup/<branch>-2026-10-09` for all three.
- Pushes only on explicit request.
- Later (separate step, after all machines run `unified`): retire
  `main-computer`, `work-computer`, `mirror/ai-dev`.

## Validation

On this machine (`ai` profile):

- `zsh -i -c exit` wall time ≤ the current `mirror/ai-dev` figure (~0.09 s).
- `emacs --batch -l ~/.emacs` loads without error; interactive startup time ≤
  current (~0.24 s) measured with `emacs-init-time`.
- `config status` clean after `config-profile ai` (filters and symlinks
  round-trip).

For `apple` and `main` profiles only static checks are possible here: `zsh -n` on
every sourced file, emacs byte-compile of profile files, `git check-attr` / filter
dry-run. Real verification happens on those machines after rollout.

## Rollout (per machine, after review)

```
config fetch
config switch unified
config-profile <name>        # symlink, filters, optional sparse-checkout
```

Files tracked only on the old branch disappear from `$HOME` on switch; the
difference reports list such files so nothing is lost silently.

## Out of scope

- Secrets handling (next pass).
- Pre-existing issues noted during exploration:
  plaintext OpenRouter key in `mirror/ai-dev` history; hardcoded
  `/Users/ai-dev` in `ccstatusline`; orphaned `dz-config-helm.el` on work;
  tabs→spaces reformat noise in work's `.gitconfig`; ineffective
  `~/.dziman-dotfiles` line in `.gitignore`.
- Branch `main` and anything only on it.
