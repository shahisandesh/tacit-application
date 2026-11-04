import QtQuick
import Tacit.Kit

// The type controls, inside the docked panel: the face and size of the reading page, the face and
// size of the source, and the stage's size and slide numbers. Every value is a scale of a
// Kit.tokens size, never a pixel of its own, so the page still follows the design's type.
Item {
    id: root

    property QtObject settings: null
    signal done()

    readonly property var families: [Kit.tokens.font.main, Kit.tokens.font.display, Kit.tokens.font.code]

    readonly property int readFont: settings ? settings.readFont : 0
    readonly property real readScale: settings ? settings.readScale : 1
    readonly property real lineHeight: settings ? settings.lineHeight : 1.6
    readonly property int writeFont: settings ? settings.writeFont : 2
    readonly property real writeScale: settings ? settings.writeScale : 1
    readonly property real slideScale: settings ? settings.slideScale : 1
    readonly property bool slideNumbers: settings ? settings.slideNumbers : true

    readonly property real pad: Kit.tokens.space.xl

    function familyFor(index) {
        return families[index] ?? families[0];
    }

    function resetType() {
        if (!settings) return;
        settings.readFont = 0;
        settings.readScale = 1;
        settings.lineHeight = 1.6;
        settings.writeFont = 2;
        settings.writeScale = 1;
        settings.slideScale = 1;
        settings.slideNumbers = true;
    }

    // A press on the panel's own ground stays in the panel; it must not reach the page under it.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onWheel: wheel => wheel.accepted = true
    }

    Flickable {
        id: flick
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: doneRow.top
        }
        clip: true
        contentWidth: width
        contentHeight: column.implicitHeight + 2 * root.pad
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            x: root.pad
            y: root.pad
            width: flick.width - 2 * root.pad
            spacing: Kit.tokens.space.xl

            TacitText {
                text: "Type"
                size: "section"
                weight: "strong"
            }

            TacitText {
                width: column.width
                text: "The page and the stage follow these."
                size: "meta"
                ink: "meta"
                wrapMode: Text.WordWrap
            }

            // ---------------------------------------------------------------- reading

            TacitText { text: "Reading"; size: "body"; weight: "strong" }

            Text {
                width: column.width
                text: "The quick brown fox jumps over the lazy dog."
                wrapMode: Text.WordWrap
                color: Kit.tokens.inkMain
                font.family: root.familyFor(root.readFont)
                font.pixelSize: Kit.tokens.size.body * root.readScale
                font.weight: Kit.tokens.weight.regular
                font.hintingPreference: Font.PreferNoHinting
                renderType: Text.NativeRendering
                lineHeight: root.lineHeight
                lineHeightMode: Text.ProportionalHeight
            }

            Column {
                width: column.width
                spacing: Kit.tokens.space.s

                TacitText { text: "Font"; size: "meta"; ink: "meta" }
                Choices {
                    label: "Reading font"
                    model: root.families
                    current: root.readFont
                    onPicked: index => { if (root.settings) root.settings.readFont = index; }
                }
            }

            Column {
                width: column.width
                spacing: Kit.tokens.space.s

                TacitText { text: "Size"; size: "meta"; ink: "meta" }
                Slider {
                    width: column.width
                    label: "Reading size"
                    step: 0.05
                    value: (root.readScale - 0.8) / 0.6
                    word: Math.round(root.readScale * 100) + "%"
                    onMoved: value => { if (root.settings) root.settings.readScale = 0.8 + value * 0.6; }
                }
            }

            Column {
                width: column.width
                spacing: Kit.tokens.space.s

                TacitText { text: "Line height"; size: "meta"; ink: "meta" }
                Slider {
                    width: column.width
                    label: "Line height"
                    step: 0.05
                    value: (root.lineHeight - 1.2) / 0.8
                    word: (Math.round(root.lineHeight * 10) / 10) + "×"
                    onMoved: value => { if (root.settings) root.settings.lineHeight = 1.2 + value * 0.8; }
                }
            }

            Rectangle { width: column.width; height: 1; color: Kit.tokens.hairline }

            // ---------------------------------------------------------------- writing

            TacitText { text: "Writing"; size: "body"; weight: "strong" }

            Text {
                width: column.width
                text: "A line of the source, in the writing face."
                wrapMode: Text.WordWrap
                color: Kit.tokens.inkMain
                font.family: root.familyFor(root.writeFont)
                font.pixelSize: Kit.tokens.size.row * root.writeScale
                font.weight: Kit.tokens.weight.regular
                font.hintingPreference: Font.PreferNoHinting
                renderType: Text.NativeRendering
            }

            Column {
                width: column.width
                spacing: Kit.tokens.space.s

                TacitText { text: "Font"; size: "meta"; ink: "meta" }
                Choices {
                    label: "Writing font"
                    model: root.families
                    current: root.writeFont
                    onPicked: index => { if (root.settings) root.settings.writeFont = index; }
                }
            }

            Column {
                width: column.width
                spacing: Kit.tokens.space.s

                TacitText { text: "Size"; size: "meta"; ink: "meta" }
                Slider {
                    width: column.width
                    label: "Writing size"
                    step: 0.05
                    value: (root.writeScale - 0.8) / 0.6
                    word: Math.round(root.writeScale * 100) + "%"
                    onMoved: value => { if (root.settings) root.settings.writeScale = 0.8 + value * 0.6; }
                }
            }

            Rectangle { width: column.width; height: 1; color: Kit.tokens.hairline }

            // ---------------------------------------------------------------- slides

            TacitText { text: "Slides"; size: "body"; weight: "strong" }

            Column {
                width: column.width
                spacing: Kit.tokens.space.s

                TacitText { text: "Size"; size: "meta"; ink: "meta" }
                Slider {
                    width: column.width
                    label: "Slide size"
                    step: 0.05
                    value: (root.slideScale - 0.8) / 0.5
                    word: Math.round(root.slideScale * 100) + "%"
                    onMoved: value => { if (root.settings) root.settings.slideScale = 0.8 + value * 0.5; }
                }
            }

            Item {
                width: column.width
                height: Kit.tokens.height.field

                TacitText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Slide numbers"
                    size: "row"
                }
                Switch {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    label: "Slide numbers"
                    checked: root.slideNumbers
                    onToggled: checked => { if (root.settings) root.settings.slideNumbers = checked; }
                }
            }

            WordAction {
                width: column.width
                text: "Reset the type"
                onActivated: root.resetType()
            }
        }
    }

    Glide { view: flick }

    ScrollBar {
        view: flick
        anchors.fill: flick
    }

    Item {
        id: doneRow
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: Kit.tokens.height.action + 2 * Kit.tokens.space.l

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: 1
            color: Kit.tokens.hairline
        }

        Slab {
            x: root.pad
            y: Kit.tokens.space.l
            width: parent.width - 2 * root.pad
            maxWidth: parent.width - 2 * root.pad
            text: "Done"
            tone: "default"
            onActivated: root.done()
        }
    }
}
