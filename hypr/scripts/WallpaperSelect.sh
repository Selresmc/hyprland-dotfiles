#!/bin/bash
# WallpaperSelect.sh — Browse wallpapers by subfolder via rofi and apply the choice.
#
#  • Level 1: folder overview (each folder shows a preview + image count)
#  • Level 2: images inside the folder (thumbnails, name without resolution)
#  • Thumbnails are served from ~/.hyprconf/hypr/.cache/wallthumbs (auto-generated)

scripts_dir="$HOME/.hyprconf/hypr/scripts"
wallDIR="$HOME/.hyprconf/hypr/Wallpaper"
cache_dir="$HOME/.hyprconf/hypr/.cache"
thmbDir="$cache_dir/wallthumbs"
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

# Transition config
FPS=120
TYPE="any"
DURATION=1
BEZIER=".28,.58,.99,.37"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Rofi theme (thm1 / thm2)
case "${1:-thm1}" in
    thm2) ROFI_CMD=(rofi -show -dmenu -config "$HOME/.config/rofi/themes/rofi-wall-2.rasi") ;;
    *)    ROFI_CMD=(rofi -show -dmenu -config "$HOME/.config/rofi/themes/rofi-wall.rasi") ;;
esac

RANDOM_LABEL="🎲  Zufällig (alle)"
ALL_LABEL="🗂️  Alle Bilder"
BACK_LABEL="⬅️  Zurück"
FOLDER_RANDOM_LABEL="🎲  Zufällig in diesem Ordner"

IMG_FIND=( -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) )

# --- helpers -----------------------------------------------------------------
# thumbnail path for a full wallpaper path
thumb_of() {
    local rel="${1#"$wallDIR"/}" base
    base="${rel%.*}"
    printf '%s/%s.jpg\n' "$thmbDir" "${base//\//__}"
}

# display name: filename without extension and without the "WxH_" resolution prefix
disp_name() {
    local b; b="$(basename "$1")"; b="${b%.*}"
    b="$(sed -E 's/^[0-9]+x[0-9]+_//' <<<"$b")"
    printf '%s\n' "$b"
}

# start daemon if not already running
start_daemon() {
    if ! pgrep -x "${ENGINE}-daemon" >/dev/null; then
        ${ENGINE}-daemon &>/dev/null &
        disown
        sleep 0.5
    fi
}

# apply a wallpaper and refresh pywal
apply_wallpaper() {
    local img="$1"
    ${ENGINE} img "$img" $AWWW_PARAMS
    ln -sf "$img" "$cache_dir/current_wallpaper.png"
    local baseName="${img##*/}"
    echo "${baseName%.*}" > "$wallCache"
    "$scripts_dir/pywal.sh"
}

# make sure every wallpaper has a thumbnail (only missing ones are built)
[[ -x "$scripts_dir/wallthumb.sh" ]] && "$scripts_dir/wallthumb.sh" >/dev/null 2>&1

# --- build folder overview ---------------------------------------------------
mapfile -t FOLDERS < <(
    find "$wallDIR" -mindepth 1 -maxdepth 1 -type d -print0 \
    | sort -z | while IFS= read -r -d '' d; do
        n=$(find "$d" "${IMG_FIND[@]}" 2>/dev/null | wc -l)
        [[ "$n" -gt 0 ]] && printf '%s\t%s\n' "$d" "$n"
    done
)

if [[ ${#FOLDERS[@]} -eq 0 ]]; then
    notify-send "Wallpaper Error" "No wallpapers found in $wallDIR"
    exit 1
fi

# --- main navigation loop ----------------------------------------------------
while :; do
    # ----- level 1: folder menu -----
    menu1() {
        printf '%s\n' "$RANDOM_LABEL"
        printf '%s\n' "$ALL_LABEL"
        for entry in "${FOLDERS[@]}"; do
            d="${entry%%$'\t'*}"; n="${entry##*$'\t'}"
            first=$(find "$d" "${IMG_FIND[@]}" 2>/dev/null | sort | head -n1)
            icon="$(thumb_of "$first")"
            if [[ "$first" == *.gif ]]; then
                printf '%s\x00icon\x1f%s\n' "$(basename "$d")  ($n)" "$first"
            elif [[ -f "$icon" ]]; then
                printf '%s\x00icon\x1f%s\n' "$(basename "$d")  ($n)" "$icon"
            else
                printf '%s\n' "$(basename "$d")  ($n)"
            fi
        done
    }

    choice=$(menu1 | "${ROFI_CMD[@]}")
    [[ -z "$choice" ]] && exit 0

    case "$choice" in
        "$RANDOM_LABEL")
            mapfile -t ALL < <(find "$wallDIR" "${IMG_FIND[@]}" | sort)
            start_daemon
            apply_wallpaper "${ALL[RANDOM % ${#ALL[@]}]}"
            exit 0
            ;;
        "$ALL_LABEL")
            SELECT_DIR="$wallDIR"
            ;;
        *)
            # strip the trailing "  (NN)" count
            dirname="${choice%  (*}"
            SELECT_DIR="$wallDIR/$dirname"
            ;;
    esac

    # ----- level 2: image menu for the selected folder -----
    mapfile -d '' _PICS < <(find "$SELECT_DIR" -maxdepth 1 "${IMG_FIND[@]}" -print0 | sort -z)
    [[ ${#_PICS[@]} -eq 0 ]] && continue

    menu2() {
        if [[ "$SELECT_DIR" != "$wallDIR" ]]; then
            printf '%s\n' "$FOLDER_RANDOM_LABEL"
            printf '%s\n' "$BACK_LABEL"
        fi
        for p in "${_PICS[@]}"; do
            name="$(disp_name "$p")"
            icon="$(thumb_of "$p")"
            if [[ "$p" == *.gif ]]; then
                printf '%s\n' "$name"
            elif [[ -f "$icon" ]]; then
                printf '%s\x00icon\x1f%s\n' "$name" "$icon"
            else
                printf '%s\x00icon\x1f%s\n' "$name" "$p"
            fi
        done
    }

    pick=$(menu2 | "${ROFI_CMD[@]}")
    [[ -z "$pick" ]] && exit 0

    if [[ "$pick" == "$BACK_LABEL" ]]; then
        continue
    fi

    if [[ "$pick" == "$FOLDER_RANDOM_LABEL" ]]; then
        start_daemon
        apply_wallpaper "${_PICS[RANDOM % ${#_PICS[@]}]}"
        exit 0
    fi

    # resolve by display name
    selected_full=""
    for p in "${_PICS[@]}"; do
        if [[ "$(disp_name "$p")" == "$pick" ]]; then
            selected_full="$p"
            break
        fi
    done

    if [[ -z "$selected_full" ]]; then
        notify-send "Wallpaper Error" "Image not found."
        exit 1
    fi

    start_daemon
    apply_wallpaper "$selected_full"
    exit 0
done
