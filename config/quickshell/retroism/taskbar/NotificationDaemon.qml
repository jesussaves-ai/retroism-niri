import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

import ".."

// Platinum-styled notification daemon. Owns the org.freedesktop.Notifications
// name and renders tracked notifications in a top-right overlay stack.
Scope {
    id: daemon

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: false
        actionsSupported: false
        onNotification: notif => {
            notif.tracked = true;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popupWin
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "transparent"
            visible: server.trackedNotifications.values.length > 0

            anchors {
                top: true
                right: true
            }
            margins {
                top: 42
                right: 10
            }
            implicitWidth: 330
            implicitHeight: Math.min(520, 8 + stack.implicitHeight)

            Column {
                id: stack
                spacing: 6
                width: parent.width

                Repeater {
                    model: server.trackedNotifications
                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        width: stack.width
                        implicitHeight: cardCol.implicitHeight + 18
                        color: Config.colors.base

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
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.width: 1
                            border.color: Config.colors.outline
                        }

                        Column {
                            id: cardCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 4

                            Text {
                                width: parent.width
                                text: card.modelData.appName || "System"
                                font.family: fontCharcoal.name
                                font.pixelSize: 11
                                font.bold: true
                                color: Config.colors.accent
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: card.modelData.summary || ""
                                font.family: fontCharcoal.name
                                font.pixelSize: 12
                                color: Config.colors.text
                                wrapMode: Text.WordWrap
                            }
                            Text {
                                width: parent.width
                                visible: text.length > 0
                                text: card.modelData.body || ""
                                font.family: fontMonaco.name
                                font.pixelSize: 11
                                color: Config.colors.text
                                opacity: 0.85
                                wrapMode: Text.WordWrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.modelData.dismiss()
                        }
                    }
                }
            }
        }
    }
}
