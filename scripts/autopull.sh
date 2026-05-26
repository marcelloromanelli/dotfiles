#!/usr/bin/env bash
# scripts/autopull.sh — safe non-interactive auto-pull for dotfiles.
#
# Called by the LaunchAgent (see launchd/com.marcello.dotfiles-autopull.plist).
#
# Behavior (intentionally conservative — never touches a dirty tree):
#   - Working tree dirty or staged changes      → no-op
#   - Local has unpushed commits                → no-op
#   - Remote unchanged                          → no-op
#   - Remote strictly ahead (fast-forward)      → merge --ff-only
#   - Diverged                                  → log warning, no-op
#   - Remote unreachable / offline              → silent no-op
#
# Log: ~/Library/Logs/dotfiles-autopull.log

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$HOME/Library/Logs/dotfiles-autopull.log"
mkdir -p "$(dirname "$LOG")"

log() {
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$(hostname -s)" "$*" >> "$LOG"
}

cd "$REPO" || { log "FAIL cd $REPO"; exit 0; }

# 1) Skip if working tree is dirty (don't risk losing in-progress edits).
if ! git diff --quiet || ! git diff --cached --quiet; then
  log "skip: working tree dirty"
  exit 0
fi

# 2) Fetch silently (5s timeout to handle offline laptops).
if ! timeout 30 git fetch --quiet origin main 2>>"$LOG"; then
  log "skip: fetch failed (offline?)"
  exit 0
fi

local_head=$(git rev-parse HEAD)
remote_head=$(git rev-parse origin/main 2>/dev/null) || { log "skip: no origin/main"; exit 0; }
merge_base=$(git merge-base HEAD origin/main 2>/dev/null) || { log "skip: no merge base"; exit 0; }

# 3) Already up to date.
if [[ "$local_head" == "$remote_head" ]]; then
  exit 0
fi

# 4) Local has unpushed commits (remote is reachable via merge-base but not equal).
if [[ "$remote_head" == "$merge_base" ]]; then
  log "skip: local ahead, unpushed commits"
  exit 0
fi

# 5) Remote strictly ahead → fast-forward.
if [[ "$local_head" == "$merge_base" ]]; then
  if git merge --ff-only origin/main >>"$LOG" 2>&1; then
    ahead=$(git rev-list --count "$local_head..origin/main")
    log "ff-merged $ahead new commit(s) from origin/main"
  else
    log "ff-merge failed unexpectedly"
  fi
  exit 0
fi

# 6) Diverged. Notify and do nothing.
log "DIVERGED: local and origin/main both have new commits — run 'dots sync'"
exit 0
