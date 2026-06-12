# Kivvy — Divvy-style window snapping for KDE Plasma

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![KDE Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6-1d99f3)
![Platform: Linux](https://img.shields.io/badge/platform-Linux%20%C2%B7%20KWin-555)

**Kivvy is "Divvy for KDE"** — a popup-grid window snapper for **KDE Plasma 6**, built as a KWin script.

<!-- DEMO: drop a ~5s screen recording at docs/demo.gif and uncomment the next line to show it here -->
<!-- ![Kivvy in action](docs/demo.gif) -->


Press a global shortcut → a small grid panel pops up centered on screen → click and drag a rectangle across the grid → release → the focused window snaps to that proportional region of the screen.

If you've used [**Divvy**](https://mizage.com/divvy/), **Rectangle**, or **Magnet** on macOS and miss that click-and-drag-on-a-grid workflow on Linux — or you just want a lighter, popup-grid alternative to KWin's built-in tiling or [KZones](https://github.com/gerritdevriese/kzones) — that's what Kivvy does.

> Independent project — not affiliated with, or endorsed by, Mizage (the makers of Divvy). "Divvy" is their trademark; Kivvy just borrows the interaction.

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
script, loads it, and claims the **Meta + `** shortcut — taking it from KDE's
default "Walk Through Windows of Current Application" if needed (that action keeps
its **Alt + `** binding). `uninstall.sh` reverses it and frees the shortcuts.

Run interactively, `install.sh` asks before reassigning a key that's already in
use; run non-interactively it takes the key. Automatic shortcut setup needs
`gdbus` (ships with GLib, present on any Plasma desktop); without it, bind
"Kivvy: open grid" yourself under System Settings → Shortcuts → KWin.

> **Updating later:** `git pull` then re-run `install.sh` refreshes the symlink and
> shortcuts, but KWin caches compiled QML for the life of the session — so changes
> to `contents/ui/main.qml` only take effect after you **log out and back in** (or
> restart KWin). This is a KWin limitation; there's no in-session way around it.

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

Click and drag a rectangle across the grid in the popup panel, then release — the focused window snaps to that proportional region of your screen. The **✕** button (top-right of the panel), Esc, or right-click cancels without snapping.

To trigger from the command line (useful while iterating):
```sh
qdbus6 org.kde.kglobalaccel /component/kwin invokeShortcut Kivvy
```

## Configure

**Permanent defaults** — set the grid columns, rows, and on-screen cell size under
**System Settings → Window Management → KWin Scripts → Kivvy** (the gear/configure
icon next to the entry). Defaults are a 6 × 4 grid at 100 px per cell.

**Quick tweak** — the **⚙** button (top-right of the popup) opens an in-panel
editor with −/+ steppers for columns, rows, and cell size. Changes apply
instantly so you can see them, but are **session-only**: a KWin script can't
persist its own settings, so they reset on the next reload/login. Use the System
Settings page above for values that should stick.

## Limits

- Multi-monitor aware: the grid opens on, and snaps within, the monitor the focused window is on. A single drag still can't span two monitors — each snap stays on one screen.
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
