import QtQuick 2.15
import org.kde.kwin 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

PlasmaCore.Dialog {
    id: root

    // ---- config (hardcoded for v1) ----
    readonly property int cols: 6
    readonly property int rows: 4
    readonly property int cellPx: 100
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

    location: PlasmaCore.Types.Floating
    type: PlasmaCore.Dialog.Normal
    backgroundHints: PlasmaCore.Types.NoBackground
    flags: Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    visible: false
    hideOnWindowDeactivate: false

    // Property bindings: dialog auto-centers as `area` changes.
    x: area.x + Math.round((area.width  - panelW) / 2)
    y: area.y + Math.round((area.height - panelH) / 2)

    function log(msg) { console.log("Kivvy: " + msg) }

    function showOverlay() {
        // Always show the panel, even if there's no valid target. If targetClient
        // is null on release, applySelection is a no-op (panel just closes).
        var c = workspace.activeClient
        targetClient = (c && c.normalWindow) ? c : null
        var screen = workspace.activeScreen
        area = workspace.clientArea(KWin.MaximizeArea, screen, workspace.currentDesktop)
        pressCol = -1; pressRow = -1; dragCol = -1; dragRow = -1; dragging = false
        root.visible = true
        rootItem.forceActiveFocus()
        var tgt = targetClient ? targetClient.resourceClass.toString() : "(none)"
        log("panel shown screen=" + screen + " area=" + area.x + "," + area.y + " "
            + area.width + "x" + area.height + " panel=" + panelW + "x" + panelH
            + " target=" + tgt)
    }

    function hideOverlay() {
        root.visible = false
        targetClient = null
        dragging = false
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
        targetClient.geometry = rect
    }

    Component.onCompleted: {
        KWin.registerShortcut("Kivvy", "Kivvy: open grid", "Meta+QuoteLeft", function() {
            if (root.visible) {
                hideOverlay()
            } else {
                showOverlay()
            }
        })
        log("registered shortcut Meta+` (build v5)")
    }

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
