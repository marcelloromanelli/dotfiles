#!/usr/bin/env bash
# install.sh — symlink the files in this repo into $HOME.
# Idempotent. Re-run any time to sync new files or refresh broken links.
#
# Usage:
#   ./install.sh                # link everything (default)
#   ./install.sh brew           # install Homebrew + run brew bundle
#   ./install.sh macos          # apply macos-defaults.sh (asks first)
#   ./install.sh doctor         # verify everything is wired up
#   ./install.sh unlink         # remove all symlinks
#   ./install.sh all            # brew + link + doctor

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
  # Seed the untracked gitconfig.local once.
  if [[ ! -e "$HOME/.gitconfig.local" ]]; then
    cp "$REPO/gitconfig.local.example" "$HOME/.gitconfig.local"
    ok "seeded ~/.gitconfig.local (edit me)"
  else
    skip "~/.gitconfig.local already exists"
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
  info "Running brew bundle"
  brew bundle --file="$REPO/Brewfile"
  if [[ -f "$REPO/Brewfile.work" ]]; then
    info "Running brew bundle for Brewfile.work"
    brew bundle --file="$REPO/Brewfile.work"
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
  for c in brew zsh git starship eza bat rg fd gh; do
    command -v "$c" >/dev/null && ok "$c" || warn "$c missing"
  done
  (( fail == 0 )) && ok "all good" || { err "doctor found issues"; return 1; }
}

cmd_all() { cmd_brew; cmd_link; cmd_doctor || true; }

case "${1:-link}" in
  link|install) cmd_link ;;
  brew)         cmd_brew ;;
  macos)        cmd_macos ;;
  unlink)       cmd_unlink ;;
  doctor)       cmd_doctor ;;
  all)          cmd_all ;;
  -h|--help|help)
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) err "unknown: $1"; exit 1 ;;
esac
