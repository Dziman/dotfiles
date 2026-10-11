<!-- apple profile: Claude Code rules for this machine only; imported by ~/.claude/CLAUDE.md -->

# Specs & plans

- **Location.** Save superpowers specs and implementation plans under `~/claude/superpowers/`, NOT in the project repo. One subdirectory per brainstorm→plan→implement session, named `YYYY-MM-DD-<topic>/`, holding `design.md` (spec), `plan.md` (implementation plan), and any implementation notes. This overrides the brainstorming/writing-plans default of `docs/superpowers/specs/`. Because these live outside the project, the skills' "commit design doc to project git" step does not apply.
- **Show inline (MANDATORY — do not skip).** A spec/plan is not "done" until its full content appears in the chat. The moment you Write or update a `design.md` / `plan.md` (or any spec/plan) under `~/claude/superpowers/`, your VERY NEXT message MUST paste that file's full content inline — before asking me to review, before invoking the next skill, before ending the turn. Saving to a file without showing its content inline in the same turn is a failure to be corrected immediately. Trigger = the Write/Edit tool touched a spec/plan file; there is no judgement call. Show it inline exactly once — don't then re-summarize the same content (Dyslexia Directive still applies).

# Commits

- **Title format.** Every commit message title MUST be `rdar://<id> - <title>` — the radar id, then space-hyphen-space, then a concise title.
- **Ask for the radar id first.** Before creating any commit, ask me for the `<id>`. If context suggests likely radar candidates (one named in the task, branch, or a related issue), propose them for me to pick from — but still confirm before committing.
- **Co-author the model.** Every commit message MUST end with a `Co-Authored-By:` trailer naming the AI model that actually wrote the change — one blank line before it, format `Co-Authored-By: <model display name> <drusak+ai@apple.com>` (e.g. `Co-Authored-By: Gemini 3.1 Pro Preview <drusak+ai@apple.com>`). The email is always exactly `drusak+ai@apple.com` — the `+ai` suffix marks the change as AI-authored; only the model display name varies, and it is the model name that says which tool wrote it. The committer stays the human, so committer and co-author differ by design. In subagent-driven work, name the model that produced *that specific* commit, which may differ per commit and from the coordinating model — e.g. a commit written by a Sonnet implementer is `Co-Authored-By: Claude Sonnet 3.5 <drusak+ai@apple.com>` even while a different model coordinates. **Exactly one** `Co-Authored-By` trailer per commit — the model that authored the substantive change. A trivial mechanical follow-up by another model (formatting, a lint/style conformance fix, a rename) does NOT earn a second trailer; keep the original author's.
- **Commit unsigned; sign at the end.** Do NOT sign while working — pass `--no-gpg-sign` on every `git commit` you make (`commit.gpgsign=true` is configured globally with `gpg.format=x509`, so you must opt out explicitly). Signing is a single batch step after ALL work and ALL commits are done, because history rewrites strip signatures anyway.
- **Signing gate.** When the whole task is complete, ask me whether I want to refine/add anything or proceed with signing the commits. Only on my go-ahead, sign the range in one pass (`git rebase -f --gpg-sign <base>`), then verify with `git log --format='%h %G?' <base>..HEAD` and confirm every line shows `G` (good) — not `N` (none). Signing happens BEFORE pushing. **Gotcha:** `git filter-branch` drops signatures entirely and `git commit-tree`/some rebase paths won't re-sign — after ANY later rewrite (trailer edits, amends across a range, rebases), re-sign and re-verify `%G?` for all affected commits.

# Personal marketplace skills (`personal-ai-marketplace`)

Reminders so these skills fire reliably at the right decision points. Each is also auto-loadable from its own description; these notes pin the guardrails. If a skill isn't installed, ask rather than improvising its behavior.

## Git branch naming

This account uses the `dz-git-conventions` skill for branch naming, reference resolution, and PR-branch shaping. Before creating, switching to, or pushing a branch — or opening a PR — load that skill and follow its rules. If the skill is not installed, ask before guessing a branch name.

## Code conventions

This account uses the `dz-code-conventions` skill. When about to author a new file, class, or public API — or when asked how code should be written, named, tested, logged, or configured — load that skill and follow its rules, deferring to any stricter project linter/formatter config. Do not apply it to trivial one-line edits or generated files.

## Subagent selection (`dz-dev-team`)

Before spinning up any subagent, check the agents defined in the `dz-dev-team` plugin — `backend-developer` (Java/merchandising, Pkl server-side), `frontend-developer` (TS/JS UI), `software-architect` (up-front design), `code-reviewer` (read-only review), `tech-writer` (docs) — and dispatch the matching one instead of a generic `general-purpose` agent when the task fits its remit. Fall back to `general-purpose` only when no `dz-dev-team` agent applies; if the plugin isn't installed, use `general-purpose`.

**Label the model in the agent name.** I need to see which model a subagent runs on. The `agent-model-suffix.sh` PreToolUse hook appends it to the agent `name` automatically (`code-review` → `code-review-sonnet`), so do NOT hand-write the suffix. Your part: pass the `model` parameter explicitly on every Agent call. Omit it and the hook labels the agent `-inherit`, which tells me only that the frontmatter or the parent session picked the model — so prefer an explicit `model` whenever the choice matters. The label mirrors what you pass, so pass a full model id (`claude-sonnet-5` → `-claudesonnet5`) when I need to see the exact version rather than a floating alias.

## Ship gate

Before opening a PR, run the `dz-ship-check` gate (format-check → lint → build → test). Do not open the PR on a NOT READY verdict unless I explicitly override. Run it on demand with `/dz-ship-check`.

## Pull requests

Use the `dz-pr` skill to open PRs. It shapes the branch (dz-git-conventions), runs the dz-ship-check gate, follows the repo's PR template (asking me for any missing fields), and previews before creating with `gh`. Don't open a PR on a NOT READY gate unless I override.

## Starting / finishing a task

Use the `dz-start-task` skill when I say I'm starting a new task or wrapping one up. It assesses repo + session state, asks via grouped questions (close-out / start-fresh), and runs the chosen steps in order — capturing learnings, recording decisions, committing (with a previewed message), gating, opening a PR, recapping, naming the next branch, pruning stale branches, and reminding me to /clear. Never commit, delete a branch, or open a PR without confirming; run captures before reminding me to clear.

## Session recaps

Use the `dz-session-recap` skill when I ask to wrap up, summarize, or write up the session as an HTML report or slide deck (`/dz-session-recap`). Review generated HTML before sharing externally — it can include my prompts, local file paths, and code.

## Decision journal

Use the `dz-decision-log` skill when I say to record/log a decision, write an ADR, or capture a trade-off. It appends a MADR-style org entry to my decision journal — draft from the conversation and prompt me for the gaps (options' pros/cons, consequences, status); never fabricate rationale.

## Learnings

Use the `dz-learnings` skill when I say to capture a learning, note a gotcha, save a recipe, or "TIL". It writes to both built-in memory and my org learnings journal, cross-referenced; confirm the draft with me before saving.

# Task tracking (kata)

kata is my personal task ledger for all repos: one project, `work`. Radar stays the source of truth for official work.

- **Access.** MCP first: the `kata` MCP tools are bound to `work` and act as `dziman+ai`. When an MCP tool is missing (e.g. `kata.close` did not surface), use the Bash `kata` CLI with `--as dziman+ai --project work`; it reaches the daemon from the sandbox.
- **When to write.** Offer follow-ups you find; file them only after I say OK. Update and close the issues you work on. No practice or test issues.
- **Before creating.** Search first; update an existing issue rather than file a duplicate. Give each create an idempotency key `<repo>-<slug>-<YYYY-MM-DD>` (`misc` outside any repo).
- **Labels.** Tag `repo:<dir-name>` (e.g. `repo:reas-merchandising`); several for cross-repo work, none outside any repo.
- **Radar.** Optional: metadata key `radar` = `<id>`. Usually unset.
- **Closing.** Close only verified work, with a substantive message and typed evidence (e.g. a commit sha). If the work is not done, add label `needs-review` and a comment instead.

