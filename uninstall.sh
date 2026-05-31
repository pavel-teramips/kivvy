#!/usr/bin/env bash
# Kivvy uninstaller — unloads the script, disables it, and removes the symlink.
set -euo pipefail

DEST="${XDG_DATA_HOME:-$HOME/.local/share}/kwin/scripts/kivvy"

kw() { if command -v kwriteconfig6 >/dev/null; then kwriteconfig6 "$@"; else kwriteconfig5 "$@"; fi; }
qd() { if command -v qdbus6      >/dev/null; then qdbus6      "$@"; else qdbus      "$@"; fi; }

qd org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript kivvy >/dev/null 2>&1 || true
kw --file kwinrc --group Plugins --key kivvyEnabled false
qd org.kde.KWin /KWin reconfigure || true

if [ -L "$DEST" ] || [ -e "$DEST" ]; then
    rm -rf "$DEST"
    echo "Kivvy: removed $DEST"
else
    echo "Kivvy: nothing to remove at $DEST"
fi

echo "Kivvy uninstalled."
