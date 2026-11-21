#!/bin/bash
# WallpaperUndo.sh — Undo wallpaper changes made with Win+W.
#
# Wallpaper.sh records the wallpaper it replaces in
# ~/.hyprconf/hypr/.cache/.wall_history (newest entry first, MAX_HISTORY entries).
# This script applies the newest of those entries and removes everything up to
# it from the history, so pressing the keybind repeatedly walks back through the
# whole history.

scripts_dir="$HOME/.hyprconf/hypr/scripts"
cache_dir="$HOME/.hyprconf/hypr/.cache"
history_file="$cache_dir/.wall_history"
wallCache="$cache_dir/.wallpaper"

[[ ! -f "$wallCache" ]] && touch "$wallCache"

# Detect wallpaper engine
if command -v awww >/dev/null 2>&1; then
    ENGINE="awww"
elif command -v swww >/dev/null 2>&1; then
    ENGINE="swww"
else
    notify-send "Wallpaper Error" "Neither awww nor swww is installed."
    exit 1
fi

if [[ ! -s "$history_file" ]]; then
    notify-send "Wallpaper Undo" "No wallpaper history yet."
    exit 0
fi

mapfile -t HIST < "$history_file"

# Oldest entry that still points to an existing image
target=""
idx=0
for i in "${!HIST[@]}"; do
    if [[ -f "${HIST[i]}" ]]; then
        target="${HIST[i]}"
        idx="$i"
        break
    fi
done

if [[ -z "$target" ]]; then
    notify-send "Wallpaper Undo" "History entries no longer exist."
    : > "$history_file"
    exit 0
fi

# Drop the entries we just walked back through (keep the older ones)
if (( idx + 1 < ${#HIST[@]} )); then
    printf '%s\n' "${HIST[@]:idx+1}" > "$history_file"
else
    : > "$history_file"
fi

# Transition config (same as Wallpaper.sh)
FPS=120
TYPE="any"
DURATION=1
BEZIER=".28,.58,.99,.37"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Start daemon if not already running
if ! pgrep -x "${ENGINE}-daemon" >/dev/null; then
    ${ENGINE}-daemon &>/dev/null &
    disown
    sleep 0.5
fi

${ENGINE} img "$target" $AWWW_PARAMS

ln -sf "$target" "$cache_dir/current_wallpaper.png"
baseName="$(basename "$target")"
echo "${baseName%.*}" > "$wallCache"

notify-send "Wallpaper Undo" "$(basename "$target")"

"$scripts_dir/pywal.sh"
