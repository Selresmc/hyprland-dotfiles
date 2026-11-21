#!/bin/bash
# Wallpaper.sh — Pick a random wallpaper and apply it.

scripts_dir="$HOME/.hyprconf/hypr/scripts"
cache_dir="$HOME/.hyprconf/hypr/.cache"
wallCache="$cache_dir/.wallpaper"
wallpaper_dir="$HOME/.hyprconf/hypr/Wallpaper"
history_file="$cache_dir/.wall_history"
MAX_HISTORY=100

[[ ! -f "$wallCache" ]] && touch "$wallCache"

# Remember the wallpaper we are about to replace so WallpaperUndo.sh can step back.
# The history holds the last MAX_HISTORY previous wallpapers, newest entry first.
push_history() {
    local new="$1" current
    current="$(readlink -f "$cache_dir/current_wallpaper.png" 2>/dev/null)"

    [[ -z "$current" || ! -f "$current" || "$current" == "$new" ]] && return 0

    {
        printf '%s\n' "$current"
        [[ -s "$history_file" ]] && cat "$history_file"
    } | awk -v skip="$new" '$0 != skip && !seen[$0]++' \
      | head -n "$MAX_HISTORY" > "$history_file.tmp"

    mv "$history_file.tmp" "$history_file"
}

# Detect wallpaper engine
if command -v awww >/dev/null 2>&1; then
    ENGINE="awww"
elif command -v swww >/dev/null 2>&1; then
    ENGINE="swww"
else
    notify-send "Wallpaper Error" "Neither awww nor swww is installed."
    exit 1
fi

# Use mapfile+find to correctly handle filenames with spaces (recursive: subfolders included)
mapfile -d '' PICS < <(
    find "$wallpaper_dir" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) \
    -print0
)

# No wallpapers found
if [[ ${#PICS[@]} -eq 0 ]]; then
    notify-send "Wallpaper Error" "No wallpapers found in $wallpaper_dir"
    exit 1
fi

wallpaper="${PICS[RANDOM % ${#PICS[@]}]}"

# Transition config
FPS=120
TYPE="any"
DURATION=1
BEZIER=".28,.58,.99,.37"

AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Start daemon if not already running
start_daemon() {
    if ! pgrep -x "${ENGINE}-daemon" >/dev/null; then
        ${ENGINE}-daemon &>/dev/null &
        disown
        sleep 0.5
    fi
}

# Apply wallpaper
set_wallpaper() {
    local img="$1"

    push_history "$img"

    ${ENGINE} img "$img" $AWWW_PARAMS

    ln -sf "$img" "$cache_dir/current_wallpaper.png"

    local baseName wallName
    baseName="$(basename "$img")"
    wallName="${baseName%.*}"

    echo "$wallName" > "$wallCache"
}

start_daemon
set_wallpaper "$wallpaper"

# wallcache.sh is called by pywal.sh — no need to call it here too
"$scripts_dir/pywal.sh"
