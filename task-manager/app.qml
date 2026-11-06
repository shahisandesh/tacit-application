// Task manager: what the desktop is spending, and one way to take it back.
// The list is programs, not threads: tacit-mem's counting (real share, PSS plus the program's swap),
// grouped by executable, sorted by memory. Enter moves to the End task ring, which asks first,
// because an ended program does not come back.
// Run: qs -p app.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Tacit.Kit

FloatingWindow {
    id: window
    title: "Task Manager"
    color: "transparent"
    visible: true
    implicitWidth: 900
    implicitHeight: 700
    Component.onCompleted: Kit.watchKeys(window)

    property var procs: []
    property var stats: ({ total: 0, used: 0, free: 0, swap: 0, cpu: 0, ncpu: 1, root: false,
                          disk: ({ read: 0, write: 0, total: 0, free: 0 }), gpu: null })
    property string pendingName: ""

    // what the list shows: the read programs, narrowed by the search, biggest first as the script sorts them
    readonly property var shown: {
        const f = search.text.trim().toLowerCase()
        return window.procs
            .filter(p => f === "" || p.name.toLowerCase().includes(f))
            .map(p => ({ name: p.name, kind: p.kind, mem: p.mem, cpu: p.cpu, icon: p.icon, pids: p.pids }))
    }
    readonly property var target: tasks.cursor >= 0 && tasks.cursor < shown.length ? shown[tasks.cursor] : null

    function kindWord(kind) {
        return kind === "apps" ? "Tacit app" : kind === "desktop" ? "Desktop" : kind === "system" ? "System" : ""
    }
    // the script's figures are kilobytes; words a person can hold in mind
    function memText(kb) {
        return kb >= 1048576 ? (kb / 1048576).toFixed(1) + " GB" : Math.max(1, Math.round(kb / 1024)) + " MB"
    }
    function rateText(kbps) {
        return kbps >= 1024 ? (kbps / 1024).toFixed(1) + " MB/s" : Math.round(kbps) + " KB/s"
    }

    WindowGround {}

    Item {
        id: chrome
        anchors.fill: parent
        // Escape leaves, unless the ring is mid-question: then it first backs out of the ask
        Keys.onEscapePressed: event => { if (!slab.asking) Qt.quit() }

        ColumnLayout {
            anchors {
                top: parent.top; left: parent.left; right: parent.right; bottom: parent.bottom
                margins: Kit.tokens.space.l
                topMargin: Kit.tokens.space.l + 10
                bottomMargin: Kit.tokens.space.m + 44 + Kit.tokens.space.m
            }
            spacing: Kit.tokens.space.m

            // four gauges, each a word, a figure, a bar and a quieter line under it
            RowLayout {
                Layout.fillWidth: true
                spacing: Kit.tokens.space.l

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kit.tokens.space.s
                    TacitText { text: "Memory"; ink: "meta"; size: Kit.tokens.size.meta }
                    TacitText { text: window.memText(window.stats.used) + " / " + window.memText(window.stats.total); ink: "main"; size: Kit.tokens.size.body }
                    Progress { Layout.fillWidth: true; value: window.stats.total > 0 ? window.stats.used / window.stats.total : 0; label: "Memory used" }
                    TacitText { text: window.memText(window.stats.free) + " free" + (window.stats.swap > 102400 ? " · " + window.memText(window.stats.swap) + " in swap" : ""); ink: "faint"; size: Kit.tokens.size.meta }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kit.tokens.space.s
                    TacitText { text: "CPU"; ink: "meta"; size: Kit.tokens.size.meta }
                    TacitText { text: Math.round(window.stats.cpu) + " %"; ink: "main"; size: Kit.tokens.size.body }
                    Progress { Layout.fillWidth: true; value: Math.min(1, window.stats.cpu / 100); label: "CPU busy" }
                    TacitText { text: window.stats.ncpu + " cores"; ink: "faint"; size: Kit.tokens.size.meta }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kit.tokens.space.s
                    TacitText { text: "Disk"; ink: "meta"; size: Kit.tokens.size.meta }
                    TacitText { text: window.stats.disk.total > 0 ? window.memText(window.stats.disk.total - window.stats.disk.free) + " / " + window.memText(window.stats.disk.total) : "—"; ink: "main"; size: Kit.tokens.size.body }
                    Progress { Layout.fillWidth: true; value: window.stats.disk.total > 0 ? (window.stats.disk.total - window.stats.disk.free) / window.stats.disk.total : 0; label: "Disk used" }
                    TacitText { text: "Read " + window.rateText(window.stats.disk.read) + " · Write " + window.rateText(window.stats.disk.write); ink: "faint"; size: Kit.tokens.size.meta }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kit.tokens.space.s
                    TacitText { text: "GPU"; ink: "meta"; size: Kit.tokens.size.meta }
                    TacitText { text: window.stats.gpu ? Math.round(window.stats.gpu.busy) + " %" : "—"; ink: "main"; size: Kit.tokens.size.body }
                    Progress { Layout.fillWidth: true; value: window.stats.gpu ? Math.min(1, window.stats.gpu.busy / 100) : 0; label: "GPU busy" }
                    TacitText { text: window.stats.gpu && window.stats.gpu.mem_total > 0 ? window.memText(window.stats.gpu.mem_used) + " of " + window.memText(window.stats.gpu.mem_total) : window.stats.gpu ? "No memory figure" : "No reading"; ink: "faint"; size: Kit.tokens.size.meta }
                }
            }

            Field {
                id: search
                Layout.fillWidth: true
                hint: "Search programs"
                label: "Search programs"
            }

            RowList {
                id: tasks
                Layout.fillWidth: true
                Layout.fillHeight: true
                label: "Programs by memory"
                model: window.shown

                delegate: ListRow {
                    required property int index
                    required property var modelData

                    width: tasks.rowWidth
                    picture: modelData.icon === "" ? "" : "file://" + modelData.icon
                    name: modelData.name
                    aside: window.kindWord(modelData.kind)
                    facts: [window.memText(modelData.mem), Math.round(modelData.cpu) + " %"]
                    factWidths: [96, 64]
                    selected: tasks.isSelected(index)
                    ring: tasks.ringAt(index)
                    focusable: false
                    onClicked: mods => tasks.clickAt(index, mods)
                    // nothing to open: Enter hands the keyboard to the End task ring, which asks
                    onActivated: slab.forceActiveFocus()
                }
            }
        }

        Slab {
            id: slab
            anchors { bottom: parent.bottom; left: parent.left; margins: Kit.tokens.space.l }
            text: "End task"
            tone: "risk"
            confirm: window.target ? "End " + window.target.name + "?" : ""
            enabled: window.target !== null && window.target.pids.length > 0
            onActivated: window.endTarget()
        }

        Notice { id: notice }
    }

    function endTarget() {
        const t = window.target
        if (!t || t.pids.length === 0) return
        window.pendingName = t.name
        killer.command = ["kill", ...t.pids.map(String)]
        killer.running = true
    }

    // one program ends as one action: every thread of it is signalled together
    Process {
        id: killer
        command: []
        onExited: {
            notice.show("Ended " + window.pendingName, "")
            window.pendingName = ""
            reader.running = true
        }
    }

    // the reader: python gathers the figures, one line of JSON per run
    Process {
        id: reader
        command: ["python3", Qt.resolvedUrl("procs.py").toString().replace("file://", "")]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                if (!line.startsWith("{")) return
                const data = JSON.parse(line)
                window.stats = { total: data.total, used: data.used, free: data.free, swap: data.swap, root: data.root,
                                 cpu: data.cpu, ncpu: data.ncpu, disk: data.disk, gpu: data.gpu }
                // the numbers move every run; the cursor stays on the program it was on while it is there
                const was = window.shown[Math.max(0, Math.min(tasks.cursor, window.shown.length - 1))]
                window.procs = data.procs
                const back = window.shown.findIndex(p => was && p.name === was.name)
                tasks.cursor = back >= 0 ? back : Math.max(0, Math.min(tasks.cursor, window.shown.length - 1))
            }
        }
    }

    // every two seconds, but never while the ring is asking: the row it names must not move away
    Timer {
        interval: 2000
        running: true
        triggeredOnStart: true
        onTriggered: if (!slab.asking && !slab.activeFocus && !reader.running) reader.running = true
    }
}
