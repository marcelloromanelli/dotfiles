#!/bin/bash
# Claude Code status line — Tokyo Night powerline, two rows.
# Row 1: model · directory · git · PR/worktree/vim   Row 2: context, plan limits, cost, time, diff
# Needs a Nerd Font (MesloLGS Nerd Font Mono in Ghostty).

input=$(cat)
eval "$(jq -r '@sh "
model=\(.model.display_name // "")
effort=\(.effort.level // "")
fast=\(.fast_mode // false)
cwd=\(.workspace.current_dir // .cwd // "")
ctx=\(.context_window.used_percentage // "")
ctxsize=\(.context_window.context_window_size // "")
cost=\(.cost.total_cost_usd // "")
dur=\(.cost.total_duration_ms // 0)
added=\(.cost.total_lines_added // 0)
removed=\(.cost.total_lines_removed // 0)
h5=\(.rate_limits.five_hour.used_percentage // "")
h5r=\(.rate_limits.five_hour.resets_at // "")
d7=\(.rate_limits.seven_day.used_percentage // "")
d7r=\(.rate_limits.seven_day.resets_at // "")
pr=\(.pr.number // "")
prstate=\(.pr.review_state // "")
wt=\(.worktree.name // .workspace.git_worktree // "")
vim=\(.vim.mode // "")
cache=\(.prompt_cache.warm // "")
"' <<<"$input")"

# Tokyo Night palette (R;G;B)
E=$'\033'; R="${E}[0m"
DARK="26;27;38"; FG="192;202;245"; MUTED="86;95;137"; SURFACE="41;46;66"
BLUE="122;162;247"; PURPLE="187;154;247"; GREEN="158;206;106"; YELLOW="224;175;104"
ORANGE="255;158;100"; RED="247;118;142"; CYAN="125;207;255"; TEAL="115;218;202"

fg() { printf '%s' "${E}[38;2;${1}m"; }

# ── Powerline segments ────────────────────────────────────────────────
line1=''; prev=''
seg() { # bg fg text
  if [ -z "$prev" ]; then line1+="$(fg "$1")"
  else line1+="${E}[38;2;${prev};48;2;${1}m"; fi
  line1+="${E}[48;2;${1};38;2;${2}m ${3} "
  prev=$1
}
close_segs() { [ -n "$prev" ] && line1+="${R}$(fg "$prev")${R}"; }

# Model, effort, fast mode
m="󰚩 ${model:-Claude}"
[ -n "$effort" ] && m+=" · ${effort}"
[ "$fast" = "true" ] && m+=" ↯"
seg "$PURPLE" "$DARK" "$m"

# Directory, truncated to the last 3 components like Starship
if [ -n "$cwd" ]; then
  dir="${cwd/#$HOME/~}"
  IFS='/' read -ra parts <<<"$dir"
  if [ "${#parts[@]}" -gt 3 ]; then
    n=${#parts[@]}; dir="…/${parts[n-3]}/${parts[n-2]}/${parts[n-1]}"
  fi
  seg "$BLUE" "$DARK" " $dir"
fi

# Git branch, ahead/behind and working tree counts
if [ -n "$cwd" ] && gs=$(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null); then
  branch=$(sed -n 's/^# branch.head //p' <<<"$gs")
  [ "$branch" = "(detached)" ] && branch=$(sed -n 's/^# branch.oid //p' <<<"$gs" | cut -c1-7)
  ab=$(sed -n 's/^# branch.ab +\([0-9]*\) -\([0-9]*\)$/\1 \2/p' <<<"$gs")
  ahead=${ab% *}; behind=${ab#* }
  staged=$(grep -cE '^[12] [^.]' <<<"$gs")
  modified=$(grep -cE '^[12] .[^.]' <<<"$gs")
  untracked=$(grep -c '^?' <<<"$gs")
  g=" $branch"
  [ "${ahead:-0}" -gt 0 ] && g+=" ⇡$ahead"
  [ "${behind:-0}" -gt 0 ] && g+=" ⇣$behind"
  [ "$staged" -gt 0 ] && g+=" +$staged"
  [ "$modified" -gt 0 ] && g+=" ~$modified"
  [ "$untracked" -gt 0 ] && g+=" ?$untracked"
  if [ $((staged + modified + untracked)) -gt 0 ]; then seg "$YELLOW" "$DARK" "$g"
  else seg "$GREEN" "$DARK" "$g"; fi
fi

# Open PR and its review state
if [ -n "$pr" ]; then
  case "$prstate" in
    approved) p=" #$pr ✓" ;; changes_requested) p=" #$pr ✗" ;;
    draft) p=" #$pr ◌" ;; *) p=" #$pr" ;;
  esac
  seg "$CYAN" "$DARK" "$p"
fi

[ -n "$wt" ] && seg "$ORANGE" "$DARK" "󰙅 $wt"
[ -n "$vim" ] && seg "$SURFACE" "$FG" "$vim"
close_segs

# ── Metrics row ───────────────────────────────────────────────────────
level() { # pct → colour
  if [ "$1" -ge 80 ]; then echo "$RED"; elif [ "$1" -ge 50 ]; then echo "$YELLOW"; else echo "$GREEN"; fi
}
bar() { # pct width [colour]
  local filled=$(( ($1 * $2 + 50) / 100 )) i out=''
  [ "$filled" -gt "$2" ] && filled=$2
  out+="$(fg "${3:-$(level "$1")}")"
  for ((i = 0; i < filled; i++)); do out+='▰'; done
  out+="$(fg "$SURFACE")"
  for ((i = filled; i < $2; i++)); do out+='▱'; done
  printf '%s' "$out"
}
human_dur() { # seconds → 1h12m / 23m / 45s
  local s=$1
  if [ "$s" -ge 86400 ]; then printf '%dd%dh' $((s / 86400)) $((s % 86400 / 3600))
  elif [ "$s" -ge 3600 ]; then printf '%dh%02dm' $((s / 3600)) $((s % 3600 / 60))
  elif [ "$s" -ge 60 ]; then printf '%dm' $((s / 60))
  else printf '%ds' "$s"; fi
}

items=()
now=$(date +%s)

if [ -n "$ctx" ]; then
  c=$(printf '%.0f' "$ctx")
  size=''
  if [ -n "$ctxsize" ]; then
    if [ "$ctxsize" -ge 1000000 ]; then size=" of $((ctxsize / 1000000))M"; else size=" of $((ctxsize / 1000))k"; fi
  fi
  items+=("$(fg "$MUTED")ctx $(bar "$c" 10) $(fg "$(level "$c")")${c}%$(fg "$MUTED")${size}")
fi

# Plan limits as what's left: the bar drains as you use it, red when nearly empty
limit() { # label used_pct resets_at width
  local used left col out
  used=$(printf '%.0f' "$2"); left=$((100 - used)); [ "$left" -lt 0 ] && left=0
  col=$(level "$used")
  out="$(fg "$MUTED")$1 $(bar "$left" "$4" "$col") $(fg "$col")${left}% left"
  [ -n "$3" ] && [ "$3" -gt "$now" ] && out+="$(fg "$MUTED") ↻$(human_dur $(($3 - now)))"
  items+=("$out")
}
[ -n "$h5" ] && limit 5h "$h5" "$h5r" 5
[ -n "$d7" ] && limit 7d "$d7" "$d7r" 5

[ -n "$cost" ] && items+=("$(fg "$YELLOW")$(printf '$%.2f' "$cost")")
[ "$dur" -gt 0 ] && items+=("$(fg "$TEAL")󱦟 $(human_dur $((dur / 1000)))")
if [ "$added" -gt 0 ] || [ "$removed" -gt 0 ]; then
  items+=("$(fg "$GREEN")+${added} $(fg "$RED")−${removed}")
fi
case "$cache" in
  true) items+=("$(fg "$CYAN")󰆼 warm") ;;
  false) items+=("$(fg "$MUTED")󰆼 cold") ;;
esac
items+=("$(fg "$MUTED") $(date +%H:%M)")

line2=''
sep="$(fg "$SURFACE") │ "
for i in "${!items[@]}"; do
  [ "$i" -gt 0 ] && line2+="$sep"
  line2+="${items[$i]}"
done

printf '%s\n%s%s' "$line1" "$line2" "$R"
