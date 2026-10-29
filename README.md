# Retroism — Niri + Quickshell desktop rice

A 1990s **Platinum / Windows 95** inspired desktop for **Arch/CachyOS**, built on
**niri** (scrollable tiling) and **Quickshell**, with no Hyprland and no Eww.

![bar](docs/bar.png)

## What's inside

| Area | Implementation |
|---|---|
| Compositor | **niri** — scrollable columns, 2px black borders + teal focus ring, 8px gaps |
| Bar | **Quickshell** (`config/quickshell/retroism`) — Platinum bevels, workspaces, task buttons, media, volume/battery/network wells, tray, clock |
| Launcher | `Mod+A` → centred Quickshell overlay (fuzzy app search) |
| System monitor | `Mod+Space` / bar button → per-core CPU, RAM, swap, load, uptime |
| Notifications | Quickshell `NotificationServer`, Platinum cards |
| Session menu | Lock / Log Out / Reboot / Shut Down |
| Lockscreen | PAM-backed `WlSessionLock` |
| Login | **SDDM** Platinum theme (`sddm-platinum/`) |
| Terminal | **ghostty** — black DOS client area, Win95 16-colour palette, no titlebar |
| Files | **Nemo** (GTK3) — menu bar, toolbar, status bar, list view |
| Browser | **LibreWolf** — `userChrome.css` Platinum chrome (square beveled tabs, sunken URL bar) |
| GTK | `ClassicPlatinumStreamlined` + `RetroismIcons`, `Charcoal` UI / `Monaco` mono |
| Wallpaper | Metropolis via `awww` |

## Install

```fish
git clone <this repo> ~/retroism
cd ~/retroism
fish install.fish --dry-run      # preview
fish install.fish --nemo         # symlink configs + fonts + Nemo prefs
sudo fish scripts/install-sddm-platinum.fish
```

Config directories are **symlinked** into `~/.config`, so editing live edits the
repo. Anything replaced is moved to `~/.config-backup-<timestamp>/`.

The SDDM background is not tracked (12 MB); drop any PNG at
`sddm-platinum/background.png` before installing the theme.

## Keybinds (additive only — upstream niri defaults kept)

| Key | Action |
|---|---|
| `Mod+A` | App launcher (Quickshell) |
| `Mod+T` | ghostty |
| `Mod+E` | Nemo |
| `Mod+ALT+L` | Lock screen |
| `Mod+Shift+Q` | Session menu |
| `Mod+S` | Screenshot: region (slurp) → file + clipboard |
| `Mod+Shift+S` | Screenshot: full screen |
| `Mod+Space` | System monitor |
| `Mod+Grave` | niri overview |
| `Mod+Shift+V` | Clipboard history (cliphist + fuzzel) |

## Dependencies

`niri quickshell ghostty nemo thermald grim slurp wl-clipboard playerctl
brightnessctl jq awww sddm qt6-base qt6-declarative qt6-wayland`

Optional: `ttf-jetbrains-mono`, `adw-gtk3`, `papirus-icon-theme`.

## Notes

- Lockscreen is `wlr-session-lock`: **killing the shell while locked terminates
  the session** (protocol requirement). Escape hatch: `Ctrl+Alt+F2`, then
  `loginctl terminate-session $XDG_SESSION_ID`.
- `Mod+Alt+L` uses the Quickshell locker; swap for `swaylock` if you prefer.
- Suspend is configured for `s2idle` (`scripts/apply-suspend-thermal-fixes.fish`)
  because S3 `deep` hung on resume on this laptop.

MIT.
---

## Support

If you'd like to support the project, you can buy me a coffee on Ko-fi:

**[https://ko-fi.com/jesussavesai](https://ko-fi.com/jesussavesai)**

And honestly -- paid or free, it all means a lot to me. A donation, a star, a bug report, or just using what I make: thank you. ❤️
