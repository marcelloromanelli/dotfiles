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
./install.sh brew          # install Homebrew + run brew bundle
./install.sh macos         # apply macos/defaults.sh (asks first)
./install.sh unlink        # remove every symlink we created
./install.sh doctor        # verify the install
./install.sh all           # brew + link + doctor
```

## Identity (untracked)

Your `name` / `email` live in `~/.gitconfig.local`, which is **not** tracked.
The first time you run `./install.sh`, it seeds that file from
[`gitconfig.local.example`](gitconfig.local.example). Edit afterwards:

```ini
[user]
    name = Marcello Romanelli
    email = you@example.com
```

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
