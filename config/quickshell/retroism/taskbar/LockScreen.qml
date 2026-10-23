import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

import ".."

// Platinum lockscreen (wlr-session-lock + PAM).
// NOT wired to a keybind by default — enable via:
//     qs ipc -c retroism call lock lock
// Escape hatch if PAM misbehaves: Ctrl+Alt+F2 to a TTY, `pkill qs`.
Scope {
    id: lockRoot

    WlSessionLock {
        id: sessionLock
        locked: false

        WlSessionLockSurface {
            color: Config.colors.base

            // Platinum wall: pinstripe gradient
            Image {
                anchors.fill: parent
                source: "file:///home/tom/.config/ghostty/platinum-bg.png"
                fillMode: Image.Stretch
                smooth: false
            }

            // Centered unlock panel
            Rectangle {
                anchors.centerIn: parent
                width: 400
                height: 230
                color: Config.colors.base
                border.width: 1
                border.color: Config.colors.outline

                // raised bevel
                Rectangle {
                    anchors.top: parent.top; anchors.topMargin: 1
                    anchors.left: parent.left; anchors.leftMargin: 1
                    width: parent.width - 2; height: 3
                    color: Config.colors.highlight
                }
                Rectangle {
                    anchors.top: parent.top; anchors.topMargin: 1
                    anchors.left: parent.left; anchors.leftMargin: 1
                    width: 3; height: parent.height - 2
                    color: Config.colors.highlight
                }
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 1
                    anchors.right: parent.right; anchors.rightMargin: 1
                    width: parent.width - 2; height: 3
                    color: Config.colors.shadow
                }
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 1
                    anchors.right: parent.right; anchors.rightMargin: 1
                    width: 3; height: parent.height - 2
                    color: Config.colors.shadow
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Retroism"
                        font.family: fontCharcoal.name
                        font.pixelSize: 22
                        color: Config.colors.text
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: pamCtx.message || "Enter password to unlock"
                        font.family: fontMonaco.name
                        font.pixelSize: 11
                        color: pamCtx.messageIsError ? Config.colors.urgent : Config.colors.text
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        color: Config.colors.well
                        border.width: 1
                        border.color: Config.colors.outline

                        TextInput {
                            id: pw
                            anchors.fill: parent
                            anchors.margins: 6
                            echoMode: TextInput.Password
                            font.family: fontMonaco.name
                            font.pixelSize: 14
                            color: Config.colors.text
                            focus: true
                            onAccepted: {
                                if (text.length === 0) return;
                                if (!pamCtx.active) pamCtx.start();
                                pamCtx.respond(text);
                                text = "";
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Press Enter to unlock"
                        font.family: fontMonaco.name
                        font.pixelSize: 10
                        color: Config.colors.text
                        opacity: 0.7
                    }
                }
            }

            PamContext {
                id: pamCtx
                user: "tom"
                config: "login"
                onCompleted: result => {
                    if (result === PamResult.Success)
                        sessionLock.locked = false;
                    else
                        pw.text = "";
                }
            }

            Component.onCompleted: pw.forceActiveFocus()
        }
    }

    IpcHandler {
        target: "lock"
        function lock() {
            sessionLock.locked = true;
        }
        function unlock() {
            sessionLock.locked = false;
        }
    }
}
