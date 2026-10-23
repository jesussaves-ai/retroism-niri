import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

import ".."

// Now-playing strip: Platinum well showing track + transport controls.
// Hidden entirely when no MPRIS player is active.
RowLayout {
    id: media
    spacing: 3

    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    visible: player !== null && (player.trackTitle || player.trackArtist)

    Item {
        implicitWidth: mediaText.implicitWidth + 16
        implicitHeight: 24
        Rectangle {
            anchors.fill: parent
            color: Config.colors.well
            border.width: 1
            border.color: Config.colors.outline
        }
        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 1
            anchors.left: parent.left; anchors.leftMargin: 1
            width: parent.width - 2; height: 3
            color: Config.colors.shadow
        }
        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 1
            anchors.left: parent.left; anchors.leftMargin: 1
            width: 3; height: parent.height - 2
            color: Config.colors.shadow
        }
        Rectangle {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 1
            anchors.right: parent.right; anchors.rightMargin: 1
            width: parent.width - 2; height: 3
            color: Config.colors.highlight
        }
        Text {
            id: mediaText
            anchors.centerIn: parent
            font.family: fontMonaco.name
            font.pixelSize: Config.settings.bar.fontSize
            color: Config.colors.text
            elide: Text.ElideRight
            maximumLineCount: 1
            property var p: media.player
            text: {
                if (!p) return "";
                const t = p.trackTitle || "";
                const a = p.trackArtist || "";
                const label = a.length > 0 ? (t + " — " + a) : t;
                return (p.isPlaying ? "\u25B6 " : "\u2016 ") + label;
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: media.player && media.player.togglePlaying()
        }
    }

    // Prev / next
    Repeater {
        model: [{ icon: "\u23EE", action: "previous" }, { icon: "\u23ED", action: "next" }]

        Item {
            implicitWidth: 22
            implicitHeight: 24
            Rectangle {
                anchors.fill: parent
                color: Config.colors.base
                border.width: 1
                border.color: Config.colors.outline
            }
            Text {
                anchors.centerIn: parent
                text: modelData.icon
                font.pixelSize: 11
                color: Config.colors.text
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!media.player) return;
                    if (modelData.action === "previous") media.player.previous();
                    else media.player.next();
                }
            }
        }
    }
}
