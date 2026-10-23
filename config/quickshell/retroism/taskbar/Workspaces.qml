import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

import ".."

// Workspace buttons for niri. Uses a persistent `niri msg` event listener
// (utils/niri-workspaces.sh) instead of the Quickshell.Niri module, which
// upstream Quickshell does not ship. Visuals match the Retroism taskbar.

RowLayout {
    id: workspaces
    spacing: 3
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter

    property var allWorkspaces: []

    Process {
        id: wsProc
        command: ["sh", "/home/tom/.config/quickshell/retroism/utils/niri-workspaces.sh"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line);
                    if (Array.isArray(data))
                        workspaces.allWorkspaces = data;
                } catch (e) {
                    // ignore malformed lines
                }
            }
        }
    }

    property var currentWorkspaces: workspaces.allWorkspaces.filter(
        w => w.output === taskbar.screen.name)

    Repeater {
        model: parent.currentWorkspaces
        Button {
            id: control
            anchors.centerIn: parent.centerIn
            contentItem: Text {
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData.idx
                font.family: fontMonaco.name
                width: 10
                height: 10
                font.pixelSize: Config.settings.bar.fontSize
                color: Config.colors.text
            }
            onPressed: event => {
                Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(modelData.idx)]);
                event.accepted = true;
            }

            property bool isActive: modelData.focused || mouse.hovered

            background: Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                width: 24
                height: 24
                color: modelData.urgent ? Config.colors.urgent : (isActive ? Config.colors.well : Config.colors.base)
                border.width: 1
                border.color: Config.colors.outline

                // Raised bevel normally, inverted (sunken) when active
                Rectangle {
                    anchors.top: parent.top; anchors.topMargin: 1
                    anchors.left: parent.left; anchors.leftMargin: 1
                    width: parent.width - 2; height: 3
                    color: isActive ? Config.colors.shadow : Config.colors.highlight
                }
                Rectangle {
                    anchors.top: parent.top; anchors.topMargin: 1
                    anchors.left: parent.left; anchors.leftMargin: 1
                    width: 3; height: parent.height - 2
                    color: isActive ? Config.colors.shadow : Config.colors.highlight
                }
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 1
                    anchors.right: parent.right; anchors.rightMargin: 1
                    width: parent.width - 2; height: 3
                    color: isActive ? Config.colors.highlight : Config.colors.shadow
                }
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 1
                    anchors.right: parent.right; anchors.rightMargin: 1
                    width: 3; height: parent.height - 2
                    color: isActive ? Config.colors.highlight : Config.colors.shadow
                }
            }

            HoverHandler {
                id: mouse
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
