#!/bin/bash
# WallpaperDelete.sh — Delete the currently active wallpaper after confirmation,
# then switch to a random next wallpaper.
#
# Bound to SUPER + SHIFT + Delete (see configs/keybinds.lua).

scripts_dir="$HOME/.hyprconf/hypr/scripts"
cache_dir="$HOME/.hyprconf/hypr/.cache"
wallpaper_dir="$HOME/.hyprconf/hypr/Wallpaper"
history_file="$cache_dir/.wall_history"

notify() {
    notify-send "Wallpaper löschen" "$1"
}

current="$(readlink -f "$cache_dir/current_wallpaper.png" 2>/dev/null)"

if [[ -z "$current" || ! -f "$current" ]]; then
    notify "Kein aktuelles Wallpaper gefunden."
    exit 1
fi

# Safety: only delete files inside the wallpaper directory
case "$current" in
    "$wallpaper_dir"/*) ;;
    *)
        notify "Aktuelles Wallpaper liegt nicht in $wallpaper_dir – abgebrochen."
        exit 1
        ;;
esac

baseName="$(basename "$current")"

# Confirmation dialog (extra window) — only "Ja, löschen" confirms deletion
choice="$(printf '%s\n' "Nein, abbrechen" "Ja, endgültig löschen" | rofi -dmenu -i -p "Wallpaper löschen?" -mesg "„${baseName}“ wird dauerhaft gelöscht. Diese Aktion kann nicht rückgängig gemacht werden." 2>/dev/null)"

if [[ "$choice" != "Ja, endgültig löschen" ]]; then
    notify "Löschen abgebrochen."
    exit 0
fi

# Remove deleted file from wallpaper history so Undo skips it
if [[ -f "$history_file" ]]; then
    awk -v del="$current" '$0 != del' "$history_file" > "$history_file.tmp" && mv "$history_file.tmp" "$history_file"
fi

if rm -- "$current"; then
    notify "Gelöscht: ${baseName}"
else
    notify "Fehler: „${baseName}“ konnte nicht gelöscht werden."
    exit 1
fi

# Switch to the next (random) wallpaper
"$scripts_dir/Wallpaper.sh"
