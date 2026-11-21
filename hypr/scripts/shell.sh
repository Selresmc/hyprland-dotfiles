#!/usr/bin/env bash
# shell.sh — Desktop Shell Manager (Waybar / SwayNC)
#   --toggle (default) : show / hide the Waybar
#   --reload           : reload Waybar config + CSS and SwayNC config
#   --restart          : full restart of Waybar + SwayNC

running() { pgrep -x "$1" >/dev/null 2>&1; }

start_bar() {
    if ! running waybar; then
        waybar &>/dev/null & disown
    fi
    if ! running swaync; then
        swaync &>/dev/null & disown
    fi
}

case "${1:---toggle}" in
    --reload)
        if running waybar; then
            pkill -SIGUSR2 -x waybar     # waybar reloads config + CSS on SIGUSR2
        else
            start_bar
        fi
        command -v swaync-client >/dev/null && swaync-client --reload-config &>/dev/null
        echo "Shell reloaded"
        ;;
    --restart)
        pkill -x waybar 2>/dev/null
        pkill -x swaync 2>/dev/null
        sleep 0.3
        start_bar
        echo "Shell restarted"
        ;;
    --toggle | *)
        if running waybar; then
            pkill -x waybar
            echo "Waybar hidden"
        else
            start_bar
            echo "Waybar shown"
        fi
        ;;
esac

exit 0
