# Brewfile — install/sync with:  brew bundle --file=Brewfile
# Generated from `brew bundle dump` and curated. Edit and commit.

tap "stripe/stripe-cli"

# CLI tools.
brew "bat"                       # syntax-highlighted cat
brew "eza"                       # modern ls with icons + git status
brew "fd"                        # friendlier find
brew "fnm"                       # Fast Node Manager
brew "gh"                        # GitHub CLI
brew "libpq"                     # psql client (no postgres server conflict)
brew "mas"                       # Mac App Store CLI (sync /Brewfile / App Store)
brew "pyenv"                     # Python version manager
brew "render"                    # Render.com CLI
brew "ripgrep"                   # faster grep, respects .gitignore
brew "starship"                  # cross-shell prompt
brew "zsh-autosuggestions"
brew "zsh-completions"
brew "zsh-syntax-highlighting"

# Databases. NOTE: only one Postgres major is usually needed.
# Keep both only if you really run side-by-side; otherwise pick one.
brew "postgresql@17"
# brew "postgresql@14"           # legacy — uncomment only if a project still needs it

# Third-party services.
brew "stripe/stripe-cli/stripe"

# GUI apps.
cask "ghostty"                   # primary terminal (config: ./ghostty.config)
cask "claude-code"               # Anthropic Claude desktop / CLI
cask "font-meslo-lg-nerd-font"   # used by Ghostty + Starship glyphs

# Mac App Store apps. Requires `mas` (installed above) and being signed in.
mas "GarageBand",    id: 682658836
mas "Home Assistant", id: 1099568401
mas "iMovie",        id: 408981434
mas "Keynote",       id: 409183694
mas "Numbers",       id: 409203825
mas "Okta Verify",   id: 490179405
mas "Pages",         id: 409201541
mas "Slack",         id: 803453959
mas "WhatsApp",      id: 310633997

# VS Code / Cursor extensions.
vscode "anysphere.cursorpyright"
vscode "atlassian.atlascode"
vscode "catppuccin.catppuccin-vsc"
vscode "catppuccin.catppuccin-vsc-icons"
vscode "datadog.datadog-vscode"
vscode "ms-azuretools.vscode-containers"
vscode "ms-azuretools.vscode-docker"
vscode "ms-python.debugpy"
vscode "ms-python.python"
vscode "redhat.vscode-yaml"

# Global npm packages. NOTE: @anthropic-ai/claude-code is the CLI; the
# `claude-code` cask above is the GUI. Keep both only if you use both.
npm "@anthropic-ai/claude-code"
npm "@zendesk/zcli"
npm "pnpm"
