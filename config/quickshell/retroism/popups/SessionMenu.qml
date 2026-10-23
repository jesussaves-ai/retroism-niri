import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import ".."

// Platinum session/power menu popup.
PopupWindow {
    id: root

    property int menuWidth: 0
    property var closeCallback: function () {}
    anchor.window: taskbar
    anchor.rect.x: menuWidth
    anchor.rect.y: parentWindow.implicitHeight
    implicitWidth: 220
    implicitHeight: 236
    color: "transparent"

    Rectangle {
        id: frame
        anchors.fill: parent
        color: Config.colors.base
        layer.enabled: true

        property int topOffset: 20

        PopupWindowFrame {
            id: sesFrame
            windowTitle: "Session"
            windowTitleIcon: "\uf418"
            windowTitleDecorationWidth: 52

            Column {
                anchors.fill: sesFrame
                anchors.margins: 14
                anchors.topMargin: frame.topOffset + 14
                spacing: 6

                Repeater {
                    model: [
                        { label: "Lock Screen", cmd: ["loginctl", "lock-session"] },
                        { label: "Log Out",     cmd: ["niri", "msg", "action", "quit"] },
                        { label: "Reboot",      cmd: ["systemctl", "reboot"] },
                        { label: "Shut Down",   cmd: ["systemctl", "poweroff"] }
                    ]

                    Rectangle {
                        width: parent.width
                        height: 34
                        color: "transparent"
                        border.width: 1
                        border.color: Config.colors.outline

                        NewBorder {
                            commonBorderWidth: 2
                            commonBorder: false
                            lBorderwidth: 2; rBorderwidth: 0; tBorderwidth: 2; bBorderwidth: 0
                            borderColor: Config.colors.highlight
                        }
                        NewBorder {
                            commonBorderWidth: 2
                            commonBorder: false
                            lBorderwidth: 0; rBorderwidth: 2; tBorderwidth: 0; bBorderwidth: 2
                            borderColor: Config.colors.shadow
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: fontCharcoal.name
                            font.pixelSize: 12
                            color: Config.colors.text
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(modelData.cmd);
                                root.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }

    function toggle() {
        root.visible = !root.visible;
    }
}
