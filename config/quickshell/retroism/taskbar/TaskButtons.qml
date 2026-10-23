import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import ".."

// Windows-style task buttons for niri, driven by the wlr-foreign-toplevel
// protocol (niri implements it). Click = activate, middle-click = close.
RowLayout {
    id: taskButtons
    spacing: 3

    Repeater {
        model: ToplevelManager.toplevels

        Item {
            id: btn
            required property var modelData
            implicitWidth: Math.min(190, btnLabel.implicitWidth + 18)
            implicitHeight: 24

            Rectangle {
                anchors.fill: parent
                color: btn.modelData.activated ? Config.colors.well : Config.colors.base
                border.width: 1
                border.color: Config.colors.outline

                // bevel: sunken when active, raised otherwise
                Rectangle {
                    anchors.top: parent.top; anchors.topMargin: 1
                    anchors.left: parent.left; anchors.leftMargin: 1
                    width: parent.width - 2; height: 3
                    color: btn.modelData.activated ? Config.colors.shadow : Config.colors.highlight
                }
                Rectangle {
                    anchors.top: parent.top; anchors.topMargin: 1
                    anchors.left: parent.left; anchors.leftMargin: 1
                    width: 3; height: parent.height - 2
                    color: btn.modelData.activated ? Config.colors.shadow : Config.colors.highlight
                }
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 1
                    anchors.right: parent.right; anchors.rightMargin: 1
                    width: parent.width - 2; height: 3
                    color: btn.modelData.activated ? Config.colors.highlight : Config.colors.shadow
                }
            }

            Text {
                id: btnLabel
                anchors.centerIn: parent
                width: Math.min(170, implicitWidth)
                text: btn.modelData.title || btn.modelData.appId || "?"
                font.family: fontMonaco.name
                font.pixelSize: Config.settings.bar.fontSize
                color: Config.colors.text
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: event => {
                    if (event.button === Qt.MiddleButton)
                        btn.modelData.close();
                    else
                        btn.modelData.activate();
                }
            }
        }
    }
}
