#!/usr/bin/env bash
# Kivvy uninstaller — clears its global shortcuts, unloads the script, disables
# it, and removes the symlink.
set -euo pipefail

DEST="${XDG_DATA_HOME:-$HOME/.local/share}/kwin/scripts/kivvy"

kw() { if command -v kwriteconfig6 >/dev/null; then kwriteconfig6 "$@"; else kwriteconfig5 "$@"; fi; }
qd() { if command -v qdbus6      >/dev/null; then qdbus6      "$@"; else qdbus      "$@"; fi; }

# Release Kivvy's global shortcuts so Meta+` / Meta+; are free again. (We don't
# restore whatever previously held them — re-bind those in System Settings if
# you want them back.)
if command -v gdbus >/dev/null; then
    for id in "['kwin','Kivvy','KWin','Kivvy: open grid']" \
              "['kwin','Kivvy (alternate key)','KWin','Kivvy: open grid (alternate key, e.g. Hebrew layout)']"; do
        gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
            --method org.kde.KGlobalAccel.setForeignShortcut "$id" "@ai []" >/dev/null 2>&1 || true
    done
fi

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
