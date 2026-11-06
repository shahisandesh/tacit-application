// SPDX-License-Identifier: LGPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Tacit.Kit
import "emoji.js" as Emoji

// Launcher: eight apps at a time in one column, centred on the screen, opened with Ctrl+Space.
// With nothing typed it shows the eight apps used most; typing narrows to the best eight matches.
// Typing a sum (2 + 2) turns the list into a calculator, and Enter copies the answer; typing a
// colon turns it into the emoji list, and Enter copies the chosen one.
// Rows are icon and name only. Enter, or a double click, opens; Escape closes, and so does a
// click outside, since a launcher that lingers has already failed. Uses are counted in a small
// file, so the first eight learn the person's habits as they go.
FloatingWindow {
    id: window
    title: "Launcher"
    color: "transparent"
    visible: true
    implicitWidth: 560
    implicitHeight: 624

    property string query: ""
    property var counts: ({})
    property bool hadFocus: false

    readonly property int shown: 8
    // 0 lists apps, 1 does a sum, 2 lists emoji
    readonly property int mode: {
        const q = window.query.trim()
        if (q.startsWith(":")) return 2
        if (q !== "" && /^[\d\s+\-*/%^().]+$/.test(q) && /\d/.test(q) && /[+\-*/%^]/.test(q)) return 1
        return 0
    }
    // Quickshell reads the .desktop files after the window is made, and the list arrives a
    // moment later; this counts those arrivals so the app list is built again when they do.
    property int entriesRev: 0
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { window.entriesRev++ }
    }
    readonly property string usageDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/tacit-launcher"
    readonly property string usagePath: usageDir + "/usage.json"

    // Every app once, in name order, with the words the person might type already folded in.
    readonly property var allApps: {
        window.entriesRev
        const seen = {}
        const out = []
        for (const entry of DesktopEntries.applications.values) {
            if (!entry || !entry.id || seen[entry.id]) continue
            seen[entry.id] = true
            let picture = String(entry.icon ?? "")
            if (picture !== "" && !picture.startsWith("/")) picture = Quickshell.iconPath(picture)
            out.push({
                id: entry.id,
                name: entry.name,
                lower: String(entry.name).toLowerCase(),
                intent: (String(entry.genericName ?? "") + " " + (entry.keywords ?? []).join(" ")).toLowerCase(),
                comment: String(entry.comment ?? "").toLowerCase(),
                picture: picture,
                entry: entry
            })
        }
        out.sort((a, b) => a.lower.localeCompare(b.lower))
        return out
    }

    // At rest: the eight most used, and the alphabet's first while nothing is used yet.
    // Typing: a name hit beats a word the app merely answers to, which beats a word in its
    // description; an exact name wins outright. Always at most eight.
    readonly property var shownApps: {
        const needle = window.query.trim().toLowerCase()
        const used = a => window.counts[window.keyOf(a.id)] ?? 0
        if (needle === "") {
            const list = window.allApps.slice()
            list.sort((a, b) => (used(b) - used(a)) || a.lower.localeCompare(b.lower))
            return list.slice(0, window.shown)
        }
        const hit = []
        for (const a of window.allApps) {
            let s = 0
            if (a.lower === needle) s = 100
            else if (a.lower.startsWith(needle)) s = 80
            else if (a.lower.includes(needle)) s = 60
            else if (a.intent.includes(needle)) s = 40
            else if (a.comment.includes(needle)) s = 25
            if (s > 0) hit.push({ app: a, score: s })
        }
        hit.sort((x, y) => y.score - x.score || x.app.lower.length - y.app.lower.length
            || x.app.lower.localeCompare(y.app.lower))
        return hit.slice(0, window.shown).map(o => o.app)
    }

    function tilesFor(apps) {
        return apps.map(a => ({ source: a.picture, name: a.name, glyph: "", copy: "" }))
    }

    // The sum only when the words are wholly a sum: digits, spaces and the four signs.
    // Nothing else reaches the calculator's maths.
    function calcOf(q) {
        try {
            const v = Number(Function("\"use strict\"; return (" + q.replace(/\^/g, "**") + ")")())
            if (!isFinite(v) || Math.abs(v) > 1e15) return null
            return Math.round(v * 1e10) / 1e10
        } catch (e) {
            return null
        }
    }

    // The rows the list shows, whichever mode the typing has picked. Each row is
    // { source, name, glyph, copy }; the copy is what Enter puts on the clipboard.
    readonly property var shownRows: {
        const q = window.query.trim()
        if (window.mode === 1) {
            const v = window.calcOf(q)
            if (v !== null)
                return [{ source: "", name: q + "  =  " + v, glyph: "=", copy: String(v) }]
        } else if (window.mode === 2) {
            return Emoji.matches(q.slice(1).trim()).map(n => ({
                source: "", name: ":" + n + ":", glyph: Emoji.MAP[n], copy: Emoji.MAP[n]
            }))
        }
        return window.tilesFor(window.shownApps)
    }

    // The key a use is counted under. Some systems end entry ids with `.desktop` and some do
    // not, so the ending comes off and the counts file speaks one shape.
    function keyOf(id) {
        return String(id).replace(/\.desktop$/, "")
    }

    function launch(index) {
        // calculator and emoji rows copy their answer instead of opening anything
        if (window.mode !== 0) {
            const row = window.shownRows[index]
            if (!row || row.copy === "") return
            clipboard.payload = row.copy
            clipboard.running = true
            return
        }
        const app = window.shownApps[index]
        if (!app) return
        const c = Object.assign({}, window.counts)
        const key = window.keyOf(app.id)
        c[key] = (c[key] ?? 0) + 1
        window.counts = c
        try {
            app.entry.execute()
        } catch (e) {
            notice.show("Could not open " + app.name + ".", "")
            return
        }
        usageWriter.payload = JSON.stringify(c)
        usageWriter.stdinEnabled = true
        usageWriter.running = true
        quitTimer.restart()
    }

    function isMine(t) {
        return !!t && t.title === window.title && String(t.appId ?? "") === Quickshell.appId
    }

    // A click outside moves the focus to another window, and the window system tells us; the
    // launcher that is not looked at is already in the way. But moving the mouse is not looking
    // away: a crossing pointer hands focus between windows in fits and starts, so the leaving
    // must hold for a moment with the pointer outside the launcher before it closes.
    readonly property bool pointerInside: pointer.hovered

    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            if (window.isMine(ToplevelManager.activeToplevel)) {
                window.hadFocus = true
                focusTimer.stop()
            } else if (window.hadFocus && !window.pointerInside) focusTimer.restart()
        }
    }
    Timer {
        id: focusTimer
        interval: 500
        onTriggered: if (!window.pointerInside) Qt.quit()
    }

    onShownRowsChanged: if (list) list.cursor = 0

    // The counts, read once at open and written after each launch.
    FileView {
        id: usageReader
        path: window.usagePath
        blockLoading: true
        printErrors: false
        onLoaded: {
            try { window.counts = JSON.parse(usageReader.text()) } catch (e) { window.counts = ({}) }
        }
    }
    Process {
        id: usageWriter
        property string payload: "{}"
        stdinEnabled: true
        command: ["bash", "-c", "mkdir -p \"$1\" && cat > \"$1/usage.json\"", "--", window.usageDir]
        onStarted: {
            usageWriter.write(usageWriter.payload)
            usageWriter.stdinEnabled = false
        }
        onExited: Qt.quit()
    }
    Timer {
        id: quitTimer
        interval: 400
        onTriggered: Qt.quit()
    }
    Process {
        id: clipboard
        property string payload: ""
        stdinEnabled: true
        command: ["wl-copy"]
        onStarted: {
            clipboard.write(clipboard.payload)
            clipboard.stdinEnabled = false
        }
        onExited: Qt.quit()
    }

    WindowGround {}

    // A click on a window moves the focus, and the watch above closes the launcher. A click on
    // the bare desktop moves nothing, so this transparent sheet under every window catches it:
    // the background layer takes the clicks no window wants, and one of those is a click outside.
    Instantiator {
        model: Quickshell.screens
        PanelWindow {
            id: clickCatcher
            required property var modelData
            visible: true
            screen: modelData
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Background
            color: "transparent"
            focusable: false
            anchors { left: true; right: true; top: true; bottom: true }

            TapHandler { onTapped: Qt.quit() }
        }
    }

    Item {
        id: chrome
        anchors.fill: parent

        // the launcher's own ground, watched only for where the pointer is; it takes no clicks
        HoverHandler {
            id: pointer
            acceptedButtons: Qt.NoButton
        }

        Keys.onEscapePressed: event => {
            Qt.quit()
            event.accepted = true
        }

        Row {
            id: searchRow
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: Kit.tokens.space.l
                rightMargin: Kit.tokens.space.l
                topMargin: Kit.tokens.space.l
            }
            spacing: Kit.tokens.space.m

            Symbol {
                id: searchIcon
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                color: Kit.tokens.inkSec
            }
            Field {
                id: field
                width: searchRow.width - searchIcon.width - searchRow.spacing
                height: Kit.tokens.height.field
                hint: "Search apps"
                label: "Search apps"
                text: Quickshell.env("LAUNCHER_Q") ?? ""
                onTextChanged: window.query = field.text
                onAccepted: window.launch(list.cursor >= 0 ? list.cursor : 0)
                Keys.onDownPressed: event => {
                    list.forceActiveFocus(Qt.TabFocusReason)
                    list.moveTo(list.cursor < 0 ? 0 : list.cursor)
                    event.accepted = true
                }
            }
        }

        AppList {
            id: list
            anchors {
                left: parent.left
                right: parent.right
                top: searchRow.bottom
                topMargin: Kit.tokens.space.m
            }
            items: window.shownRows
            label: window.mode === 1 ? "Calculator" : window.mode === 2 ? "Emoji" : "Apps"
            onActivated: index => window.launch(index)
            onUpRequested: field.focusIn()
        }

        TacitText {
            anchors {
                left: parent.left
                bottom: parent.bottom
                margins: Kit.tokens.space.l
            }
            text: window.mode === 1 ? "Enter copies the answer"
                : window.mode === 2 ? "Enter copies the emoji"
                : window.query.trim() === ""
                ? "Most used"
                : window.shownRows.length + (window.shownRows.length === 1 ? " match" : " matches")
            size: "meta"
            ink: "faint"
        }
        TacitText {
            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: Kit.tokens.space.l
            }
            text: "Arrows choose, Enter opens, Escape closes"
            size: "meta"
            ink: "faint"
        }
    }

    Notice {
        id: notice
    }

    Component.onCompleted: {
        Kit.watchKeys(window)
        field.focusIn()
    }
}
