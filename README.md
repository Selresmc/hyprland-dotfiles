# hyprland-dotfiles

Meine Desktop-Konfiguration aus `~/.hyprconf`: Hyprland, Waybar, Rofi, Kitty, Fish, GTK, Qt, swaync, wlogout, Lockscreens, Scripts und Wallpaper.

## Struktur

| Pfad | Inhalt |
| --- | --- |
| `hypr/` | Hyprland-Config (Lua), Keybinds, Lockscreens, Scripts, Icons, Sounds |
| `hypr/Wallpaper/` | Ca. 1.000 Wallpaper in Kategorien (`cars`, `cyberpunk`, `nature`, `mix`, …) |
| `waybar/`, `rofi/`, `kitty/`, `swaync/`, `wlogout/` | Statusbar, Launcher, Terminal, Benachrichtigungen, Logout-Menü |
| `fish/`, `nvim/`, `yazi/`, `btop/`, `fastfetch/` | Shell, Editor, Filemanager, Systemmonitor, Fetch |
| `gtk-3.0/`, `gtk-4.0/`, `Kvantum/`, `qt5ct/`, `qt6ct/` | Theme-Anpassungen |

## Einrichtung auf einem neuen System

```bash
git clone https://github.com/<DEIN_USER>/hyprland-dotfiles.git ~/.hyprconf
ln -s ~/.hyprconf/hypr ~/.config/hypr
```

Die restlichen Configs werden üblicherweise ebenfalls nach `~/.config/<name>` verlinkt, z. B.:

```bash
ln -s ~/.hyprconf/waybar ~/.config/waybar
ln -s ~/.hyprconf/rofi ~/.config/rofi
ln -s ~/.hyprconf/kitty ~/.config/kitty
```

## Hinweise

- **Wallpaper:** Die Bilder liegen direkt in `hypr/Wallpaper/` (ca. 3,5 GB). Das Repo ist deshalb groß; beim Klonen also Geduld haben. Einzelne Dateien bleiben unterhalb des GitHub-Limits von 100 MB.
- **Generierte Farben:** Einige Dateien (z. B. `hypr/configs/colors-hyprland.lua`, `waybar/theme.css`) sind Symlinks nach `~/.cache/wal` und werden von pywal erzeugt. Sie sind absichtlich per `.gitignore` ausgeschlossen und müssen nach dem Klonen neu generiert bzw. verlinkt werden.
- **Absolute Pfade:** Manche Symlinks zeigen auf absolute Pfade unter `/home/franzgauglhofer` (z. B. Themes unter `~/.themes`). Auf einem anderen System müssen diese angepasst werden.
- **Aktualisieren:** `cd ~/.hyprconf && git add -A && git commit -m "..." && git push`

## Lizenz der Wallpaper

Die Wallpaper stammen von externen Quellen (u. a. Wallhaven). Die jeweiligen Urheberrechte bleiben bei den Erstellern – bitte vor Weiterverwendung prüfen.
