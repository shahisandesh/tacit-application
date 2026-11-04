import QtQuick
import Tacit.Kit
import "Markdown.js" as Md
import "Highlight.js" as Highlight

// One block of a Markdown page: a heading, a paragraph, a run of list lines, a quote, a fence, a
// rule or a table. It draws with the kit's inks and the type the page was given; on the stage the
// same block is larger and sits on the window ground.
Item {
    id: root

    property var block: null
    property var theme: ({})

    readonly property string kind: block !== null && block !== undefined ? (block.type ?? "paragraph") : "paragraph"
    readonly property int level: block !== null && block !== undefined ? (block.level ?? 1) : 1
    readonly property string words: block !== null && block !== undefined ? (block.text ?? "") : ""
    readonly property int columns: block !== null && block !== undefined && block.header ? block.header.length : 0
    readonly property real cellWidth: columns > 0
        ? (content.width - (columns - 1) * theme.tableGap) / columns
        : content.width

    implicitHeight: content.implicitHeight
    height: implicitHeight
    width: parent ? parent.width : 0

    function headingSize() {
        const levelName = level <= 1 ? "h1" : level === 2 ? "h2" : level === 3 ? "h3" : "h4";
        return theme[levelName] ?? theme.body;
    }

    function headingFamily() {
        return level <= 2 && theme.displayFamily ? theme.displayFamily : theme.family;
    }

    function markFor(item, index) {
        if (item.ordered) return item.number + ".";
        return item.depth === 0 ? "•" : item.depth === 1 ? "–" : "·";
    }

    function alignAt(index) {
        const a = block.aligns ? block.aligns[index] : "";
        return a === "right" ? Text.AlignRight : a === "center" ? Text.AlignHCenter : Text.AlignLeft;
    }

    function openLink(link) {
        if (/^(https?:\/\/|mailto:)/i.test(String(link)))
            Qt.openUrlExternally(link);
    }

    Column {
        id: content
        width: root.width
        spacing: root.kind === "heading" ? 0 : 0

        Column {
            visible: root.kind === "heading"
            width: content.width
            spacing: root.theme.smallSpace

            Text {
                width: parent.width
                text: Md.inline(root.words, root.theme)
                textFormat: Text.StyledText
                linkColor: root.theme.mark
                wrapMode: Text.WordWrap
                color: root.theme.heading
                font.family: root.headingFamily()
                font.pixelSize: root.headingSize()
                font.weight: Kit.tokens.weight.strong
                font.hintingPreference: Font.PreferNoHinting
                renderType: Text.NativeRendering
                lineHeight: root.theme.headingLine
                lineHeightMode: Text.ProportionalHeight
                onLinkActivated: link => root.openLink(link)
            }

            // A short accent mark under the big headings, the way the kit marks a place.
            Rectangle {
                visible: root.level <= 2
                width: root.level === 1 ? Kit.tokens.space.xxl : Kit.tokens.space.xl
                height: Kit.tokens.state.focusRing
                radius: height / 2
                color: root.theme.headingMark
            }
        }

        Text {
            visible: root.kind === "paragraph"
            width: content.width
            text: Md.inline(root.words, root.theme)
            textFormat: Text.StyledText
            linkColor: root.theme.mark
            wrapMode: Text.WordWrap
            color: root.theme.ink
            font.family: root.theme.family
            font.pixelSize: root.theme.body
            font.weight: Kit.tokens.weight.regular
            font.hintingPreference: Font.PreferNoHinting
            renderType: Text.NativeRendering
            lineHeight: root.theme.lineHeight
            lineHeightMode: Text.ProportionalHeight
            onLinkActivated: link => root.openLink(link)
        }

        Column {
            visible: root.kind === "list"
            width: content.width
            spacing: root.theme.smallSpace

            Repeater {
                model: root.kind === "list" ? (root.block.items ?? []) : []

                Item {
                    id: listLine
                    required property var modelData
                    required property int index

                    readonly property real indent: modelData.depth * root.theme.listIndent
                    readonly property real markRoom: root.theme.body * (modelData.ordered ? 2.1 : 1.2)

                    width: content.width - indent
                    x: indent
                    height: Math.max(markText.implicitHeight, lineText.implicitHeight)

                    Text {
                        id: markText
                        width: listLine.markRoom
                        text: root.markFor(listLine.modelData, listLine.index)
                        color: root.theme.mark
                        font.family: root.theme.family
                        font.pixelSize: root.theme.body
                        font.hintingPreference: Font.PreferNoHinting
                        renderType: Text.NativeRendering
                        lineHeight: root.theme.lineHeight
                        lineHeightMode: Text.ProportionalHeight
                    }
                    Text {
                        id: lineText
                        x: listLine.markRoom
                        width: listLine.width - listLine.markRoom
                        text: Md.inline(listLine.modelData.text, root.theme)
                        textFormat: Text.StyledText
                        linkColor: root.theme.mark
                        wrapMode: Text.WordWrap
                        color: root.theme.ink
                        font.family: root.theme.family
                        font.pixelSize: root.theme.body
                        font.weight: Kit.tokens.weight.regular
                        font.hintingPreference: Font.PreferNoHinting
                        renderType: Text.NativeRendering
                        lineHeight: root.theme.lineHeight
                        lineHeightMode: Text.ProportionalHeight
                        onLinkActivated: link => root.openLink(link)
                    }
                }
            }
        }

        Row {
            visible: root.kind === "quote"
            width: content.width
            spacing: root.theme.quoteGap

            Rectangle {
                width: Kit.tokens.state.focusRing
                height: quoteText.implicitHeight
                radius: width / 2
                color: root.theme.mark
            }
            Text {
                id: quoteText
                width: content.width - 2 - root.theme.quoteGap
                text: Md.inline(root.words, root.theme)
                textFormat: Text.StyledText
                linkColor: root.theme.mark
                wrapMode: Text.WordWrap
                color: root.theme.inkSec
                font.family: root.theme.family
                font.pixelSize: root.theme.body
                font.weight: Kit.tokens.weight.regular
                font.hintingPreference: Font.PreferNoHinting
                renderType: Text.NativeRendering
                lineHeight: root.theme.lineHeight
                lineHeightMode: Text.ProportionalHeight
                onLinkActivated: link => root.openLink(link)
            }
        }

        Rectangle {
            visible: root.kind === "code"
            width: content.width
            height: codeText.implicitHeight + 2 * root.theme.codePad
            radius: Kit.tokens.radius.row
            color: root.theme.codeBg
            clip: true

            Rectangle {
                width: Kit.tokens.state.focusRing
                height: parent.height
                color: root.theme.mark
            }

            Text {
                id: codeText
                x: root.theme.codePad
                y: root.theme.codePad
                width: parent.width - 2 * root.theme.codePad
                text: root.kind === "code" ? Highlight.highlight(root.block.text ?? "", root.block.language ?? "", root.theme.syntax) : ""
                textFormat: Text.StyledText
                wrapMode: Text.WrapAnywhere
                color: root.theme.codeInk
                font.family: root.theme.codeFamily
                font.pixelSize: root.theme.code
                font.hintingPreference: Font.PreferNoHinting
                renderType: Text.NativeRendering
                lineHeight: root.theme.codeLine
                lineHeightMode: Text.ProportionalHeight
            }
        }

        Rectangle {
            visible: root.kind === "rule"
            width: content.width
            height: 1
            color: root.theme.ruleMark
        }

        Column {
            visible: root.kind === "table"
            width: content.width
            spacing: 0

            Row {
                width: content.width
                spacing: root.theme.tableGap

                Repeater {
                    model: root.columns
                    Text {
                        required property int index
                        width: root.cellWidth
                        text: Md.inline(root.block.header[index] ?? "", root.theme)
                        textFormat: Text.StyledText
                        linkColor: root.theme.mark
                        wrapMode: Text.WordWrap
                        horizontalAlignment: root.alignAt(index)
                        verticalAlignment: Text.AlignTop
                        color: root.theme.heading
                        font.family: root.theme.family
                        font.pixelSize: root.theme.tableSize
                        font.weight: Kit.tokens.weight.strong
                        font.hintingPreference: Font.PreferNoHinting
                        renderType: Text.NativeRendering
                        lineHeight: root.theme.lineHeight
                        lineHeightMode: Text.ProportionalHeight
                        onLinkActivated: link => root.openLink(link)
                    }
                }
            }

            Rectangle {
                width: content.width
                height: 1
                color: root.theme.headingMark
            }

            Repeater {
                model: root.kind === "table" ? (root.block.rows ?? []) : []

                Column {
                    id: tableRow
                    required property var modelData
                    width: content.width

                    Row {
                        width: tableRow.width
                        spacing: root.theme.tableGap

                        Repeater {
                            model: root.columns
                            Text {
                                required property int index
                                width: root.cellWidth
                                text: Md.inline(tableRow.modelData[index] ?? "", root.theme)
                                textFormat: Text.StyledText
                                linkColor: root.theme.mark
                                wrapMode: Text.WordWrap
                                horizontalAlignment: root.alignAt(index)
                                verticalAlignment: Text.AlignTop
                                color: root.theme.ink
                                font.family: root.theme.family
                                font.pixelSize: root.theme.tableSize
                                font.weight: Kit.tokens.weight.regular
                                font.hintingPreference: Font.PreferNoHinting
                                renderType: Text.NativeRendering
                                lineHeight: root.theme.lineHeight
                                lineHeightMode: Text.ProportionalHeight
                                onLinkActivated: link => root.openLink(link)
                            }
                        }
                    }

                    Rectangle {
                        width: tableRow.width
                        height: 1
                        color: root.theme.rule
                    }
                }
            }
        }
    }
}
