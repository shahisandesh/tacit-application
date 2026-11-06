// SPDX-License-Identifier: LGPL-3.0-or-later
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Tacit.Kit

// AppList: one column of apps, each a bigger icon beside its name. The kit's RowList of ListRows
// is the part for a list of things, but its rows are 44 high with a small kind picture, and a
// launcher wants the icon and the name said loudly, so this is built from the kit's parts with
// the same keyboard manners: one Tab stop; Up and Down step (Up on the first row asks the page to
// give the keyboard back), Home and End jump, Enter opens; click selects, double click opens.
// `items` is [{ source, name, glyph }]; a row with a glyph shows it in the icon's place,
// which is how the calculator's answer and the emoji list look.
FocusScope {
    id: list

    property var items: []
    property int cursor: -1
    property string label: "Apps"

    signal activated(int index)
    signal upRequested()

    readonly property int count: items.length
    readonly property int rowHeight: 60
    readonly property int iconSide: 48

    function moveTo(i) {
        if (count === 0) return
        cursor = Math.max(0, Math.min(count - 1, i))
    }

    implicitWidth: 528
    implicitHeight: count * rowHeight
    activeFocusOnTab: true
    Accessible.role: Accessible.List
    Accessible.name: label
    onActiveFocusChanged: if (activeFocus && cursor < 0) moveTo(0)
    onItemsChanged: if (cursor >= count) cursor = count - 1

    Keys.onPressed: event => {
        Kit.focusVisible = true
        if (event.key === Qt.Key_Up && cursor <= 0) {
            if (cursor === 0) {
                list.upRequested()
                event.accepted = true
            }
            return
        }
        const by = { [Qt.Key_Left]: -1, [Qt.Key_Right]: 1, [Qt.Key_Up]: -1, [Qt.Key_Down]: 1 }[event.key]
        if (by !== undefined) moveTo(cursor + by)
        else if (event.key === Qt.Key_Home) moveTo(0)
        else if (event.key === Qt.Key_End) moveTo(count - 1)
        else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && cursor >= 0) activated(cursor)
        else return
        event.accepted = true
    }

    Column {
        id: rows
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round(list.width * 0.95)
        spacing: Kit.tokens.space.xs

        Repeater {
            model: list.count

            Item {
                id: row
                required property int index

                readonly property var app: list.items[index]
                readonly property bool chosen: list.cursor === index
                readonly property bool hovered: hover.hovered
                readonly property bool pressed: tap.pressed

                width: rows.width
                height: list.rowHeight
                scale: pressed ? Kit.tokens.state.pressScale : 1
                Behavior on scale {
                    NumberAnimation {
                        duration: Kit.ms(Kit.motion("press").ms)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Kit.tokens.motion.press.curve
                    }
                }
                Accessible.role: Accessible.ListItem
                Accessible.name: String(row.app?.name ?? "")
                Accessible.selected: row.chosen

                // the row's ground: the chosen row wears the pressed wash, as ListRow does
                Rectangle {
                    anchors.fill: parent
                    radius: Kit.tokens.radius.row
                    color: Kit.tokens.inkMain
                    opacity: row.pressed || row.chosen ? Kit.tokens.wash.pressed
                        : row.hovered ? Kit.tokens.wash.hover : 0
                    Behavior on opacity {
                        NumberAnimation { duration: Kit.ms(Kit.tokens.motion.hover.ms) }
                    }
                }
                FocusRing {
                    anchors.fill: parent
                    shown: row.chosen && list.activeFocus && Kit.focusVisible
                    corner: Kit.tokens.radius.row
                }

                Row {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: Kit.tokens.space.m
                    }
                    spacing: Kit.tokens.space.m

                    TacitText {
                        // the emoji or the equals sign, in the icon's place
                        visible: String(row.app?.glyph ?? "") !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        width: list.iconSide
                        horizontalAlignment: Text.AlignHCenter
                        text: String(row.app?.glyph ?? "")
                        size: "row"
                    }
                    Image {
                        id: icon
                        anchors.verticalCenter: parent.verticalCenter
                        width: list.iconSide
                        height: list.iconSide
                        visible: status === Image.Ready && String(row.app?.source ?? "") !== ""
                            && String(row.app?.glyph ?? "") === ""
                        source: String(row.app?.source ?? "")
                        sourceSize: Qt.size(list.iconSide * 2, list.iconSide * 2)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                    }
                    Symbol {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !icon.visible && String(row.app?.glyph ?? "") === ""
                        width: list.iconSide
                        height: list.iconSide
                        text: "apps"
                        size: Math.round(list.iconSide * 0.66)
                        color: Kit.tokens.inkSec
                    }
                    TacitText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: rows.width - list.iconSide - 3 * Kit.tokens.space.m
                        text: String(row.app?.name ?? "")
                        size: "body"
                        weight: "medium"
                        elide: Text.ElideRight
                    }
                }

                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    id: tap
                    onTapped: {
                        list.forceActiveFocus(Qt.MouseFocusReason)
                        Kit.focusVisible = false
                        list.cursor = row.index
                    }
                    onDoubleTapped: list.activated(row.index)
                }
            }
        }
    }
}
