---
name: onboard-new-mac
description: Bootstrap a fresh Mac to match Marcello's working setup by cloning the marcelloromanelli/dotfiles repo and running its installer. Use when setting up a new Mac, a second laptop, a reset machine, or when the user says "I'm setting up a new laptop", "fresh install", "new machine setup", or "onboard". Covers prerequisites (Xcode CLT, Homebrew, gh, 1Password sign-in) and the exact `./install.sh` invocation order, plus the post-install checklist that needs human action.
---

# Onboard a new Mac

End-to-end bootstrap of a fresh (or reset) Mac to match Marcello's working
setup. Assumes macOS Tahoe or newer on Apple Silicon. Should take ~15 minutes
on a fast connection, mostly waiting on `brew bundle`.

## Step 1: Prereqs

These cannot be installed via dotfiles — they bootstrap the dotfiles install.

```bash
# 1.1 Xcode Command Line Tools (provides git, clang, make).
xcode-select --install

# 1.2 Sign into iCloud + App Store (for `mas` to install GarageBand/Slack/etc).
#     System Settings → Apple Account.

# 1.3 Install 1Password 8 (App Store). Enable the SSH agent:
#     1Password → Settings → Developer → Use the SSH agent.
#     Add the user's ed25519 key to 1Password.

# 1.4 Open GitHub in a browser and sign in as `marcelloromanelli`.
```

## Step 2: Clone the repo via SSH

The repo's `Brewfile` and the `dots` helper assume the repo lives at
`~/projects/dotfiles`. Use SSH (1Password's agent will handle auth):

```bash
mkdir -p ~/projects
cd ~/projects
git clone git@github.com:marcelloromanelli/dotfiles.git
cd dotfiles
```

If SSH fails: the user hasn't completed 1Password SSH-agent setup. Stop and
fix that — don't fall back to HTTPS, that creates a credential-cache mess.

## Step 3: Run the full install

```bash
./install.sh all
```

This runs, in order:

1. **brew**: installs Homebrew (if missing), then `brew bundle --file=Brewfile`
   for all 33+ shared deps. Slow: 5–15 min. Also runs `Brewfile.local` and
   `Brewfile.work` if present.
2. **link**: symlinks `.zshrc`, `.gitconfig`, `.gitignore`, `.gitattributes`,
   `.editorconfig`, `starship.toml`, `ghostty.config` into `$HOME` (backs up
   anything existing into `~/.dotfiles-backup/<timestamp>/`). Seeds
   `~/.gitconfig.local` from `gitconfig.local.example` and `~/.extra` from
   `extra.tpl`. Activates `.githooks/pre-commit`. Symlinks
   `.agents/skills/*` into `~/.cursor/skills/` and `~/.claude/skills/`.
3. **launchd**: installs the autopull LaunchAgent. Runs daily at noon + on login.
4. **doctor**: prints a green checklist if everything is wired up.

## Step 4: Identity (required, can't be skipped)

`~/.gitconfig.local` was seeded with placeholders. Edit it:

```bash
${EDITOR:-vim} ~/.gitconfig.local
```

Set:

```ini
[user]
    name = marcelloromanelli
    email = marcello.romanelli@getyourguide.com
    signingkey = ssh-ed25519 AAAA...           # paste from 1Password

[gpg]
    format = ssh
[gpg "ssh"]
    program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign

[commit]
    gpgsign = true
```

Verify: `git -C ~/projects/dotfiles log -1 --show-signature` should say
"Good signature" once the user makes a signed commit.

## Step 5: Secrets via 1Password CLI

```bash
op signin                                # interactive — pick the right account
op inject -i extra.tpl -o ~/.extra       # materialize ~/.extra from the template
chmod 600 ~/.extra
```

Confirm: `zsh -i -c 'echo $DATABRICKS_HOST'` should print the URL from 1Password.

Note: the template references items like `op://Private/GYG/databricks_host`.
These must exist in the user's Private vault. If they don't, `op inject` will
fail loudly. The list of required items lives at the top of `extra.tpl`.

## Step 6: macOS defaults (optional)

```bash
./install.sh macos
```

Applies the curated 181-line `macos/defaults.sh` (keyboard repeat, screenshots
to `~/Screenshots`, Finder hidden files, Dock autohide, no `.DS_Store` on
network drives, App Store auto-updates, etc.). Some changes require a logout
to take full effect.

## Step 7: Set Ghostty as the default terminal

`Brewfile` installs Ghostty as a cask. Open it once (Spotlight: `⌘Space →
Ghostty`), then drag the icon to the Dock. The `ghostty.config` is already
linked, so font/theme/keybinds work on first launch.

Optional: System Settings → Login Items → add Ghostty so it's always running.

## Step 8: Switch to Homebrew zsh (optional)

macOS ships an old zsh. To use the Homebrew one (installed by `Brewfile`):

```bash
echo "$(brew --prefix)/bin/zsh" | sudo tee -a /etc/shells
chsh -s "$(brew --prefix)/bin/zsh"
```

Log out and back in for it to take effect.

## Step 9: Cursor sign-in + skill activation

```bash
# Install via Brewfile if not already (cask "cursor" is NOT in the Brewfile
# by default — installed by hand from cursor.com).
```

After signing into Cursor, this skill (and the `dotfiles` one) should already
be live at `~/.cursor/skills/dotfiles/` and `~/.cursor/skills/onboard-new-mac/`
because `install.sh link` symlinked them. Verify with `ls -la ~/.cursor/skills/`.

## Verification checklist

Run each. All should pass:

```bash
./install.sh doctor                       # green across the board
dots status                               # ahead 0, behind 0, dirty 0
/usr/bin/time -p zsh -i -c exit           # < 0.5s on second run
git -C ~/projects/dotfiles log -1 --show-signature   # signed
launchctl print "gui/$UID/com.marcello.dotfiles-autopull"   # state = waiting
cat ~/Library/Logs/dotfiles-autopull.log  # shows it ran on login
```

## Common stumbles

| Symptom | Fix |
| --- | --- |
| `./install.sh brew` hangs forever | `mas` requires App Store sign-in. Open App Store and sign in, then re-run. |
| `op inject` fails with "no such item" | The 1Password item referenced in `extra.tpl` doesn't exist in this user's vault. Create it or remove the line. |
| First shell takes 30+ seconds | Probably an unexpired AWS SSO session OR no SSO session at all. Run `aws sso login --profile production/developer`, then `ca-refresh`. |
| LaunchAgent never runs | `launchctl print gui/$UID/com.marcello.dotfiles-autopull` to inspect. If `state = not loaded`, run `./install.sh launchd` again. |
| `git push` asks for password | SSH agent isn't reachable. Verify 1Password → Developer → SSH agent is enabled and the key is in the vault. |

## When NOT to use this skill

- Existing setup that just needs an update: use the `dotfiles` skill instead.
  `./install.sh all` will work but `./install.sh update` is cheaper.
- The user is asking about a tool that isn't in the Brewfile (e.g. Lightroom).
  Add it to `Brewfile.local` first, don't do a one-off `brew install`.
