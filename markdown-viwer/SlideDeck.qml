import QtQuick
import Tacit.Kit

// The stage: one slide of the same Markdown, large, on the window's own ground. Left and Right
// (also Space, Page Up and Down, Home and End) move; Esc stops. The footer is the one piece of
// chrome: back, forward, the slide's place, and close, over the accent progress mark.
FocusScope {
    id: root

    property var slides: []
    property string family: Kit.tokens.font.main
    property color headingColor: Kit.tokens.accent
    property real scale: 1
    property bool numbers: true

    signal exitRequested()

    property int index: 0
    readonly property int count: slides.length
    readonly property int current: count === 0 ? -1 : Math.max(0, Math.min(count - 1, index))
    readonly property var slide: current >= 0 ? slides[current] : ({ title: "", body: [] })
    readonly property string titleFamily: family === Kit.tokens.font.main ? Kit.tokens.font.display : family

    activeFocusOnTab: true
    clip: true
    Accessible.role: Accessible.Pane
    Accessible.name: count === 0 ? "Presentation, no slides" : "Presentation, slide " + (current + 1) + " of " + count

    function focusDeck() { root.forceActiveFocus(); }

    function go(to) {
        if (root.count === 0) return;
        root.index = Math.max(0, Math.min(root.count - 1, to));
    }

    onIndexChanged: slideFade.restart()
    onSlidesChanged: if (root.index >= root.count) root.index = Math.max(0, root.count - 1)

    Keys.onPressed: event => {
        Kit.focusVisible = true;
        switch (event.key) {
        case Qt.Key_Right:
        case Qt.Key_Down:
        case Qt.Key_Space:
        case Qt.Key_PageDown:
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.go(root.current + 1);
            event.accepted = true;
            break;
        case Qt.Key_Left:
        case Qt.Key_Up:
        case Qt.Key_PageUp:
            root.go(root.current - 1);
            event.accepted = true;
            break;
        case Qt.Key_Home:
            root.go(0);
            event.accepted = true;
            break;
        case Qt.Key_End:
            root.go(root.count - 1);
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            root.exitRequested();
            event.accepted = true;
            break;
        }
    }

    Item {
        id: slideContent
        anchors.fill: parent
        anchors.bottomMargin: footer.height
        opacity: 1

        NumberAnimation on opacity {
            id: slideFade
            running: false
            from: 0
            to: 1
            duration: Kit.ms(Kit.tokens.motion.fade.ms)
        }

        // Zen: the slide is one block at the centre of the stage, on the reading measure, above
        // the footer. A slide taller than the stage starts at the top and scrolls.
        readonly property real columnWidth: Math.min(width - 2 * Kit.tokens.space.page,
                                                     Kit.tokens.width.list + 2 * Kit.tokens.space.page)
        readonly property real titleBlock: titleText.visible ? titleText.implicitHeight + Kit.tokens.space.xl : 0
        readonly property real bodyHeight: Math.min(bodyView.contentHeight,
                                                    Math.max(Kit.tokens.space.page,
                                                             height - 2 * Kit.tokens.space.page - titleBlock))
        readonly property real blockHeight: titleBlock + bodyHeight
        readonly property real blockTop: Math.max(Kit.tokens.space.page, (height - blockHeight) / 2)
        readonly property real blockLeft: (width - columnWidth) / 2

        Component.onCompleted: console.log("ZEN stage", height, "blockTop", blockTop, "blockHeight", blockHeight,
                                            "titleBlock", titleBlock, "bodyHeight", bodyHeight,
                                            "contentHeight", bodyView.contentHeight, "col", columnWidth)
        onHeightChanged: console.log("ZEN resize", width, height, "root", root.width, root.height,
                                     "body", bodyView.height, "content", bodyView.contentHeight)

        Text {
            id: titleText
            visible: root.slide.title !== ""
            x: slideContent.blockLeft
            y: slideContent.blockTop
            width: slideContent.columnWidth
            text: root.slide.title
            wrapMode: Text.WordWrap
            color: root.headingColor
            font.family: root.titleFamily
            font.pixelSize: Kit.tokens.size.display * root.scale
            font.weight: Kit.tokens.weight.strong
            font.hintingPreference: Font.PreferNoHinting
            renderType: Text.NativeRendering
            lineHeight: 1.1
        }

        MarkdownView {
            id: bodyView
            x: slideContent.blockLeft
            y: slideContent.blockTop + slideContent.titleBlock
            width: slideContent.columnWidth
            height: slideContent.bodyHeight
            source: ""
            blocks: root.slide.body
            mode: "stage"
            family: root.family
            headingColor: root.headingColor
            scale: root.scale
            pad: 0
            scrollBar: bodyView.contentHeight > bodyView.height
            label: "Slide content"
            onHeightChanged: console.log("ZEN body height", height, "content", contentHeight,
                                         "stage", slideContent.height, "top", slideContent.blockTop)
            onContentHeightChanged: console.log("ZEN content", contentHeight, "body height", height,
                                               "stage", slideContent.height)
        }

        Text {
            visible: root.count === 0
            anchors.centerIn: parent
            width: Math.min(parent.width - 2 * Kit.tokens.space.page, Kit.tokens.width.list)
            text: "Nothing to present yet. Press Esc to go back and write a slide."
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: Kit.tokens.inkSec
            font.family: Kit.tokens.font.main
            font.pixelSize: Kit.tokens.size.body
            font.hintingPreference: Font.PreferNoHinting
            renderType: Text.NativeRendering
        }

        Rectangle {
            x: bodyView.x
            y: bodyView.y
            width: bodyView.width
            height: bodyView.height
            color: "transparent"
            // border.color: "red"
            // border.width: 1
            z: 99
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            // border.color: "blue"
            // border.width: 1
            z: 99
        }
    }

    Item {
        id: footer
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: Kit.tokens.space.page
            rightMargin: Kit.tokens.space.page
            bottomMargin: Kit.tokens.space.m
        }
        height: Kit.tokens.height.action + Kit.tokens.space.l

        Progress {
            id: progress
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            value: root.count > 0 ? (root.current + 1) / root.count : 0
            label: "Slide progress"
        }

        IconButton {
            id: backButton
            anchors {
                left: parent.left
                top: parent.top
            }
            symbol: "back"
            size: Kit.tokens.icon.nav
            label: "Previous slide"
            enabled: root.current > 0
            onActivated: root.go(root.current - 1)
        }

        IconButton {
            id: forwardButton
            anchors {
                left: backButton.right
                top: parent.top
            }
            symbol: "forward"
            size: Kit.tokens.icon.nav
            label: "Next slide"
            enabled: root.current >= 0 && root.current < root.count - 1
            onActivated: root.go(root.current + 1)
        }

        TacitText {
            visible: root.numbers
            anchors {
                left: forwardButton.right
                leftMargin: Kit.tokens.space.m
                verticalCenter: backButton.verticalCenter
            }
            text: root.count === 0 ? "0 of 0" : (root.current + 1) + " of " + root.count
            size: "meta"
            ink: "meta"
            cut: "numbers"
        }

        IconButton {
            anchors {
                right: parent.right
                top: parent.top
            }
            symbol: "close"
            size: Kit.tokens.icon.nav
            label: "Stop presenting"
            onActivated: root.exitRequested()
        }
    }
}
