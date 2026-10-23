import QtQuick 2.15
import SddmComponents 2.0

// Retroism "Platinum" SDDM theme.
// Palette mirrors ~/.config/quickshell/retroism/Config.qml
//   base #b4b4b4  shadow #666666  highlight #ffffff  well #909090  accent #1f6f6a
Rectangle {
    id: root
    width: 1920
    height: 1080

    property int sessionIndex: session.index

    TextConstants { id: textConstants }

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
    }

    // Slight dim so the panel reads clearly
    Rectangle {
        anchors.fill: parent
        color: "#0000003d"
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            passwordField.text = "";
            errorText.text = "Login failed — try again";
            passwordField.forceActiveFocus();
        }
        function onInformationMessage(message) {
            errorText.text = message;
        }
    }

    // ── Platinum panel ───────────────────────────────────────────────────
    Rectangle {
        id: panel
        width: 440
        height: 340
        anchors.centerIn: parent
        color: "#b4b4b4"
        border.width: 1
        border.color: "#000000"

        // raised bevel
        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 1
            anchors.left: parent.left; anchors.leftMargin: 1
            anchors.right: parent.right; anchors.rightMargin: 1
            height: 3
            color: "#ffffff"
        }
        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 1
            anchors.left: parent.left; anchors.leftMargin: 1
            anchors.bottom: parent.bottom; anchors.bottomMargin: 1
            width: 3
            color: "#ffffff"
        }
        Rectangle {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 1
            anchors.left: parent.left; anchors.leftMargin: 1
            anchors.right: parent.right; anchors.rightMargin: 1
            height: 3
            color: "#666666"
        }
        Rectangle {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 1
            anchors.right: parent.right; anchors.rightMargin: 1
            anchors.top: parent.top; anchors.topMargin: 1
            width: 3
            color: "#666666"
        }

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 10

            Text {
                text: "Retroism"
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: "DejaVu Sans"
                font.pixelSize: 26
                font.bold: true
                color: "#000000"
            }

            Text {
                text: sddm.hostName || ""
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: "DejaVu Sans Mono"
                font.pixelSize: 11
                color: "#333333"
            }

            // Username
            Text {
                text: "Username"
                font.family: "DejaVu Sans Mono"
                font.pixelSize: 11
                color: "#000000"
            }
            Rectangle {
                width: parent.width
                height: 28
                color: "#909090"
                border.width: 1
                border.color: "#000000"
                Rectangle {
                    anchors.top: parent.top; anchors.topMargin: 1
                    anchors.left: parent.left; anchors.leftMargin: 1
                    width: parent.width - 2; height: 2
                    color: "#666666"
                }
                TextInput {
                    id: userField
                    anchors.fill: parent
                    anchors.margins: 6
                    verticalAlignment: TextInput.AlignVCenter
                    text: userModel.lastUser
                    font.family: "DejaVu Sans Mono"
                    font.pixelSize: 13
                    color: "#000000"
                    KeyNavigation.tab: passwordField
                }
            }

            // Password
            Text {
                text: "Password"
                font.family: "DejaVu Sans Mono"
                font.pixelSize: 11
                color: "#000000"
            }
            Rectangle {
                width: parent.width
                height: 28
                color: "#909090"
                border.width: 1
                border.color: "#000000"
                Rectangle {
                    anchors.top: parent.top; anchors.topMargin: 1
                    anchors.left: parent.left; anchors.leftMargin: 1
                    width: parent.width - 2; height: 2
                    color: "#666666"
                }
                TextInput {
                    id: passwordField
                    anchors.fill: parent
                    anchors.margins: 6
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    font.family: "DejaVu Sans Mono"
                    font.pixelSize: 13
                    color: "#000000"
                    focus: true
                    KeyNavigation.tab: loginButtonArea
                    onAccepted: sddm.login(userField.text, passwordField.text, root.sessionIndex)
                }
            }

            Text {
                id: errorText
                text: ""
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                font.family: "DejaVu Sans Mono"
                font.pixelSize: 10
                color: "#a02020"
            }

            // Log In button
            Rectangle {
                id: loginButtonArea
                width: parent.width
                height: 34
                color: loginMouse.pressed ? "#909090" : "#1f6f6a"
                border.width: 1
                border.color: "#000000"

                Rectangle {
                    anchors.top: parent.top; anchors.topMargin: 1
                    anchors.left: parent.left; anchors.leftMargin: 1
                    anchors.right: parent.right; anchors.rightMargin: 1
                    height: 2
                    color: loginMouse.pressed ? "#666666" : "#ffffff"
                }
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 1
                    anchors.left: parent.left; anchors.leftMargin: 1
                    anchors.right: parent.right; anchors.rightMargin: 1
                    height: 2
                    color: loginMouse.pressed ? "#ffffff" : "#666666"
                }

                Text {
                    anchors.centerIn: parent
                    text: "Log In"
                    font.family: "DejaVu Sans"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#ffffff"
                }

                MouseArea {
                    id: loginMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.login(userField.text, passwordField.text, root.sessionIndex)
                }
            }

            // Session selector
            Row {
                spacing: 6
                width: parent.width

                Text {
                    text: "Session:"
                    font.family: "DejaVu Sans Mono"
                    font.pixelSize: 10
                    color: "#000000"
                    anchors.verticalCenter: parent.verticalCenter
                }
                ComboBox {
                    id: sessionBox
                    width: parent.width - 70
                    height: 24
                    model: sessionModel
                    index: 0
                    textColor: "#000000"
                    font.family: "DejaVu Sans Mono"
                    font.pixelSize: 10
                    onIndexChanged: root.sessionIndex = index
                }
            }
        }
    }

    // ── Power controls ───────────────────────────────────────────────────
    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 18
        spacing: 10

        Repeater {
            model: [
                { label: "Suspend", action: "suspend", visible: sddm.canSuspend },
                { label: "Reboot", action: "reboot", visible: sddm.canPowerOff },
                { label: "Shut Down", action: "poweroff", visible: sddm.canPowerOff }
            ]

            Rectangle {
                visible: modelData.visible
                width: powerLabel.implicitWidth + 20
                height: 26
                color: powerMouse.pressed ? "#909090" : "#b4b4b4"
                border.width: 1
                border.color: "#000000"

                Rectangle {
                    anchors.top: parent.top; anchors.topMargin: 1
                    anchors.left: parent.left; anchors.leftMargin: 1
                    anchors.right: parent.right; anchors.rightMargin: 1
                    height: 2
                    color: "#ffffff"
                }

                Text {
                    id: powerLabel
                    anchors.centerIn: parent
                    text: modelData.label
                    font.family: "DejaVu Sans Mono"
                    font.pixelSize: 11
                    color: "#000000"
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.action === "reboot") sddm.reboot();
                        else if (modelData.action === "poweroff") sddm.powerOff();
                        else if (modelData.action === "suspend") sddm.suspend();
                    }
                }
            }
        }
    }

    Component.onCompleted: passwordField.forceActiveFocus()
}
