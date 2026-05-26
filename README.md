# Marcello's dotfiles

Snapshot of my actual setup: **zsh + oh-my-zsh** for the shell,
**Starship** for the prompt, **Ghostty** for the terminal,
**MesloLGS Nerd Font**, and a curated `Brewfile` for everything else.

This repo is not a framework — it's a backup. The files here are verbatim
copies of what's in `$HOME`, symlinked back at install time so edits flow
both directions.

## Install on a fresh Mac

```bash
git clone https://github.com/marcelloromanelli/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh all
```

That installs Homebrew + everything in [`Brewfile`](Brewfile), then symlinks
the dotfiles into `$HOME`. Existing files in `$HOME` are moved to
`~/.dotfiles-backup/<timestamp>/` before being replaced — nothing is
destroyed.

## Layout

```
~/dotfiles
├── .zshrc                       → ~/.zshrc
├── starship.toml                → ~/.config/starship.toml
├── ghostty.config               → ~/.config/ghostty/config
├── .gitconfig                   → ~/.gitconfig
├── .gitignore                   → ~/.gitignore (global)
├── .gitattributes               → ~/.gitattributes
├── .editorconfig                → ~/.editorconfig
├── Brewfile                     `brew bundle --file=Brewfile`
├── Brewfile.work.example        copy to Brewfile.work for work brews (gitignored)
├── macos/defaults.sh            opinionated `defaults write` for new Macs
├── install.sh                   symlink installer + brew runner
├── .agents/                     personal AI agent assets (skills, prompts, hooks)
└── gitconfig.local.example      template for ~/.gitconfig.local (untracked)
```

## install.sh

```
./install.sh               # link everything (default)
./install.sh brew          # install Homebrew + run brew bundle (+ .local + .work)
./install.sh macos         # apply macos/defaults.sh (asks first)
./install.sh launchd       # install the daily autopull LaunchAgent
./install.sh update        # git pull --ff-only + relink
./install.sh unlink        # remove every symlink we created
./install.sh doctor        # verify the install
./install.sh all           # brew + link + launchd + doctor
```

## Cross-laptop sync

Edits to `~/.zshrc` (et al.) are edits to the repo file — they're symlinks.
Once a change is good:

```bash
dots sync "tighten history opts"        # commit any local changes, rebase-pull, push
```

The other laptop picks it up automatically via the LaunchAgent (runs daily at
12:00 + on login). Manual pull any time:

```bash
dots pull                               # safe fetch + ff-only merge
```

### `dots` helper

```
dots                  short status (branch, ahead/behind, dirty count)
dots cd               cd into the repo
dots edit [file]      open the repo (or a specific file) in $EDITOR
dots diff             git diff inside the repo
dots log              recent commits
dots sync "msg"       commit + rebase-pull + push
dots pull             safe non-destructive pull
dots push             git push
dots install          rerun install.sh link
dots doctor           rerun install.sh doctor
dots autopull-log     tail the LaunchAgent log
```

### Conflict handling

The auto-pull script (`scripts/autopull.sh`) is intentionally conservative:

| State on this laptop                       | Auto-pull does       |
| ------------------------------------------ | -------------------- |
| working tree dirty                         | nothing              |
| local has unpushed commits                 | nothing              |
| remote unchanged                           | nothing              |
| remote strictly ahead (fast-forward)       | `git merge --ff-only`|
| diverged (both sides have new commits)     | log warning, nothing |
| offline / fetch failed                     | silent no-op         |

If you see the `⚠ dotfiles dirty` message on shell startup, run
`dots sync "msg"` to ship. If you see "DIVERGED" in the log, run `dots sync`
which rebases your local commits on top of the remote.

## Per-machine overrides (untracked)

| Path                       | Purpose                                          |
| -------------------------- | ------------------------------------------------ |
| `~/.gitconfig.local`       | `[user]` name/email + signing key                |
| `~/.extra`                 | Secrets, env vars (sourced by `.zshrc`)          |
| `Brewfile.local` (in repo) | Per-machine brews (e.g. Docker on one laptop)    |
| `Brewfile.work` (in repo)  | Work-only brews (e.g. private SSH-only taps)    |

### `~/.extra` via 1Password (recommended)

`extra.tpl` is a committed template with `op://` references. When you run
`./install.sh link`, the installer:

1. If `op` (1Password CLI) is installed and signed in → runs `op inject` to
   materialize `~/.extra` with resolved secrets.
2. Else → copies `extra.tpl` to `~/.extra` literally; you run
   `op inject -i extra.tpl -o ~/.extra` manually after `op signin`.

This means each laptop pulls secrets fresh from the same 1Password vault —
no manual copying.

## Pre-commit hook

`.githooks/pre-commit` runs `zsh -n` + `bash -n` + Brewfile lint +
basic secret detection on every commit. Activated automatically when you run
`./install.sh link` (sets `core.hooksPath = .githooks` for this repo only).
Bypass with `git commit --no-verify` if needed.

## Identity (untracked)

Your `name` / `email` live in `~/.gitconfig.local`, which is **not** tracked.
The first time you run `./install.sh`, it seeds that file from
[`gitconfig.local.example`](gitconfig.local.example). Edit afterwards.
`~/.gitconfig` includes it automatically.

## Work brews (private tap)

The GetYourGuide tap (`getyourguide/dev`) is SSH-only. To keep the public
Brewfile installable for anyone, work-specific brews live in
`Brewfile.work` (gitignored). To enable:

```bash
cp Brewfile.work.example Brewfile.work
./install.sh brew    # picks up both files automatically
```

## .agents/

This is the version-controlled home for my personal AI agent assets — skills,
prompts, rules, hooks, MCP configs. The directory is not auto-linked into any
specific tool because each tool wants things in a different place
(`~/.claude/skills/`, `~/.cursor/skills-cursor/`, etc.); see
[.agents/README.md](.agents/README.md) for the per-tool symlink snippets.

## Updating

Installs are symlinks, so `git pull` in `~/dotfiles` updates your live config
instantly. Reload the shell with `exec zsh -l`.

## License

MIT — see [LICENSE-MIT.txt](LICENSE-MIT.txt).
