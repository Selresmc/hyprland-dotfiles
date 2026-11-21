#!/bin/bash
# monitor.sh — Interactive monitor refresh-rate setup (Lua config aware).
# Writes into configs/monitor.lua via hyprctl, replacing the auto-generated
# defaults (output "", mode "preferred", position "auto", scale "auto").

config_file="$HOME/.config/hypr/configs/monitor.lua"
monitor_icon="$HOME/.hyprconf/hypr/icons/monitor.png"

display() {
    cat << "EOF"
   __  ___          _ __             ____    __
  /  |/  /__  ___  (_) /____  ____  / __/__ / /___ _____
 / /|_/ / _ \/ _ \/ / __/ _ \/ __/ _\ \/ -_) __/ // / _ \
/_/  /_/\___/_//_/_/\__/\___/_/   /___/\__/\__/\_,_/ .__/
                                                  /_/
EOF
}

# Only offer setup while monitor.lua still holds the auto-generated defaults
if grep -q 'mode[[:space:]]*=[[:space:]]*"preferred"' "$config_file" 2>/dev/null; then

    gum spin \
        --spinner minidot \
        --spinner.foreground "#c5c1c1" \
        --title.foreground "#c5c1c1" \
        --title "Setting up for your Monitor" -- \
        sleep 2

    monitor_data=$(hyprctl monitors -j 2>/dev/null)
    monitor_name=$(jq -r '.[0].name // empty' <<< "$monitor_data")
    monitor_resolution=$(jq -r '.[0] | "\(.width)x\(.height)"' <<< "$monitor_data")

    if [[ -z "$monitor_name" || "$monitor_resolution" == "nullxnull" || -z "$monitor_resolution" ]]; then
        echo ">< Could not detect a monitor (is Hyprland running?). Exiting.."
        exit 1
    fi

    display
    refresh_rate=$(gum choose \
                    --header \
                    --header.foreground "#c5c1c1" \
                    --selected.foreground "#c5c1c1" \
                    --cursor.foreground "#c5c1c1" \
                    "60Hz" "75Hz" "120Hz" "144Hz" "165Hz" "180Hz" "200Hz" "240Hz"
                )

    case $refresh_rate in
        *Hz)
            hz="${refresh_rate%Hz}"
            ;;
        *)
            echo -e ">< Nothing will be changed. Exiting.."
            exit 0
            ;;
    esac

    sed -E -i \
        -e "s|^([[:space:]]*)output[[:space:]]*=.*|\1output   = \"$monitor_name\",|" \
        -e "s|^([[:space:]]*)mode[[:space:]]*=.*|\1mode     = \"$monitor_resolution@$hz\",|" \
        -e "s|^([[:space:]]*)position[[:space:]]*=.*|\1position = \"0x0\",|" \
        -e "s|^([[:space:]]*)scale[[:space:]]*=.*|\1scale    = \"1\",|" \
        "$config_file"

    hyprctl reload &>/dev/null
    notify-send -i "$monitor_icon" "Monitor" "$monitor_name → ${monitor_resolution}@${hz}"
fi
