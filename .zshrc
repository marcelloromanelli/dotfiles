# =============================================================================
# Homebrew (needed early so brew --prefix works for the rest of this file)
# =============================================================================
eval "$(/opt/homebrew/bin/brew shellenv)"

# =============================================================================
# Local / work overrides (untracked). Sourced early so anything below can
# rely on the env vars they export (Databricks, AWS CodeArtifact, etc.).
# =============================================================================
[[ -r "$HOME/.extra" ]] && source "$HOME/.extra"

# =============================================================================
# Oh My Zsh
# =============================================================================
export ZSH="$HOME/.oh-my-zsh"

# Theme is set to empty because we use Starship for the prompt (see bottom)
ZSH_THEME=""

# Never block shell startup with an interactive "would you like to update?" prompt
zstyle ':omz:update' mode reminder

# Disable oh-my-zsh's built-in `user@host: ~/path` title — we set our own below
DISABLE_AUTO_TITLE="true"

# Plugins (oh-my-zsh built-ins). The brew-installed zsh-autosuggestions /
# zsh-syntax-highlighting / zsh-completions are loaded separately below for
# better control over load order.
plugins=(
  git
  python
  poetry
  npm
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
setopt EXTENDED_HISTORY       # record timestamp + duration of each command
setopt HIST_FIND_NO_DUPS      # skip dupes when searching (↑, Ctrl-R)

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
# Note: OMZ provides `gcm = git checkout main`. To commit with message, use
# OMZ's `gcmsg "msg"` (= git commit -m).
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
# Smart terminal title
# Idle:    "~/gyg/gygadmin"              (local)   /  "marcello@host: ~/path"  (ssh)
# Running: "npm run dev — gygadmin"      (local)   /  "marcello@host: npm — gygadmin"  (ssh)
# =============================================================================
function _title_is_ssh() {
  [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]
}

function _title_set() {
  print -Pn "\e]0;${1}\a"
}

function _title_idle() {
  local dir="${PWD/#$HOME/~}"
  if _title_is_ssh; then
    _title_set "${USER}@${HOST%%.*}: ${dir}"
  else
    _title_set "${dir}"
  fi
}

function _title_running() {
  local full_cmd="$1"
  # Strip env-var prefixes (FOO=bar baz) and take the first token (the program)
  local cmd="${${(z)full_cmd}[(r)[^=]##]}"
  cmd="${cmd:t}"   # basename, in case of full paths
  local dir="${PWD:t}"
  if _title_is_ssh; then
    _title_set "${USER}@${HOST%%.*}: ${cmd} — ${dir}"
  else
    _title_set "${cmd} — ${dir}"
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd  _title_idle      # before each prompt → reset to idle title
add-zsh-hook preexec _title_running   # before each command → show command in title

# =============================================================================
# Dotfiles helper: `dots`
# =============================================================================
# DOTFILES — let scripts and functions locate the repo without hardcoding.
export DOTFILES="${DOTFILES:-$HOME/projects/dotfiles}"

dots() {
  local repo="$DOTFILES"
  [[ -d "$repo" ]] || { echo "DOTFILES not found: $repo" >&2; return 1; }
  local cmd="${1:-status}"; shift 2>/dev/null || true

  case "$cmd" in
    cd)      cd "$repo" ;;
    status|"")
      # Fast: NO network. Use last-known-fetched origin ref. Run `dots pull`
      # to refresh the remote state (which runs the LaunchAgent's safe fetch).
      ( cd "$repo" && {
          local branch ahead behind dirty last
          branch=$(git rev-parse --abbrev-ref HEAD)
          ahead=$(git rev-list --count "origin/$branch..HEAD" 2>/dev/null || echo 0)
          behind=$(git rev-list --count "HEAD..origin/$branch" 2>/dev/null || echo 0)
          dirty=$(git status --porcelain | wc -l | tr -d ' ')
          last=$(git log -1 --format='%h %s (%cr)')
          echo "  repo:    $repo"
          echo "  branch:  $branch  (ahead $ahead, behind $behind — vs last fetch)"
          echo "  dirty:   $dirty file(s)"
          echo "  last:    $last"
        }
      ) ;;
    edit)
      if [[ $# -eq 0 ]]; then
        ( cd "$repo" && ${EDITOR:-vim} . )
      else
        ${EDITOR:-vim} "$repo/$1"
      fi ;;
    diff)    git -C "$repo" diff "$@" ;;
    log)     git -C "$repo" log --oneline --decorate --graph -20 "$@" ;;
    pull)    bash "$repo/scripts/autopull.sh" && echo "see ~/Library/Logs/dotfiles-autopull.log" ;;
    push)    git -C "$repo" push "$@" ;;
    sync)
      local msg="${1:-update}"
      ( cd "$repo" && {
          # Stash + rebase + pop pattern, with fallback to clean push.
          if ! git diff --quiet || ! git diff --cached --quiet; then
            git add -A && git commit -m "$msg" || return 1
          fi
          git pull --rebase --autostash || { echo "rebase failed — resolve and run 'dots push'" >&2; return 1; }
          git push
        }
      ) ;;
    install)  bash "$repo/install.sh" link ;;
    doctor)   bash "$repo/install.sh" doctor ;;
    update)   bash "$repo/install.sh" update ;;
    autopull-log) tail -40 "$HOME/Library/Logs/dotfiles-autopull.log" 2>/dev/null || echo "no log yet" ;;
    help|-h|--help)
      cat <<EOF
dots — dotfiles helper

  dots                  short status (branch, ahead/behind, dirty count)
  dots status           same as above
  dots cd               cd into the repo
  dots edit [file]      open the repo (or a specific file) in \$EDITOR
  dots diff [args]      git diff inside the repo
  dots log              recent commits
  dots sync "msg"       commit any changes, rebase-pull, push
  dots pull             safe non-destructive pull (uses scripts/autopull.sh)
  dots push             git push
  dots install          rerun install.sh link
  dots doctor           rerun install.sh doctor
  dots update           git pull + relink
  dots autopull-log     tail the LaunchAgent's log
EOF
      ;;
    *) echo "dots: unknown subcommand '$cmd' (try 'dots help')" >&2; return 1 ;;
  esac
}

# Hourly dirty-state warning. Cached via timestamp file so we touch git at most
# once per hour. Only warns when the working tree is dirty AND last commit is
# older than 24h (so a "still in progress" change doesn't spam).
_dots_dirty_check() {
  local stamp="${TMPDIR:-/tmp}/dots-dirty-check-${USER}"
  local now last
  now=$(date +%s)
  last=0
  [[ -r "$stamp" ]] && last=$(cat "$stamp" 2>/dev/null || echo 0)
  (( now - last < 3600 )) && return
  echo "$now" > "$stamp"

  [[ -d "$DOTFILES/.git" ]] || return
  local dirty last_commit age
  dirty=$(git -C "$DOTFILES" status --porcelain 2>/dev/null)
  [[ -z "$dirty" ]] && return
  last_commit=$(git -C "$DOTFILES" log -1 --format=%ct 2>/dev/null) || return
  age=$(( now - last_commit ))
  (( age < 86400 )) && return  # <24h since last commit — probably still iterating

  printf '\033[33m⚠\033[0m dotfiles dirty for %dh; run \033[1mdots sync "msg"\033[0m to ship\n' "$(( age / 3600 ))"
}
_dots_dirty_check

# =============================================================================
# Starship prompt (must be initialized LAST so it owns PROMPT/RPROMPT)
# =============================================================================
eval "$(starship init zsh)"
