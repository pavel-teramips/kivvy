import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kwin

Item {
    id: root

    // ---- config (read from the KWin Scripts settings UI; see contents/config) ----
    property int cols: 6
    property int rows: 4
    property int cellPx: 100
    readonly property int panelW: cols * cellPx
    readonly property int panelH: rows * cellPx
    readonly property color cellFill: "#33ffffff"
    readonly property color cellStroke: "#88ffffff"
    readonly property color selFill: "#883daee9"
    readonly property color selStroke: "#ff3daee9"
    readonly property color bg: "#cc1e1e1e"

    // ---- runtime state ----
    property var targetClient: null
    property var area: ({ x: 0, y: 0, width: 800, height: 600 })
    property int pressCol: -1
    property int pressRow: -1
    property int dragCol: -1
    property int dragRow: -1
    property bool dragging: false

    function log(msg) { console.log("Kivvy: " + msg) }

    function loadConfig() {
        cols   = KWin.readConfig("Cols", 6)
        rows   = KWin.readConfig("Rows", 4)
        cellPx = KWin.readConfig("CellSize", 100)
    }

    function showOverlay() {
        loadConfig()
        // Always show the panel, even if there's no valid target. If targetClient
        // is null on release, applySelection is a no-op (panel just closes).
        var c = Workspace.activeWindow
        targetClient = (c && c.normalWindow) ? c : null
        var screen = Workspace.activeScreen
        area = Workspace.clientArea(KWin.MaximizeArea, screen, Workspace.currentDesktop)
        pressCol = -1; pressRow = -1; dragCol = -1; dragRow = -1; dragging = false
        dialog.visible = true
        rootItem.forceActiveFocus()
        var tgt = targetClient ? targetClient.resourceClass.toString() : "(none)"
        log("panel shown screen=" + (screen ? screen.name : "?") + " area=" + area.x + "," + area.y + " "
            + area.width + "x" + area.height + " panel=" + panelW + "x" + panelH
            + " target=" + tgt)
    }

    function hideOverlay() {
        dialog.visible = false
        targetClient = null
        dragging = false
    }

    function toggle() {
        if (dialog.visible) {
            hideOverlay()
        } else {
            showOverlay()
        }
    }

    // px,py in panel-local pixels → grid cell
    function cellAt(px, py) {
        var c = Math.floor(px / cellPx)
        var r = Math.floor(py / cellPx)
        if (c < 0) c = 0; else if (c >= cols) c = cols - 1
        if (r < 0) r = 0; else if (r >= rows) r = rows - 1
        return { col: c, row: r }
    }

    function applySelection() {
        if (!targetClient) return
        if (pressCol < 0 || dragCol < 0) return
        var c1 = Math.min(pressCol, dragCol)
        var c2 = Math.max(pressCol, dragCol)
        var r1 = Math.min(pressRow, dragRow)
        var r2 = Math.max(pressRow, dragRow)
        // Map panel cells → screen-space rect using the active screen's work area
        var cw = area.width  / cols
        var ch = area.height / rows
        var rect = Qt.rect(
            Math.round(area.x + c1 * cw),
            Math.round(area.y + r1 * ch),
            Math.round((c2 - c1 + 1) * cw),
            Math.round((r2 - r1 + 1) * ch)
        )
        log("snapping client to " + JSON.stringify(rect))
        targetClient.setMaximize(false, false)
        targetClient.frameGeometry = rect
    }

    Component.onCompleted: {
        loadConfig()
        log("loaded (build v8) cols=" + cols + " rows=" + rows + " cellPx=" + cellPx)
    }

    // Global shortcut: Plasma 6 uses a declarative ShortcutHandler instead of
    // the old KWin.registerShortcut(...) callback.
    //
    // KDE matches global shortcuts by keysym, and its Latin-layout fallback only
    // covers letters/digits — not symbol keys like grave. Under a non-Latin
    // layout the backtick key emits a different symbol (e.g. semicolon on the
    // Hebrew layout), so Meta+` alone wouldn't fire. We register a second binding
    // on Meta+; so the same physical (top-left) key toggles the grid in both the
    // US and Hebrew layouts.
    ShortcutHandler {
        name: "Kivvy"
        text: "Kivvy: open grid"
        sequence: "Meta+`"
        onActivated: root.toggle()
    }

    ShortcutHandler {
        name: "Kivvy (alternate key)"
        text: "Kivvy: open grid (alternate key, e.g. Hebrew layout)"
        sequence: "Meta+;"
        onActivated: root.toggle()
    }

    PlasmaCore.Dialog {
        id: dialog

        location: PlasmaCore.Types.Floating
        type: PlasmaCore.Dialog.Normal
        backgroundHints: PlasmaCore.Types.NoBackground
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        visible: false
        hideOnWindowDeactivate: false

        // Dialog auto-centers on the active screen's work area as `area` changes.
        x: area.x + Math.round((area.width  - panelW) / 2)
        y: area.y + Math.round((area.height - panelH) / 2)

        mainItem: Rectangle {
            id: rootItem
            width: root.panelW
            height: root.panelH
            color: root.bg
            radius: 6
            border.color: "#ff444444"
            border.width: 1
            focus: true

            Keys.onEscapePressed: root.hideOverlay()

            Grid {
                id: gridLayout
                anchors.fill: parent
                anchors.margins: 4
                columns: root.cols
                rows: root.rows
                spacing: 2

                Repeater {
                    model: root.cols * root.rows
                    delegate: Rectangle {
                        width: (gridLayout.width  - (root.cols - 1) * gridLayout.spacing) / root.cols
                        height: (gridLayout.height - (root.rows - 1) * gridLayout.spacing) / root.rows
                        radius: 3
                        property int col: index % root.cols
                        property int row: Math.floor(index / root.cols)
                        property bool inSel: {
                            if (!root.dragging) return false
                            var c1 = Math.min(root.pressCol, root.dragCol)
                            var c2 = Math.max(root.pressCol, root.dragCol)
                            var r1 = Math.min(root.pressRow, root.dragRow)
                            var r2 = Math.max(root.pressRow, root.dragRow)
                            return col >= c1 && col <= c2 && row >= r1 && row <= r2
                        }
                        color: inSel ? root.selFill : root.cellFill
                        border.color: inSel ? root.selStroke : root.cellStroke
                        border.width: 1
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: false
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                preventStealing: true

                onPressed: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        root.hideOverlay()
                        return
                    }
                    var p = root.cellAt(mouse.x, mouse.y)
                    root.pressCol = p.col
                    root.pressRow = p.row
                    root.dragCol = p.col
                    root.dragRow = p.row
                    root.dragging = true
                }

                onPositionChanged: function(mouse) {
                    if (!root.dragging) return
                    var p = root.cellAt(mouse.x, mouse.y)
                    root.dragCol = p.col
                    root.dragRow = p.row
                }

                onReleased: function(mouse) {
                    if (mouse.button !== Qt.LeftButton) return
                    if (!root.dragging) return
                    root.dragging = false
                    root.applySelection()
                    root.hideOverlay()
                }
            }
        }
    }
}
