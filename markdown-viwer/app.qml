import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import Tacit.Kit
import "Markdown.js" as Md

// Markdown: one file, three views. Write it, read it, present it. The page is a dark glass sheet
// lifted from the window's ground, and the stage is the ground itself. The type for the page and
// the stage is set in the docked Type panel.
FloatingWindow {
    id: window

    title: "Markdown"
    color: "transparent"
    implicitWidth: 1360
    implicitHeight: 860
    minimumSize: Qt.size(1000, 680)
    visible: true

    property int mode: 0                 // 0 write, 1 read, 2 present
    property int beforePresent: 0
    property string source: ""
    property string previewSource: ""
    property string currentPath: ""
    property string currentName: "Welcome.md"
    property string docKey: "sample"
    property bool dirty: false
    property bool typeOpen: false
    property bool railFolded: false
    property bool reading: false
    property bool sampleReady: false
    property string sampleText: ""
    property string pendingPath: ""
    property string pendingName: ""
    property string saveTarget: ""
    property string saveName: ""
    property string saveText: ""

    readonly property var slides: Md.slides(previewSource)
    readonly property int words: Md.wordCount(previewSource)
    readonly property bool empty: previewSource.trim() === ""

    readonly property string documentsDir: {
        const dirs = StandardPaths.standardLocations(StandardPaths.DocumentsLocation);
        let dir = dirs.length > 0 ? String(dirs[0]) : (Quickshell.env("HOME") + "/Documents");
        if (dir.startsWith("file://")) dir = decodeURIComponent(dir.slice(7));
        return dir.replace(/\/$/, "");
    }
    readonly property string appDir: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, "")
    readonly property string samplePath: appDir + "/deck.md"
    readonly property string palettePath: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell/user/generated/colors.json"
    property color headingGreen: Kit.tokens.accent
    readonly property string readFamily: familyAt(typeSettings.readFont)
    readonly property string writeFamily: familyAt(typeSettings.writeFont)

    readonly property string fallbackDeck: "# Welcome to Markdown\n\nWrite in Markdown. A line of three dashes starts a new slide.\n\n---\n\n## A second slide\n\n- A point\n- Another point\n"

    function familyAt(index) {
        const families = [Kit.tokens.font.main, Kit.tokens.font.display, Kit.tokens.font.code];
        return families[index] ?? families[0];
    }

    function localPath(path) {
        let s = String(path ?? "");
        if (s.startsWith("file://")) s = decodeURIComponent(s.slice(7));
        return s;
    }

    function setDocument(text, path, name, key) {
        parseTimer.stop();
        loadingDocument = true;
        source = text ?? "";
        previewSource = source;
        currentPath = path;
        currentName = name;
        docKey = key;
        dirty = false;
        loadingDocument = false;
        if (mode === 2) leavePresent();
    }

    function edited(text) {
        if (loadingDocument) return;
        source = text;
        dirty = true;
        parseTimer.restart();
    }

    function receiveSample(text) {
        sampleText = text && String(text).length > 0 ? text : fallbackDeck;
        sampleReady = true;
        if (source === "") setDocument(sampleText, "", "Welcome.md", "sample");
    }

    function loadSample() {
        if (!sampleReady) {
            notice.show("The welcome deck is still loading. Try again in a moment.", "");
            return;
        }
        setDocument(sampleText, "", "Welcome.md", "sample");
        if (mode === 0) editor.focusEditor();
    }

    function newDeck() {
        setDocument("# Untitled deck\n\nWrite in Markdown. A line of three dashes starts a new slide.\n\n---\n\n## A second slide\n\n- A point\n- Another point\n", "", "Untitled.md", "new");
        dirty = true;
        mode = 0;
        typeOpen = false;
        notice.show("New deck. Save it to keep it.", "");
        Qt.callLater(function() { editor.focusEditor(); });
    }

    function openPath(path, name) {
        const clean = localPath(path);
        pendingPath = clean;
        pendingName = name;
        reading = true;
        if (fileReader.path === clean) fileReader.reload();
        else fileReader.path = clean;
    }

    function finishOpen(text) {
        if (pendingPath === "") return;
        const path = pendingPath;
        const name = pendingName;
        pendingPath = "";
        pendingName = "";
        reading = false;
        if (text === undefined || text === null) {
            notice.show("Could not open " + name + ". Check it is still there.", "");
            return;
        }
        setDocument(text, path, name, path);
    }

    function failOpen() {
        if (pendingPath === "") return;
        const name = pendingName;
        pendingPath = "";
        pendingName = "";
        reading = false;
        notice.show("Could not open " + name + ". Check it is still there.", "");
    }

    function hasDocument(name) {
        for (let i = 0; i < docsModel.count; i++) {
            if (String(docsModel.get(i, "fileName")).toLowerCase() === String(name).toLowerCase())
                return true;
        }
        return false;
    }

    function uniquePath(base, extension) {
        let name = base + extension;
        let n = 2;
        while (hasDocument(name)) {
            name = base + "-" + n + extension;
            n++;
        }
        return documentsDir + "/" + name;
    }

    function save() {
        if (currentPath !== "") {
            startSave(currentPath, currentName);
            return;
        }
        const base = currentName.replace(/\.[^.]+$/, "") || "untitled";
        const path = uniquePath(base, ".md");
        startSave(path, path.split("/").pop());
    }

    function startSave(path, name) {
        saveTarget = path;
        saveName = name;
        saveText = source;
        saver.stdinEnabled = true;
        saver.command = ["bash", "-c", "cat > \"$1\"", "--", path];
        saver.running = true;
    }

    function setMode(index) {
        if (index === 2) { present(); return; }
        if (mode === 2) mode = beforePresent;
        mode = index;
        typeOpen = false;
        Qt.callLater(function() {
            if (mode === 0) editor.focusEditor();
            else if (mode === 1) viewTabs.forceActiveFocus();
        });
    }

    function present() {
        if (mode === 2) return;
        beforePresent = mode;
        typeOpen = false;
        mode = 2;
        presentView.index = 0;
        Qt.callLater(function() { presentView.focusDeck(); });
    }

    function leavePresent() {
        mode = beforePresent;
        Qt.callLater(function() {
            if (mode === 0) editor.focusEditor();
            else if (mode === 1) viewTabs.forceActiveFocus();
        });
    }

    property bool loadingDocument: false

    QtObject {
        id: typeSettings
        property int readFont: 0
        property real readScale: 1
        property real lineHeight: 1.6
        property int writeFont: 2
        property real writeScale: 1
        property real slideScale: 1
        property bool slideNumbers: true
    }

    Timer {
        id: parseTimer
        interval: 120
        repeat: false
        onTriggered: window.previewSource = window.source
    }

    Process {
        id: ensureDocuments
        command: ["mkdir", "-p", window.documentsDir]
        running: true
    }

    FileView {
        id: sampleFile
        path: window.samplePath
        blockLoading: true
        printErrors: true
        onLoaded: window.receiveSample(sampleFile.text())
        onLoadFailed: window.receiveSample(window.fallbackDeck)
    }

    // The kit dresses the page in the window's inks and one accent. For a second colour that still
    // belongs to the wallpaper, read the shell's palette: its tertiary is the green the headings use.
    FileView {
        id: paletteFile
        path: window.palettePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const palette = JSON.parse(paletteFile.text());
                if (palette.tertiary) window.headingGreen = palette.tertiary;
            } catch (e) {}
        }
    }

    FileView {
        id: fileReader
        path: ""
        blockLoading: true
        printErrors: false
        onLoaded: if (window.pendingPath !== "") window.finishOpen(fileReader.text())
        onLoadFailed: if (window.pendingPath !== "") window.failOpen()
    }

    Process {
        id: saver
        stdinEnabled: true
        command: ["bash", "-c", "cat > \"$1\"", "--", ""]
        onStarted: {
            saver.write(window.saveText);
            saver.stdinEnabled = false;
        }
        onExited: (code, status) => {
            if (code === 0) {
                window.currentPath = window.saveTarget;
                window.currentName = window.saveName;
                window.docKey = window.saveTarget;
                window.dirty = window.source !== window.saveText;
                notice.show("Saved " + window.saveName, "");
            } else {
                notice.show("Could not save " + window.saveName + ". Check the Documents folder.", "");
            }
        }
    }

    FolderListModel {
        id: docsModel
        folder: "file://" + window.documentsDir
        nameFilters: ["*.md", "*.markdown", "*.mdown"]
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
    }

    Shortcut { sequence: "Ctrl+S"; onActivated: window.save() }
    Shortcut { sequence: "F5"; onActivated: window.present() }
    Shortcut { sequence: "Ctrl+T"; onActivated: window.typeOpen = !window.typeOpen }
    Shortcut { sequence: "Ctrl+1"; onActivated: window.setMode(0) }
    Shortcut { sequence: "Ctrl+2"; onActivated: window.setMode(1) }
    Shortcut { sequence: "Ctrl+3"; onActivated: window.present() }

    WindowGround {}

    Item {
        id: chrome
        anchors.fill: parent
        visible: window.mode !== 2

        Keys.onEscapePressed: event => {
            if (window.typeOpen) {
                window.typeOpen = false;
                event.accepted = true;
            }
        }

        Rail {
            id: rail
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            folded: window.railFolded
            action: "New deck"
            actionSymbol: "note_add"
            onToggle: window.railFolded = !window.railFolded
            onActionActivated: window.newDeck()

            RailSection { text: "Start" }

            RailRow {
                glyph: "markdown"
                label: "Welcome deck"
                current: window.docKey === "sample"
                onPicked: window.loadSample()
            }

            RailSection {
                text: "Documents"
                count: docsModel.count
            }

            Repeater {
                model: docsModel

                RailRow {
                    required property string fileName
                    required property var filePath
                    glyph: "description"
                    label: fileName
                    current: window.docKey === window.localPath(filePath)
                    onPicked: window.openPath(filePath, fileName)
                }
            }

            TacitText {
                visible: docsModel.count === 0 && !window.railFolded
                x: 44
                width: rail.width - 52
                text: "No Markdown files in Documents yet."
                size: "meta"
                ink: "meta"
                wrapMode: Text.WordWrap
            }
        }

        Item {
            id: pageArea
            anchors {
                left: rail.right
                top: parent.top
                right: parent.right
                rightMargin: typePanel.width
                bottom: parent.bottom
            }

            PageHeader {
                id: header
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                crumbs: []
                here: window.currentName
                canGoBack: false
                canGoForward: false
                loading: window.reading

                Slab {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Save"
                    tone: window.dirty ? "default" : ""
                    onActivated: window.save()
                }

                Slab {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Type"
                    onActivated: window.typeOpen = !window.typeOpen
                }
            }

            Item {
                id: viewBar
                anchors {
                    left: parent.left
                    right: parent.right
                    top: header.bottom
                }
                height: Kit.tokens.height.action + Kit.tokens.space.s

                Tabs {
                    id: viewTabs
                    x: Kit.tokens.space.l
                    anchors.verticalCenter: parent.verticalCenter
                    labels: ["Write", "Read", "Present"]
                    current: window.mode
                    label: "Views"
                    onPicked: index => window.setMode(index)
                }

                TacitText {
                    anchors {
                        right: parent.right
                        rightMargin: Kit.tokens.space.l
                        verticalCenter: parent.verticalCenter
                    }
                    text: window.words === 0
                        ? "Empty"
                        : window.words + (window.words === 1 ? " word" : " words")
                          + " · " + window.slides.length + (window.slides.length === 1 ? " slide" : " slides")
                          + (window.dirty ? " · Unsaved" : "")
                    size: "meta"
                    ink: "meta"
                    cut: "numbers"
                }
            }

            Item {
                id: contentArea
                anchors {
                    left: parent.left
                    right: parent.right
                    top: viewBar.bottom
                    bottom: parent.bottom
                }

                Rectangle {
                    id: paper
                    readonly property real sheetWidth: Math.min(parent.width - 2 * Kit.tokens.space.l,
                                                               Kit.tokens.width.list + 2 * Kit.tokens.space.page)
                    x: window.mode === 1 ? (parent.width - sheetWidth) / 2 : Kit.tokens.space.l
                    y: Kit.tokens.space.l
                    width: window.mode === 1 ? sheetWidth : parent.width - 2 * Kit.tokens.space.l
                    height: parent.height - 2 * Kit.tokens.space.l
                    color: Qt.alpha(Kit.tokens.inkMain, Kit.tokens.wash.action)
                    border.width: 1
                    border.color: Qt.alpha(Kit.tokens.inkMain, 0.10)
                    radius: Kit.tokens.radius.panel
                    clip: true
                }

                Item {
                    id: writeView
                    anchors.fill: paper
                    visible: window.mode === 0

                    MarkdownEditor {
                        id: editor
                        anchors {
                            left: parent.left
                            right: splitLine.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        text: window.source
                        family: window.writeFamily
                        scale: typeSettings.writeScale
                        label: "Markdown source"
                        onEdited: text => window.edited(text)
                        onSaveRequested: window.save()
                    }

                    Rectangle {
                        id: splitLine
                        x: parent.width / 2
                        width: 1
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            topMargin: Kit.tokens.space.xl
                            bottomMargin: Kit.tokens.space.xl
                        }
                        color: Kit.tokens.hairline
                    }

                    MarkdownView {
                        anchors {
                            left: splitLine.right
                            right: parent.right
                            top: parent.top
                            bottom: parent.bottom
                        }
                        source: window.previewSource
                        mode: "paper"
                        family: window.readFamily
                        headingColor: window.headingGreen
                        scale: typeSettings.readScale
                        lineHeight: typeSettings.lineHeight
                        pad: Kit.tokens.space.xxl
                        label: "Preview"
                    }

                    Text {
                        visible: window.empty
                        anchors {
                            left: splitLine.right
                            right: parent.right
                            top: parent.top
                            leftMargin: Kit.tokens.space.xxl
                            rightMargin: Kit.tokens.space.xxl
                            topMargin: Kit.tokens.space.xxl
                        }
                        text: "Nothing to preview yet. Write a line of Markdown."
                        wrapMode: Text.WordWrap
                        color: Kit.tokens.inkSec
                        font.family: Kit.tokens.font.main
                        font.pixelSize: Kit.tokens.size.body
                        font.hintingPreference: Font.PreferNoHinting
                        renderType: Text.NativeRendering
                    }
                }

                MarkdownView {
                    id: readerView
                    visible: window.mode === 1
                    readonly property real readWidth: Math.min(paper.width, Kit.tokens.width.list + 2 * Kit.tokens.space.page)
                    x: paper.x + (paper.width - readWidth) / 2
                    y: paper.y
                    width: readWidth
                    height: paper.height
                    source: window.previewSource
                    mode: "paper"
                    family: window.readFamily
                    headingColor: window.headingGreen
                    scale: typeSettings.readScale
                    lineHeight: typeSettings.lineHeight
                    pad: Math.max(Kit.tokens.space.xl, (readWidth - Kit.tokens.width.list) / 2)
                    label: "Markdown preview"
                }

                Text {
                    visible: window.mode === 1 && window.empty
                    x: readerView.x + readerView.pad
                    y: paper.y + Kit.tokens.space.xxl * 2
                    width: Math.min(readerView.width - 2 * readerView.pad, Kit.tokens.width.list)
                    text: "This deck is empty. Write something in Write."
                    wrapMode: Text.WordWrap
                    color: Kit.tokens.inkSec
                    font.family: Kit.tokens.font.main
                    font.pixelSize: Kit.tokens.size.body
                    font.hintingPreference: Font.PreferNoHinting
                    renderType: Text.NativeRendering
                }
            }
        }

        DockedPanel {
            id: typePanel
            anchors.right: parent.right
            y: header.fullHeight - 1
            height: parent.height - y - Kit.tokens.space.xl
            open: window.typeOpen
            openWidth: Kit.tokens.width.panel
            label: "Type"

            TypePanel {
                anchors.fill: parent
                settings: typeSettings
                onDone: window.typeOpen = false
            }
        }
    }

    SlideDeck {
        id: presentView
        anchors.fill: parent
        visible: window.mode === 2
        slides: window.slides
        family: window.readFamily
        headingColor: window.headingGreen
        scale: typeSettings.slideScale
        numbers: typeSettings.slideNumbers
        onExitRequested: window.leavePresent()
    }

    Notice {
        id: notice
    }

    Component.onCompleted: {
        Kit.watchKeys(window);
        if (window.sampleReady && window.source === "")
            window.loadSample();
        editor.focusEditor();
    }
}
