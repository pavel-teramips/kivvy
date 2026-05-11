# Kivvy

A [Divvy](https://mizage.com/divvy/)-style popup-grid window snapper for **KDE Plasma**.

Press a global shortcut → a small grid panel appears centered on screen → click and drag across the grid → release → the focused window snaps to that proportional region of the screen.

## Why "Kivvy"

K for KDE. It's a KWin script — KDE-only by design. Won't work on GNOME or any other desktop (those use different window managers with their own extension APIs).

| Desktop | Backend | Status |
|---|---|---|
| **KDE Plasma 5** | X11 | ✓ tested (Plasma 5.27.12 on Kubuntu 24.04) |
| **KDE Plasma 5** | Wayland | should work, untested |
| **KDE Plasma 6** | X11 / Wayland | needs ~10 lines of porting (see below) |
| GNOME / Hyprland / sway / i3 / XFCE | anything | not supported, won't be |

## Install

```sh
git clone https://github.com/pavel-teramips/kivvy.git ~/dev/kivvy
ln -s ~/dev/kivvy ~/.local/share/kwin/scripts/kivvy
kwriteconfig5 --file kwinrc --group Plugins --key kivvyEnabled true
qdbus org.kde.KWin /KWin reconfigure
```

Or enable through **System Settings → Window Management → KWin Scripts → Get New…** once Kivvy is published there. Log out and back in once after enabling to ensure KWin picks up the script source.

## Use

Default shortcut: **Meta + \`** (Win + backtick).

You can rebind it under **System Settings → Shortcuts → KWin → Kivvy: open grid**.

Click and drag a rectangle across the 6×4 grid in the popup panel, then release — the focused window snaps to that proportional region of your screen. Esc or right-click cancels.

To trigger from the command line (useful while iterating):
```sh
qdbus org.kde.kglobalaccel /component/kwin invokeShortcut Kivvy
```

## v0.1 limits

- 6 × 4 grid, hardcoded
- Single monitor (panel always opens on the active screen, but no cross-monitor drag yet)
- One shortcut for the panel; no per-region shortcuts like `Meta+Alt+Left → snap left half`
- No config UI

## Plasma 6 port notes

Three small renames in `contents/ui/main.qml`:

| Plasma 5 | Plasma 6 |
|---|---|
| `workspace.activeClient` | `workspace.activeWindow` |
| `client.geometry = …` | `client.frameGeometry = …` |
| `import org.kde.kwin 2.0` | `import org.kde.kwin` |
| `import org.kde.plasma.core 2.0 as PlasmaCore` | `import org.kde.plasma.core as PlasmaCore` |

## Credits

Modeled on [Divvy](https://mizage.com/divvy/) (Mizage) for macOS and Windows. KWin script plumbing patterns cribbed from [KZones v0.6](https://github.com/gerritdevriese/kzones/tree/v0.6), which is the closest existing Plasma 5 KWin overlay script.

## License

MIT.
