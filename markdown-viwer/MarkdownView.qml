import QtQuick
import Tacit.Kit
import "Markdown.js" as Md

// A Markdown page, drawn from Kit.tokens. On the page (mode "paper") it uses the window inks and
// the reading type the app hands it; on the stage (mode "stage") the same inks at the large stage
// sizes. Blocks are parsed in Markdown.js and drawn by MarkdownBlock.
Item {
    id: root

    property string source: ""
    property var blocks: null
    property string mode: "paper"
    property string family: Kit.tokens.font.main
    property color headingColor: Kit.tokens.accent
    property real scale: 1
    property real lineHeight: 1.65
    property int pad: 0
    property bool scrollBar: true
    property string label: "Markdown preview"

    readonly property var shown: blocks !== null && blocks !== undefined ? blocks : Md.parse(source)
    readonly property var theme: makeTheme()
    readonly property real contentHeight: column.implicitHeight + 2 * root.pad

    Accessible.role: Accessible.Pane
    Accessible.name: label
    clip: true

    function makeTheme() {
        const t = Kit.tokens;
        const displayFamily = root.family === t.font.main ? t.font.display : root.family;
        const syntax = {
            keyword: t.accent.toString(),
            string: root.headingColor.toString(),
            number: t.risk.toString(),
            comment: t.inkFaint.toString(),
            function: t.inkMain.toString(),
            type: t.inkSec.toString(),
            operator: t.inkMeta.toString(),
            punctuation: t.inkSec.toString(),
            tag: t.accent.toString(),
            attr: root.headingColor.toString(),
            key: root.headingColor.toString(),
            meta: t.inkMeta.toString(),
            added: root.headingColor.toString(),
            removed: t.risk.toString()
        };
        if (root.mode === "stage") {
            return {
                mode: "stage",
                family: root.family,
                displayFamily,
                h1: t.size.display * root.scale,
                h2: t.size.alarm * root.scale,
                h3: t.size.headline * root.scale,
                h4: t.size.section * root.scale,
                body: t.size.section * root.scale,
                tableSize: t.size.body * root.scale,
                code: t.size.body * root.scale,
                meta: t.size.row * root.scale,
                strong: t.weight.strong,
                lineHeight: 1.5,
                headingLine: 1.1,
                codeLine: 1.5,
                ink: t.inkMain,
                inkSec: t.inkSec,
                heading: root.headingColor,
                headingMark: root.headingColor,
                mark: t.accent,
                rule: t.hairline,
                ruleMark: Qt.alpha(t.accent, 0.55),
                codeBg: t.overlay,
                codeInk: t.inkMain,
                codeFamily: t.font.code,
                linkCss: t.accent.toString(),
                metaCss: t.inkMeta.toString(),
                codeBgCss: t.overlay.toString(),
                codeInkCss: t.accent.toString(),
                syntax,
                blockSpace: t.space.xl,
                smallSpace: t.space.s,
                listIndent: t.space.xl,
                quoteGap: t.space.m,
                tableGap: t.space.l,
                codePad: t.space.l
            };
        }
        return {
            mode: "paper",
            family: root.family,
            displayFamily,
            h1: t.size.headline * root.scale,
            h2: t.size.section * root.scale,
            h3: t.size.body * root.scale,
            h4: t.size.row * root.scale,
            body: t.size.body * root.scale,
            tableSize: t.size.row * root.scale,
            code: t.size.fileText * root.scale,
            meta: t.size.meta * root.scale,
            strong: t.weight.strong,
            lineHeight: root.lineHeight,
            headingLine: 1.18,
            codeLine: 1.55,
            ink: t.inkMain,
            inkSec: t.inkSec,
            heading: root.headingColor,
            headingMark: root.headingColor,
            mark: t.accent,
            rule: t.hairline,
            ruleMark: Qt.alpha(t.accent, 0.55),
            codeBg: t.overlay,
            codeInk: t.inkMain,
            codeFamily: t.font.code,
            linkCss: t.accent.toString(),
            metaCss: t.inkMeta.toString(),
            codeBgCss: t.overlay.toString(),
            codeInkCss: t.accent.toString(),
            syntax,
            blockSpace: t.space.l,
            smallSpace: t.space.xs,
            listIndent: t.space.xl,
            quoteGap: t.space.m,
            tableGap: t.space.m,
            codePad: t.space.m
        };
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: content.height
        interactive: true

        Item {
            id: content
            width: flick.width
            height: column.implicitHeight + 2 * root.pad

            Column {
                id: column
                x: root.pad
                y: root.pad
                width: content.width - 2 * root.pad
                spacing: root.theme.blockSpace

                Repeater {
                    model: root.shown

                    MarkdownBlock {
                        required property var modelData
                        width: column.width
                        block: modelData
                        theme: root.theme
                    }
                }
            }
        }
    }

    Glide { view: flick }

    ScrollBar {
        view: flick
        anchors.fill: flick
        visible: root.scrollBar
    }
}
