#!/usr/bin/env bash
# Kivvy installer — symlinks this repo into KWin's script directory, enables it,
# reloads KWin, and claims the global shortcut (taking it from any conflicting
# binding). Re-run any time after pulling changes.
#
# NOTE ON RELOADS: re-running this picks up config/enable state, but KWin caches
# compiled QML in memory for the life of the session — so *code* edits to
# contents/ui/main.qml only take effect after you log out and back in (or restart
# KWin). This is a KWin limitation, not something the script can work around.
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

# Hot-reload the declarative script so a *fresh* install applies without logging
# out (works on Wayland, where KWin can't be restarted in place). On an existing
# session this only re-instantiates the already-compiled script — see the note at
# the top about code edits needing a logout.
if qd org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded kivvy >/dev/null 2>&1; then
    qd org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript kivvy || true
    qd org.kde.KWin /Scripting org.kde.kwin.Scripting.loadDeclarativeScript "$SRC/contents/ui/main.qml" kivvy || true
    qd org.kde.KWin /Scripting org.kde.kwin.Scripting.start || true
fi

# ---------------------------------------------------------------------------
# Global shortcut setup.
#
# Kivvy's default keys are Meta+` (primary) and Meta+; (alternate, for non-Latin
# layouts where the top-left key isn't a backtick). On most Plasma installs Meta+`
# is already KDE's default for "Walk Through Windows of Current Application", so a
# plain registration loses the race and Kivvy ends up with no key. We fix that
# here by taking the key from whoever holds it.
#
# Global shortcuts on Plasma are kept in a live in-memory registry (hosted by
# kglobalacceld, or by kwin_wayland itself on some builds). Editing
# kglobalshortcutsrc by hand does NOT change the running bindings — only the
# org.kde.KGlobalAccel D-Bus API does (and it also persists to the file). We use
# `gdbus` because it marshals the array/stringlist arguments that qdbus can't.
#
# Key integers are Qt key codes OR'd with modifier flags:
#   Meta = 0x10000000, Alt = 0x08000000   |   ` (Key_QuoteLeft) = 0x60, ; = 0x3B
#   Meta+` = 0x10000060 = 268435552        Meta+; = 0x1000003B = 268435515
# ---------------------------------------------------------------------------
KEY_PRIMARY=268435552   # Meta+`
KEY_ALT=268435515       # Meta+;

# Kivvy's own action ids: [componentUnique, actionUnique, componentFriendly, actionFriendly].
# These must match the ShortcutHandler name/text in contents/ui/main.qml.
KIVVY_PRIMARY_ID="['kwin','Kivvy','KWin','Kivvy: open grid']"
KIVVY_ALT_ID="['kwin','Kivvy (alternate key)','KWin','Kivvy: open grid (alternate key, e.g. Hebrew layout)']"

ga() { # call a method on org.kde.KGlobalAccel; args after method are GVariant literals
    gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
        --method "org.kde.KGlobalAccel.$1" "${@:2}"
}

# claim KEY for Kivvy, displacing any current holder (keeping that holder's other keys).
#   $1 = key int   $2 = Kivvy action id   $3 = Kivvy's own uniqueName   $4 = human label
claim_shortcut() {
    local key="$1" kivvy_id="$2" kivvy_uniq="$3" label="$4"
    local info; info="$(ga getGlobalShortcutsByKey "$key" 2>/dev/null || true)"

    # No holder at all → just assign to Kivvy.
    if ! grep -q "'" <<<"$info"; then
        ga setForeignShortcut "$kivvy_id" "[$key]" >/dev/null
        echo "Kivvy: bound $label (was free)"
        return
    fi

    # Parse the current holder. The struct is 6 single-quoted strings then 2 int
    # arrays: (uniqueName, friendlyName, compUnique, compFriendly, ctxU, ctxF, keys, defaultKeys).
    mapfile -t toks < <(grep -oE "'[^']*'" <<<"$info" | sed "s/^'//; s/'\$//")
    local h_uniq="${toks[0]}" h_friendly="${toks[1]}" h_comp="${toks[2]}" h_compf="${toks[3]}"

    if [ "$h_uniq" = "$kivvy_uniq" ]; then
        echo "Kivvy: $label already bound"
        return
    fi

    if [ -t 0 ]; then
        local ans
        read -r -p "Kivvy: $label is currently used by \"$h_friendly\". Reassign it to Kivvy? [Y/n] " ans
        case "$ans" in
            [nN]*) echo "Kivvy: left \"$h_friendly\" on $label (Kivvy will rely on its other key)"; return ;;
        esac
    fi

    # Remaining keys for the displaced action = its current keys minus this one.
    local cur_keys remaining
    cur_keys="$(grep -oE '\[[-0-9, ]*\]' <<<"$info" | head -1)"
    remaining="$(tr -d '[] ' <<<"$cur_keys" | tr ',' '\n' | grep -vx "$key" | paste -sd, -)"

    ga setForeignShortcut "['$h_comp','$h_uniq','$h_compf','$h_friendly']" "[$remaining]" >/dev/null
    ga setForeignShortcut "$kivvy_id" "[$key]" >/dev/null
    echo "Kivvy: claimed $label (was \"$h_friendly\"); that action keeps its other keys"
}

if command -v gdbus >/dev/null; then
    sleep 0.5  # give KWin a moment to register the script's actions
    claim_shortcut "$KEY_PRIMARY" "$KIVVY_PRIMARY_ID" "Kivvy"                 "Meta+\`"
    claim_shortcut "$KEY_ALT"     "$KIVVY_ALT_ID"     "Kivvy (alternate key)" "Meta+;"
else
    echo "Kivvy: 'gdbus' not found — skipping automatic shortcut setup."
    echo "      Bind 'Kivvy: open grid' under System Settings → Shortcuts → KWin."
fi

cat <<'EOF'

Kivvy installed. Press Meta + ` (Win + backtick) to open the grid.

Rebind under: System Settings → Shortcuts → KWin → "Kivvy: open grid"
Trigger from CLI: qdbus6 org.kde.kglobalaccel /component/kwin invokeShortcut Kivvy

If the grid doesn't appear, log out and back in once so KWin picks up the script.
EOF
