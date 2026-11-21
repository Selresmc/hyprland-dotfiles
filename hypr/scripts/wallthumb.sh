#!/usr/bin/env bash
# wallthumb.sh — Generate 16:10 (640x400) thumbnails for every wallpaper.
# Used by WallpaperSelect.sh so the rofi picker loads small previews instead
# of full-size (multi-MB) images.
#
#   wallthumb.sh            # generate/refresh thumbnails for all wallpapers
#   wallthumb.sh <image>    # generate/print the thumbnail path for one image
#
# Thumbnails live in ~/.hyprconf/hypr/.cache/wallthumbs/

WALLDIR="$HOME/.hyprconf/hypr/Wallpaper"
THUMBDIR="$HOME/.hyprconf/hypr/.cache/wallthumbs"
mkdir -p "$THUMBDIR"

thumb_path() {
    local img="$1" rel
    rel="${img#"$WALLDIR"/}"     # path relative to wallpaper dir
    rel="${rel//\//__}"          # subfolder separators -> __
    printf '%s/%s.jpg\n' "$THUMBDIR" "${rel%.*}"
}

make_thumb() {
    local img="$1" out
    out="$(thumb_path "$img")"
    if [[ ! -f "$out" || "$img" -nt "$out" ]]; then
        magick "$img[0]" -strip -thumbnail '640x400^' \
            -gravity center -extent 640x400 -quality 82 "$out" 2>/dev/null \
            || { rm -f "$out"; return 1; }
    fi
    printf '%s\n' "$out"
}

# Single-image mode
if [[ $# -ge 1 ]]; then
    make_thumb "$1"
    exit $?
fi

# Bulk mode (parallel)
export WALLDIR THUMBDIR
export -f thumb_path make_thumb
find "$WALLDIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' \) -print0 \
  | xargs -0 -P "$(nproc)" -I{} bash -c 'make_thumb "$1" >/dev/null' _ {}

echo "Thumbnails: $(find "$THUMBDIR" -type f -name '*.jpg' | wc -l) in $THUMBDIR"
