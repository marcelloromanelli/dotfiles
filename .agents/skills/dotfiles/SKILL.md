---
name: dotfiles
description: Edit, commit, and sync Marcello's personal dotfiles repo (marcelloromanelli/dotfiles, cloned at ~/projects/dotfiles and symlinked into $HOME). Use when modifying .zshrc, .gitconfig, starship.toml, ghostty.config, Brewfile, install.sh, the macOS defaults script, or any file in the repo; when adding a Homebrew package, a global git alias, or a personal secret; when syncing changes between his two laptops; or when debugging shell startup, the pre-commit hook, or the autopull LaunchAgent. Enforces the `dots sync` workflow, the symlink convention, and the per-machine override pattern.
---

# Dotfiles

Marcello's dotfiles live at `~/projects/dotfiles` and are wired into `$HOME`
via symlinks created by `./install.sh link`. This skill documents the
conventions an agent must follow to make safe, correct changes.

## The repo at a glance

```
~/projects/dotfiles
├── .zshrc                  → ~/.zshrc                       (zsh entry point)
├── .gitconfig              → ~/.gitconfig
├── .gitignore              → ~/.gitignore                   (also serves as global)
├── .gitattributes          → ~/.gitattributes
├── .editorconfig           → ~/.editorconfig
├── starship.toml           → ~/.config/starship.toml
├── ghostty.config          → ~/.config/ghostty/config
├── Brewfile                shared brews (installed everywhere)
├── Brewfile.work           private SSH-only tap (gitignored)
├── Brewfile.local          per-machine brews (gitignored)
├── extra.tpl               template for ~/.extra (op:// references)
├── gitconfig.local.example template for ~/.gitconfig.local (identity)
├── install.sh              symlink installer + brew/launchd/doctor/update subcommands
├── macos/defaults.sh       curated `defaults write` script (181 lines, opt-in)
├── scripts/autopull.sh     safe non-interactive auto-pull, called by LaunchAgent
├── launchd/                LaunchAgent plist template
├── .githooks/pre-commit    syntax + Brewfile + secret-leak checks
└── .agents/skills/         skills consumed by Cursor + Claude (you are here)
```

## Rule 1: Symlinks mean one source of truth

Editing `~/.zshrc` IS editing `~/projects/dotfiles/.zshrc` — same inode. **Never
copy a file from the repo into `$HOME` or vice versa.** Always edit the file in
place (either path works).

To confirm a file is linked: `readlink ~/.zshrc` should print the absolute path
inside the repo.

## Rule 2: Use `dots`, not raw git

A `dots` function is defined in `.zshrc` and available in every shell. Prefer
it over `cd ~/projects/dotfiles && git ...` to avoid forgetting steps.

```
dots                 short status (no network — instant)
dots sync "msg"      commit any local changes, rebase-pull, push  ← the main one
dots pull            safe fetch + ff-only merge (uses scripts/autopull.sh)
dots push            git push
dots edit [file]     open the repo (or a specific file) in $EDITOR
dots diff [args]     git diff inside the repo
dots log             pretty `git log -20`
dots install         rerun `install.sh link`
dots doctor          rerun `install.sh doctor`
dots autopull-log    tail ~/Library/Logs/dotfiles-autopull.log
```

When the user says "deploy this" or "ship it" or "push these dotfile changes",
the right command is `dots sync "<descriptive message>"`.

## Rule 3: The pre-commit hook is canon

`.githooks/pre-commit` is active in this repo (`core.hooksPath = .githooks`).
It runs on every commit and will block:

- `zsh -n` failures on `.zshrc` and `extra.tpl`
- `bash -n` failures on `install.sh`, `macos/defaults.sh`, `scripts/*.sh`,
  `.githooks/*`
- Brewfile parse errors
- Obvious secret leaks (regex: `AKIA[0-9A-Z]{16}`, `ghp_[A-Za-z0-9]{36}`,
  `gho_[A-Za-z0-9]{36}`, `ntn_[A-Za-z0-9]+`)

**Never use `--no-verify` unless the user explicitly approves.** If the hook
blocks you, fix the root cause.

## Common workflows

### Add or modify a zsh alias / function / env var

1. Edit `.zshrc` (anywhere in the repo, or via `~/.zshrc`).
2. Verify it loads: `zsh -n .zshrc && zsh -i -c 'type my_new_alias'`.
3. `dots sync "add my_new_alias for X"`.

The user's other laptop picks it up within 24h via the autopull LaunchAgent.

### Add a Homebrew package

Decision tree:

| Used by | File to edit |
| --- | --- |
| Both laptops, public formula or cask | `Brewfile` |
| One laptop only (e.g. Docker on the work Mac, not personal) | `Brewfile.local` (gitignored) |
| GetYourGuide / private SSH-only tap | `Brewfile.work` (gitignored) |

Adding to `Brewfile`:

```
brew "the-package"      # short comment on why
# or
cask "the-app"
# or
mas "App Store App", id: 1234567890     # find ID via:  mas search "name"
# or
vscode "publisher.extension"            # Cursor doesn't honor this; only add if you use VS Code
# or
npm "@scope/package"
```

Then install: `brew bundle --file=Brewfile` (or `dots install` for the full
loop). Commit with `dots sync "add <package>: <why>"`.

### Add a personal secret

Secrets live in `~/.extra` (untracked, sourced by `.zshrc` early). The repo
ships `extra.tpl` with `op://` placeholders. To add a new secret:

1. Create the item in 1Password (Private vault), note its `op://Private/<Item>/<field>` path.
2. Add the line to `extra.tpl`:
   ```bash
   export MY_API_KEY="op://Private/MyService/credential"
   ```
3. Materialize on this machine:
   ```bash
   op signin    # if not already signed in
   op inject -i extra.tpl -o ~/.extra && chmod 600 ~/.extra
   ```
4. `dots sync "extra: add MY_API_KEY reference"` (the live `~/.extra` is gitignored;
   only `extra.tpl` is committed).

Never put a literal secret in any tracked file — the pre-commit hook will
reject it.

### Add a starship module / change theme

Edit `starship.toml`. Test the change live by opening a new prompt (no reload
needed — starship reads the file every prompt). Commit with `dots sync`.

### Add a Ghostty option

Edit `ghostty.config`. Reload Ghostty: `⌘⇧,` in any Ghostty window, or quit +
reopen. Validate: `ghostty +validate-config`. Commit.

### Change a global git default (.gitconfig)

Edit `.gitconfig`. Identity (`user.name`, `user.email`, signing keys) does NOT
live here — it lives in `~/.gitconfig.local` (untracked). Behavioral defaults
like `pull.rebase`, `merge.conflictStyle`, aliases, etc. live in `.gitconfig`.

### Apply a new macOS default

Edit `macos/defaults.sh`. The script is opt-in (only runs on
`./install.sh macos`). Keep it curated — don't paste from random gists without
reading each line. Commit with `dots sync`.

### Track a new file (e.g. a new `~/.foorc`)

1. Place the file in the repo at `foorc` (or wherever makes sense).
2. Add an entry to the `LINKS` array in `install.sh`:
   ```bash
   "foorc                 .foorc"
   ```
3. Run `./install.sh link` to symlink it. Existing `~/.foorc` is backed up to
   `~/.dotfiles-backup/<timestamp>/`.
4. `dots sync "track ~/.foorc"`.

## Cross-laptop sync

| State on the other laptop | What the LaunchAgent does |
| --- | --- |
| Tree clean, remote ahead (ff-only) | Fast-forward merges silently. |
| Tree dirty | Skip; logs "skip: working tree dirty". |
| Local has unpushed commits | Skip. |
| Diverged | Skip; logs "DIVERGED — run 'dots sync'". |
| Offline / fetch fails | Skip silently. |

Schedule: daily at 12:00, plus once on login. Logs at
`~/Library/Logs/dotfiles-autopull.log`.

If divergence happens (both laptops edited the same lines), resolve with
`dots sync "<msg>"` which does `git pull --rebase --autostash` — this drops
into a 3-way merge with `zdiff3` conflict markers (showing the base) thanks to
`merge.conflictStyle = zdiff3` in `.gitconfig`.

## Per-machine vs shared

| What | Where | Tracked? |
| --- | --- | --- |
| `[user]` name + email + signing key | `~/.gitconfig.local` | No |
| Work env vars, AWS profile, API keys | `~/.extra` (sourced by `.zshrc`) | No |
| Per-machine brews | `Brewfile.local` | No |
| GetYourGuide private brews | `Brewfile.work` | No |
| Everything else | the repo | Yes |

If you find yourself adding a hostname-conditional in `.zshrc`, consider
whether that thing actually belongs in `~/.extra` instead.

## Debugging shell startup

Target: <250 ms steady-state, <2 s on first shell of the day.

```bash
/usr/bin/time -p zsh -i -c exit          # measure
zsh -i -x -c exit 2>&1 | head -50        # trace what's running
```

Common culprits:

- A new sync `eval "$(slow_command)"` in `.zshrc`. Always wrap in a
  presence check (`command -v X >/dev/null`) and cache when possible.
- Anything that talks to AWS/network at startup. Use the
  `_CA_CACHE_FILE` pattern in `extra.tpl` as a template for caching.
- Too many OMZ plugins. Audit `plugins=( ... )` in `.zshrc` periodically.

## Things never to do

- Don't use `git commit --no-verify` (skips the pre-commit hook) without
  explicit user permission. If the hook is wrong, fix it.
- Don't add tracked secrets. Always use `extra.tpl` + 1Password.
- Don't add a `cask` to `Brewfile` that uses a private/SSH-only tap. That
  belongs in `Brewfile.work`.
- Don't `rm -rf ~/.dotfiles-backup` without checking — that's where install.sh
  parks anything it overwrote.
- Don't push without running `dots sync` (which rebases first) or you'll fight
  the LaunchAgent's worldview on the other laptop.
- Don't `chsh` to a different shell without updating this repo to match — the
  whole point is that the repo IS the source of truth.

## Verification

Before considering a change "done":

1. `dots doctor` prints all green (`✓ ~/<file>` for each symlink + every
   binary in PATH).
2. `dots status` shows `dirty: 0 file(s)` and `ahead 0, behind 0`.
3. If the change touched `.zshrc`: open a fresh terminal and confirm the
   behavior (don't trust the current shell — it may have stale env).
