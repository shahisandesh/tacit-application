import QtQuick
import Tacit.Kit

// The source, on the document's dark glass sheet: a TextEdit in the writing face the app hands it,
// with the window inks, the caret in the accent, and the kit's scroll bar. It never draws a surface
// of its own; the sheet holds it.
Item {
    id: root

    property string text: ""
    property string family: Kit.tokens.font.code
    property real scale: 1
    property string label: "Markdown source"

    signal edited(string text)
    signal saveRequested()

    readonly property real pad: Kit.tokens.space.xxl

    function focusEditor() {
        input.forceActiveFocus();
    }

    function ensureCursor() {
        if (!input.activeFocus) return;
        const top = input.y + input.cursorRectangle.y;
        const bottom = top + input.cursorRectangle.height;
        if (top < flick.contentY + root.pad)
            flick.contentY = Math.max(0, top - root.pad);
        else if (bottom > flick.contentY + flick.height - root.pad)
            flick.contentY = bottom - flick.height + root.pad;
    }

    onTextChanged: {
        if (input.text !== text) {
            input.text = text;
            input.cursorPosition = 0;
            flick.contentY = 0;
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: Math.max(input.height + 2 * root.pad, height)
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Text {
            x: root.pad
            y: root.pad
            width: flick.width - 2 * root.pad
            visible: input.text.length === 0
            text: "Write Markdown. Three dashes on a line start a slide."
            wrapMode: Text.WordWrap
            color: Kit.tokens.inkMeta
            font.family: root.family
            font.pixelSize: Kit.tokens.size.meta * root.scale
            font.hintingPreference: Font.PreferNoHinting
            renderType: Text.NativeRendering
            Accessible.ignored: true
        }

        TextEdit {
            id: input
            x: root.pad
            y: root.pad
            width: flick.width - 2 * root.pad
            height: Math.max(contentHeight, flick.height - 2 * root.pad)
            text: root.text
            textFormat: TextEdit.PlainText
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            activeFocusOnTab: true
            color: Kit.tokens.inkMain
            selectionColor: Qt.alpha(Kit.tokens.accent, 0.24)
            selectedTextColor: Kit.tokens.inkMain
            font.family: root.family
            font.pixelSize: Kit.tokens.size.row * root.scale
            font.weight: Kit.tokens.weight.regular
            font.hintingPreference: Font.PreferNoHinting
            renderType: Text.NativeRendering
            cursorDelegate: Rectangle {
                width: 1.5
                color: Kit.tokens.accent
                visible: input.cursorVisible
            }
            Accessible.role: Accessible.EditableText
            Accessible.name: root.label
            Accessible.multiLine: true

            onTextChanged: {
                if (input.text !== root.text)
                    root.edited(input.text);
            }
            onCursorRectangleChanged: root.ensureCursor()
            Keys.onPressed: event => {
                Kit.focusVisible = true;
            }
        }
    }

    ScrollBar {
        view: flick
        anchors.fill: flick
    }
}
