import Quickshell
import QtQuick
import QtQuick.Controls.Basic

import ".."

// Platinum toolbutton: hard outline + 2px bevel, inverted when toggled/pressed.
Button {
    id: root

    property bool isToggled: false
    property string iconFontValue: "\ue5c3"
    property string toggledIconFontValue: "\ue5c5"

    implicitWidth: 26
    implicitHeight: 24

    background: Rectangle {
        anchors.fill: parent
        color: root.isToggled ? Config.colors.well : (mouse.hovered ? Config.colors.highlight : Config.colors.base)
        border.width: 1
        border.color: Config.colors.outline

        // Bevel: raised normally, sunken when toggled/pressed
        property bool sunken: root.isToggled || root.pressed

        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 1
            anchors.left: parent.left; anchors.leftMargin: 1
            width: parent.width - 2; height: 3
            color: parent.sunken ? Config.colors.shadow : Config.colors.highlight
        }
        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 1
            anchors.left: parent.left; anchors.leftMargin: 1
            width: 3; height: parent.height - 2
            color: parent.sunken ? Config.colors.shadow : Config.colors.highlight
        }
        Rectangle {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 1
            anchors.right: parent.right; anchors.rightMargin: 1
            width: parent.width - 2; height: 3
            color: parent.sunken ? Config.colors.highlight : Config.colors.shadow
        }
        Rectangle {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 1
            anchors.right: parent.right; anchors.rightMargin: 1
            width: 3; height: parent.height - 2
            color: parent.sunken ? Config.colors.highlight : Config.colors.shadow
        }

        Text {
            anchors.centerIn: parent
            font.family: iconFont.name
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            text: root.isToggled ? root.toggledIconFontValue : root.iconFontValue
            color: Config.colors.text
        }
    }

    HoverHandler {
        id: mouse
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        cursorShape: Qt.PointingHandCursor
    }
}
