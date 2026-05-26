# =============================================================================
# GetYourGuide environment
# =============================================================================
# Note: these AWS CodeArtifact calls run on EVERY shell start. If they ever
# slow your shell down, wrap them in a lazy function (ask Cursor).
export POETRY_HTTP_BASIC_CODEARTIFACT_USERNAME=aws
export POETRY_HTTP_BASIC_CODEARTIFACT_PASSWORD=$(aws codeartifact get-authorization-token --profile production/developer --domain getyourguide --domain-owner 130607246975 --query authorizationToken --output text)
export CODEARTIFACT_AUTH_TOKEN=$(aws codeartifact get-authorization-token --profile production/developer --domain getyourguide --domain-owner 130607246975 --query authorizationToken --output text)
export MLFLOW_TRACKING_URI=databricks
export DATABRICKS_HOST=https://dbc-d10db17d-b6c4.cloud.databricks.com/

# =============================================================================
# Homebrew (needed early so brew --prefix works for the rest of this file)
# =============================================================================
eval "$(/opt/homebrew/bin/brew shellenv)"

# =============================================================================
# Oh My Zsh
# =============================================================================
export ZSH="$HOME/.oh-my-zsh"

# Theme is set to empty because we use Starship for the prompt (see bottom)
ZSH_THEME=""

# Never block shell startup with an interactive "would you like to update?" prompt
zstyle ':omz:update' mode reminder

# Plugins (oh-my-zsh built-ins). The brew-installed zsh-autosuggestions /
# zsh-syntax-highlighting / zsh-completions are loaded separately below for
# better control over load order.
plugins=(
  git
  macos
  brew
  docker
  docker-compose
  python
  pip
  poetry
  npm
  fnm
  aws
  command-not-found
  colored-man-pages
  extract
)

# Make brew-installed zsh-completions discoverable BEFORE oh-my-zsh runs compinit
FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"

source "$ZSH/oh-my-zsh.sh"

# =============================================================================
# History — make it useful
# =============================================================================
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$HOME/.zsh_history"
setopt SHARE_HISTORY          # share history across all running shells
setopt HIST_IGNORE_DUPS       # don't record consecutive dupes
setopt HIST_IGNORE_ALL_DUPS   # remove older dupes when a new one arrives
setopt HIST_IGNORE_SPACE      # commands starting with a space are not saved
setopt HIST_REDUCE_BLANKS     # trim extra whitespace
setopt HIST_VERIFY            # show !! / !$ expansions before running

# =============================================================================
# Language version managers
# =============================================================================
# fnm (Fast Node Manager)
FNM_PATH="/opt/homebrew/opt/fnm/bin"
if [ -d "$FNM_PATH" ]; then
  eval "$(fnm env --use-on-cd)"
fi

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# =============================================================================
# PATH additions
# =============================================================================
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"   # libpq (psql etc.)
export PATH="$HOME/.local/bin:$PATH"              # user-local bins
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# pnpm
export PNPM_HOME="/Users/marcello/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# =============================================================================
# Modern CLI replacements
# =============================================================================
# eza — modern ls with icons + git status
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first'
  alias l='eza -l --git --icons --group-directories-first'
  alias ll='eza -l --git --icons --group-directories-first'
  alias la='eza -la --git --icons --group-directories-first'
  alias lt='eza --tree --level=2 --icons --group-directories-first'
  alias ltt='eza --tree --level=3 --icons --group-directories-first'
fi

# bat — cat with syntax highlighting + paging
if command -v bat >/dev/null; then
  alias cat='bat --paging=never'
  alias less='bat'
  export BAT_THEME="ansi"
  # Use bat as the man pager (colored man pages)
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT="-c"
fi

# ripgrep — faster than grep, respects .gitignore
# (rg has its own command; only add a fallback alias if you really want it)
# alias grep='rg'   # uncomment to fully replace grep

# fd — friendlier find
# (fd has its own command; no alias needed)

# =============================================================================
# Personal aliases
# =============================================================================
alias zshconfig='${EDITOR:-vim} ~/.zshrc'
alias zshreload='source ~/.zshrc'
alias starshipconfig='${EDITOR:-vim} ~/.config/starship.toml'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Safer file ops
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Misc
alias path='echo $PATH | tr ":" "\n"'
alias ports='lsof -i -P -n | grep LISTEN'
alias myip='curl -s https://ifconfig.me && echo'

# =============================================================================
# Git aliases (overlays on top of oh-my-zsh's `git` plugin)
# Most you might want are already there: gst, gd, gco, gcb, gp, gl, glog, etc.
# Run `alias | grep '^g[a-z]*='` after reload to see them all.
# =============================================================================
alias gs='git status'                                 # shorter than gst
alias gcm='git commit -m'                             # override OMZ's `gcm` (= checkout main)
alias gca='git commit --amend --no-edit'
alias gcan='git commit --amend --no-edit --no-verify'
alias gwip='git add -A && git commit -m "wip" --no-verify'
alias gundo='git reset --soft HEAD~1'                 # undo last commit, keep changes staged
alias gprune='git fetch --prune && git branch -vv | awk "/: gone]/{print \$1}" | xargs -r git branch -D'
alias glog='git log --oneline --decorate --graph --all'
alias gloga='git log --graph --pretty=format:"%C(yellow)%h%Creset %C(cyan)%an%Creset %s %C(green)(%cr)%Creset %C(magenta)%d%Creset" --all'

# =============================================================================
# zsh plugins (load order matters — syntax-highlighting MUST be last)
# =============================================================================
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Accept the autosuggestion with Ctrl-Space (more ergonomic than the default →)
bindkey '^ ' autosuggest-accept

# syntax-highlighting MUST be sourced LAST (after all other plugins)
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# =============================================================================
# Starship prompt (must be initialized LAST so it owns PROMPT/RPROMPT)
# =============================================================================
eval "$(starship init zsh)"
