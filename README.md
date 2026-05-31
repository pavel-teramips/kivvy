# Kivvy

A [Divvy](https://mizage.com/divvy/)-style popup-grid window snapper for **KDE Plasma**.

Press a global shortcut → a small grid panel appears centered on screen → click and drag across the grid → release → the focused window snaps to that proportional region of the screen.

## Why "Kivvy"

K for KDE. It's a KWin script — KDE-only by design. Won't work on GNOME or any other desktop (those use different window managers with their own extension APIs).

| Desktop | Backend | Status |
|---|---|---|
| **KDE Plasma 6** | Wayland | ✓ tested (Plasma 6.6.4) |
| **KDE Plasma 6** | X11 | should work, untested |
| **KDE Plasma 5** | X11 / Wayland | needs a small reverse port (see below) |
| GNOME / Hyprland / sway / i3 / XFCE | anything | not supported, won't be |

## Install

```sh
git clone https://github.com/pavel-teramips/kivvy.git ~/dev/kivvy
~/dev/kivvy/install.sh
```

`install.sh` symlinks the repo into `~/.local/share/kwin/scripts/`, enables the
script, and hot-reloads KWin — so it works on Wayland without logging out, and
you can re-run it any time after pulling changes. `uninstall.sh` reverses it.

<details>
<summary>Manual install (what the script does)</summary>

```sh
ln -s ~/dev/kivvy ~/.local/share/kwin/scripts/kivvy
kwriteconfig6 --file kwinrc --group Plugins --key kivvyEnabled true
qdbus6 org.kde.KWin /KWin reconfigure
```
</details>

If the shortcut does nothing right after install, log out and back in once so KWin picks up the script source.

## Use

Default shortcut: **Meta + \`** (Win + backtick).

Non-Latin layouts (Hebrew, Arabic, …) don't have a backtick key, and KDE's
shortcut fallback doesn't cover symbol keys — so the same physical top-left key
is also bound on **Meta + ;** (which is what that key emits under the Hebrew
layout). Either opens the grid.

You can rebind both under **System Settings → Shortcuts → KWin** ("Kivvy: open grid" and "… (alternate key)").

Click and drag a rectangle across the grid in the popup panel, then release — the focused window snaps to that proportional region of your screen. Esc or right-click cancels.

To trigger from the command line (useful while iterating):
```sh
qdbus6 org.kde.kglobalaccel /component/kwin invokeShortcut Kivvy
```

## Configure

Set the grid columns, rows, and on-screen cell size under **System Settings →
Window Management → KWin Scripts → Kivvy** (the gear/configure icon next to the
entry). Defaults are a 6 × 4 grid at 100 px per cell.

## Limits

- Single monitor (panel always opens on the active screen, but no cross-monitor drag yet)
- One shortcut for the panel; no per-region shortcuts like `Meta+Alt+Left → snap left half`

## Plasma 5 reverse-port notes

Kivvy targets Plasma 6. To run it on Plasma 5, reverse these changes in
`contents/ui/main.qml`:

| Plasma 6 (current) | Plasma 5 |
|---|---|
| `import org.kde.kwin` | `import org.kde.kwin 2.0` |
| `import org.kde.plasma.core as PlasmaCore` | `import org.kde.plasma.core 2.0 as PlasmaCore` |
| `Workspace.activeWindow` | `workspace.activeClient` |
| `client.frameGeometry = …` | `client.geometry = …` |
| `ShortcutHandler { … }` element | `KWin.registerShortcut(…)` in `Component.onCompleted` |

## Credits

Modeled on [Divvy](https://mizage.com/divvy/) (Mizage) for macOS and Windows. KWin script plumbing patterns cribbed from [KZones v0.6](https://github.com/gerritdevriese/kzones/tree/v0.6), which is the closest existing Plasma 5 KWin overlay script.

## License

MIT.
