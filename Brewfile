# Brewfile — install/sync with:  brew bundle --file=Brewfile
# Generated from `brew bundle dump` and curated. Edit and commit.

tap "stripe/stripe-cli"

# CLI tools.
brew "bat"                       # syntax-highlighted cat
brew "eza"                       # modern ls with icons + git status
brew "fd"                        # friendlier find
brew "fnm"                       # Fast Node Manager
brew "gh"                        # GitHub CLI
brew "git-delta"                 # syntax-highlighted git diffs (used by .gitconfig)
brew "libpq"                     # psql client (no postgres server conflict)
brew "mas"                       # Mac App Store CLI (sync /Brewfile / App Store)
brew "pyenv"                     # Python version manager
brew "render"                    # Render.com CLI
brew "ripgrep"                   # faster grep, respects .gitignore
brew "starship"                  # cross-shell prompt
brew "zsh-autosuggestions"
brew "zsh-completions"
brew "zsh-syntax-highlighting"

# Databases.
brew "postgresql@17"

# Third-party services.
brew "stripe/stripe-cli/stripe"

# GUI apps.
cask "ghostty"                   # primary terminal (config: ./ghostty.config)
cask "font-meslo-lg-nerd-font"   # used by Ghostty + Starship glyphs
cask "1password-cli"             # `op` CLI — used for op-ssh-sign + secret injection

# Mac App Store apps. Requires `mas` (installed above) and being signed in.
mas "GarageBand",     id: 682658836
mas "Home Assistant", id: 1099568401
mas "iMovie",         id: 408981434
mas "Keynote",        id: 409183694
mas "Numbers",        id: 409203825
mas "Okta Verify",    id: 490179405
mas "Pages",          id: 409201541
mas "Slack",          id: 803453959
mas "WhatsApp",       id: 310633997

# Global npm packages (`brew bundle` runs `npm install -g`).
npm "@anthropic-ai/claude-code"  # `claude` CLI
npm "@zendesk/zcli"
npm "pnpm"
