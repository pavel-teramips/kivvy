#!/usr/bin/env bash
# Kivvy installer — symlinks this repo into KWin's script directory, enables it,
# and reloads KWin. Re-run any time after pulling changes.
set -euo pipefail

# Resolve the directory this script lives in (the repo root), following symlinks.
SRC="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/kwin/scripts/kivvy"

# Pick the Plasma 6 tools, falling back to the Plasma 5 names if that's all there is.
kw() { if command -v kwriteconfig6 >/dev/null; then kwriteconfig6 "$@"; else kwriteconfig5 "$@"; fi; }
qd() { if command -v qdbus6      >/dev/null; then qdbus6      "$@"; else qdbus      "$@"; fi; }

echo "Kivvy: source = $SRC"
echo "Kivvy: dest   = $DEST"

# (Re)create the symlink.
mkdir -p "$(dirname "$DEST")"
if [ -L "$DEST" ] || [ -e "$DEST" ]; then
    echo "Kivvy: removing existing $DEST"
    rm -rf "$DEST"
fi
ln -s "$SRC" "$DEST"

# Enable the script and tell KWin to reload its config.
kw --file kwinrc --group Plugins --key kivvyEnabled true
qd org.kde.KWin /KWin reconfigure || true

# Hot-reload the declarative script so changes apply without logging out
# (works on Wayland, where KWin can't be restarted in place).
if qd org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded kivvy >/dev/null 2>&1; then
    qd org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript kivvy || true
    qd org.kde.KWin /Scripting org.kde.kwin.Scripting.loadDeclarativeScript "$SRC/contents/ui/main.qml" kivvy || true
    qd org.kde.KWin /Scripting org.kde.kwin.Scripting.start || true
fi

cat <<'EOF'

Kivvy installed. Press Meta + ` (Win + backtick) to open the grid.

Rebind under: System Settings → Shortcuts → KWin → "Kivvy: open grid"
Trigger from CLI: qdbus6 org.kde.kglobalaccel /component/kwin invokeShortcut Kivvy

If the shortcut does nothing, log out and back in once so KWin picks up the script.
EOF
