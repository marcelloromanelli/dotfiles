#!/usr/bin/env bash
# install.sh — symlink the files in this repo into $HOME.
# Idempotent. Re-run any time to sync new files or refresh broken links.
#
# Usage:
#   ./install.sh                # link everything (default)
#   ./install.sh brew           # install Homebrew + run brew bundle (+ .local + .work)
#   ./install.sh macos          # apply macos-defaults.sh (asks first)
#   ./install.sh launchd        # install the daily autopull LaunchAgent
#   ./install.sh update         # git pull + re-link
#   ./install.sh doctor         # verify everything is wired up
#   ./install.sh unlink         # remove all symlinks
#   ./install.sh all            # brew + link + launchd + doctor

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Each line:  <path-in-repo>  <path-relative-to-HOME>
LINKS=(
  ".zshrc                .zshrc"
  ".gitconfig            .gitconfig"
  ".gitignore            .gitignore"
  ".gitattributes        .gitattributes"
  ".editorconfig         .editorconfig"
  "starship.toml         .config/starship.toml"
  "ghostty.config        .config/ghostty/config"
)

if [[ -t 1 ]]; then
  B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; D=$'\033[2m'; N=$'\033[0m'
else B=''; G=''; Y=''; R=''; D=''; N=''; fi
info() { printf '%s==>%s %s\n'  "$B"   "$N" "$*"; }
ok()   { printf '%s ✓%s %s\n'   "$G"   "$N" "$*"; }
warn() { printf '%s ⚠%s %s\n'   "$Y"   "$N" "$*"; }
err()  { printf '%s ✗%s %s\n'   "$R"   "$N" "$*" >&2; }
skip() { printf '%s  -%s %s\n'  "$D"   "$N" "$*"; }

link_one() {
  local src="$REPO/$1" dst="$HOME/$2"
  [[ -e "$src" ]] || { err "missing in repo: $1"; return 1; }
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    skip "~/$2 (already linked)"; return 0
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    mkdir -p "$BACKUP/$(dirname "$2")"
    mv "$dst" "$BACKUP/$2"
    warn "backed up existing ~/$2 → ${BACKUP/$HOME/~}/$2"
  fi
  ln -s "$src" "$dst"
  ok "linked ~/$2"
}

unlink_one() {
  local src="$REPO/$1" dst="$HOME/$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    rm "$dst"; ok "unlinked ~/$2"
  else
    skip "~/$2 (not our symlink)"
  fi
}

cmd_link() {
  info "Linking $REPO → \$HOME"
  for entry in "${LINKS[@]}"; do
    link_one $entry
  done
  # Seed the gitconfig.local from example once (never overwrite).
  if [[ ! -e "$HOME/.gitconfig.local" ]]; then
    cp "$REPO/gitconfig.local.example" "$HOME/.gitconfig.local"
    chmod 600 "$HOME/.gitconfig.local"
    ok "seeded ~/.gitconfig.local (edit me)"
  else
    skip "~/.gitconfig.local already exists"
  fi

  # Seed ~/.extra from extra.tpl. If 1Password CLI is signed in, run
  # `op inject` to materialize op:// references; otherwise copy literally
  # (placeholders will be visible — user runs op inject after `op signin`).
  if [[ ! -e "$HOME/.extra" ]]; then
    if command -v op >/dev/null && op whoami >/dev/null 2>&1; then
      op inject -i "$REPO/extra.tpl" -o "$HOME/.extra"
      chmod 600 "$HOME/.extra"
      ok "materialized ~/.extra from extra.tpl via op inject"
    else
      cp "$REPO/extra.tpl" "$HOME/.extra"
      chmod 600 "$HOME/.extra"
      warn "seeded ~/.extra (placeholders unresolved — run 'op inject -i $REPO/extra.tpl -o ~/.extra' after 'op signin')"
    fi
  else
    skip "~/.extra already exists"
  fi

  # Activate the repo's git hooks (scoped to this repo only).
  if [[ -d "$REPO/.githooks" ]]; then
    chmod +x "$REPO"/.githooks/* 2>/dev/null || true
    git -C "$REPO" config core.hooksPath .githooks
    ok "enabled pre-commit hooks (.githooks/)"
  fi
  # Clean up empty backup dir.
  rmdir "$BACKUP" 2>/dev/null && rmdir "$(dirname "$BACKUP")" 2>/dev/null || true
  [[ -d "$BACKUP" ]] && info "Backups: $BACKUP"
}

cmd_unlink() {
  info "Removing symlinks"
  for entry in "${LINKS[@]}"; do
    unlink_one $entry
  done
}

cmd_brew() {
  if ! command -v brew >/dev/null; then
    info "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    skip "Homebrew already installed"
  fi
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  info "Running brew bundle (Brewfile)"
  brew bundle --file="$REPO/Brewfile"
  for extra in Brewfile.work Brewfile.local; do
    if [[ -f "$REPO/$extra" ]]; then
      info "Running brew bundle ($extra)"
      brew bundle --file="$REPO/$extra"
    fi
  done
}

cmd_launchd() {
  local plist_src="$REPO/launchd/com.marcello.dotfiles-autopull.plist"
  local plist_dst="$HOME/Library/LaunchAgents/com.marcello.dotfiles-autopull.plist"
  [[ -f "$plist_src" ]] || { err "missing $plist_src"; return 1; }
  mkdir -p "$(dirname "$plist_dst")"
  # Substitute placeholders and write to LaunchAgents dir.
  sed -e "s|__DOTFILES__|$REPO|g" -e "s|__HOME__|$HOME|g" "$plist_src" > "$plist_dst"
  # Re-load: bootout if already loaded, then bootstrap.
  launchctl bootout "gui/$UID" "$plist_dst" 2>/dev/null || true
  if launchctl bootstrap "gui/$UID" "$plist_dst" 2>/dev/null; then
    ok "LaunchAgent installed: dotfiles-autopull (runs daily at 12:00 + at login)"
    info "Log: ~/Library/Logs/dotfiles-autopull.log"
  else
    err "launchctl bootstrap failed"; return 1
  fi
}

cmd_macos() {
  local script="$REPO/macos/defaults.sh"
  [[ -x "$script" ]] || { err "$script not found/executable"; return 1; }
  warn "About to apply macOS defaults (some require logout/restart)."
  read -r -p "Continue? [y/N] " r; [[ "$r" =~ ^[Yy]$ ]] || return 0
  "$script"
}

cmd_doctor() {
  info "Checking installation"
  local fail=0
  for entry in "${LINKS[@]}"; do
    set -- $entry
    local src="$REPO/$1" dst="$HOME/$2"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
      ok "~/$2"
    else
      err "~/$2 not linked"; fail=1
    fi
  done
  for c in brew zsh git starship eza bat rg fd gh delta; do
    command -v "$c" >/dev/null && ok "$c" || warn "$c missing"
  done
  (( fail == 0 )) && ok "all good" || { err "doctor found issues"; return 1; }
}

cmd_update() {
  info "git pull && relink"
  git -C "$REPO" pull --ff-only || { err "git pull failed"; return 1; }
  cmd_link
}

cmd_all() { cmd_brew; cmd_link; cmd_launchd; cmd_doctor || true; }

case "${1:-link}" in
  link|install) cmd_link ;;
  brew)         cmd_brew ;;
  macos)        cmd_macos ;;
  launchd)      cmd_launchd ;;
  update)       cmd_update ;;
  unlink)       cmd_unlink ;;
  doctor)       cmd_doctor ;;
  all)          cmd_all ;;
  -h|--help|help)
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) err "unknown: $1"; exit 1 ;;
esac
