import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import ".."

// Retroism function-key bar (bottom of screen). Purely additive: it does NOT
// touch niri keybinds. Each key is also mouse-clickable.
Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: fnbar
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: Config.colors.base
            anchors {
                bottom: true
                left: true
                right: true
            }
            implicitHeight: 26

            NewBorder {
                commonBorderWidth: 4
                commonBorder: false
                lBorderwidth: 10
                rBorderwidth: 1
                tBorderwidth: 1
                bBorderwidth: 10
                borderColor: Config.colors.shadow
            }
            NewBorder {
                commonBorderWidth: 4
                commonBorder: false
                lBorderwidth: 10
                rBorderwidth: 10
                tBorderwidth: 10
                bBorderwidth: 1
                borderColor: Config.colors.highlight
            }

            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: [
                        { k: "F1", label: "Overview", run: ["niri", "msg", "action", "toggle-overview"] },
                        { k: "F2", label: "Launch", run: ["fuzzel"] },
                        { k: "F3", label: "Terminal", run: ["ghostty"] },
                        { k: "F4", label: "Browser", run: ["librewolf"] },
                        { k: "F5", label: "Monitor", ipc: "sysmon" },
                        { k: "F6", label: "Capture", run: ["niri", "msg", "action", "screenshot-screen"] },
                        { k: "F7", label: "Files", run: ["nautilus"] }
                    ]

                    Rectangle {
                        implicitWidth: 74
                        implicitHeight: 20
                        border.width: 1
                        border.color: Config.colors.outline
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Config.colors.highlight }
                            GradientStop { position: 0.55; color: Config.colors.accent }
                            GradientStop { position: 1.0; color: Config.colors.shadow }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: modelData.k
                                font.family: fontMonaco.name
                                font.pixelSize: 11
                                font.bold: true
                                color: Config.colors.text
                            }
                            Text {
                                text: modelData.label
                                font.family: fontMonaco.name
                                font.pixelSize: 10
                                color: Config.colors.text
                                opacity: 0.85
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.ipc)
                                    Quickshell.execDetached(["qs", "ipc", "call", modelData.ipc, "toggle"]);
                                else
                                    Quickshell.execDetached(modelData.run);
                            }
                        }
                    }
                }
            }
        }
    }
}
