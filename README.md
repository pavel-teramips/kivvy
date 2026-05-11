# Kivvy

A popup-grid window snapper for KDE Plasma, inspired by [Divvy on Windows/Mac](https://mizage.com/divvy/).

Press a global shortcut → a small grid panel appears centered on screen → click and drag across cells → release → the focused window snaps to the corresponding proportional region of the screen.

## Status

v0.1 — initial single-monitor build for Plasma 5.27.

- Shortcut: `Meta+\`` (Win + backtick)
- Grid: 6 columns × 4 rows
- Panel size: 600×400 px

## Install

```sh
ln -s "$PWD" ~/.local/share/kwin/scripts/kivvy
```

Then enable in **System Settings → Window Management → KWin Scripts**, or via:

```sh
kwriteconfig5 --file kwinrc --group Plugins --key kivvyEnabled true
qdbus org.kde.KWin /KWin reconfigure
```

Bind a shortcut via **System Settings → Shortcuts → KWin → "Kivvy: open grid"** (or accept the default).

## Trigger from the command line

```sh
qdbus org.kde.kglobalaccel /component/kwin invokeShortcut Kivvy
```

## Plasma 6 notes

Tested against Plasma 5.27.x. Needs minor changes for Plasma 6:

- `workspace.activeClient` → `workspace.activeWindow`
- `client.geometry =` → `client.frameGeometry =`
- Drop version numbers from `org.kde.kwin 2.0` / `org.kde.plasma.core 2.0` imports
