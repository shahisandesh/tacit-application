// SPDX-License-Identifier: LGPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Tacit.Kit

// Launcher: eight apps at a time in one column, centred on the screen, opened with Ctrl+Space.
// With nothing typed it shows the eight apps used most; typing narrows to the best eight matches.
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
        return apps.map(a => ({ source: a.picture, name: a.name }))
    }

    // The key a use is counted under. Some systems end entry ids with `.desktop` and some do
    // not, so the ending comes off and the counts file speaks one shape.
    function keyOf(id) {
        return String(id).replace(/\.desktop$/, "")
    }

    function launch(index) {
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
    // launcher that is not looked at is already in the way.
    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            if (window.isMine(ToplevelManager.activeToplevel)) window.hadFocus = true
            else if (window.hadFocus) Qt.quit()
        }
    }

    onShownAppsChanged: if (list) list.cursor = 0

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

    WindowGround {}

    Item {
        id: chrome
        anchors.fill: parent

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
            items: window.tilesFor(window.shownApps)
            label: "Apps"
            onActivated: index => window.launch(index)
            onUpRequested: field.focusIn()
        }

        TacitText {
            anchors {
                left: parent.left
                bottom: parent.bottom
                margins: Kit.tokens.space.l
            }
            text: window.query.trim() === ""
                ? "Most used"
                : window.shownApps.length + (window.shownApps.length === 1 ? " match" : " matches")
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
