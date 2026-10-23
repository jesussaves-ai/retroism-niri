import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

import ".."

// Volume / battery / network cluster — sunken Platinum "wells" with a hard
// black outline and a 2px inverted bevel for depth.
RowLayout {
    id: cluster
    spacing: 3

    // Required: without tracking the node, Quickshell leaves volume/muted at
    // their defaults (observed vol=0 muted=false while wpctl said 0.80/MUTED).
    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    // ── Network ─────────────────────────────────────────────────────────
    Item {
        implicitWidth: netText.implicitWidth + 16
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
            id: netText
            anchors.centerIn: parent
            font.family: fontMonaco.name
            font.pixelSize: Config.settings.bar.fontSize
            color: Config.colors.text
            property var devs: Networking.devices ? Networking.devices.values : []
            property var connected: devs.filter(d => d.connected)
            text: connected.length > 0 ? "NET" : "OFF"
            opacity: connected.length > 0 ? 1.0 : 0.55
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["nm-connection-editor"])
        }
    }

    // ── Volume ──────────────────────────────────────────────────────────
    Item {
        implicitWidth: volText.implicitWidth + 16
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
            id: volText
            anchors.centerIn: parent
            font.family: fontMonaco.name
            font.pixelSize: Config.settings.bar.fontSize
            color: Config.colors.text
            property var sink: Pipewire.defaultAudioSink
            property var audio: sink ? sink.audio : null
            property int pct: audio ? Math.round(audio.volume * 100) : 0
            property bool muted: audio ? audio.muted : false
            text: muted ? "MUTE" : "VOL " + pct + "%"
            opacity: muted ? 0.65 : 1.0
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
            onWheel: wheel => {
                if (wheel.angleDelta.y > 0)
                    Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", "5%+"]);
                else
                    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]);
            }
        }
    }

    // ── Battery ─────────────────────────────────────────────────────────
    Item {
        visible: UPower.displayDevice ? UPower.displayDevice.isPresent : false
        implicitWidth: batText.implicitWidth + 16
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
            id: batText
            anchors.centerIn: parent
            font.family: fontMonaco.name
            font.pixelSize: Config.settings.bar.fontSize
            color: Config.colors.text
            property var d: UPower.displayDevice
            property int pct: d ? Math.round(d.percentage * 100) : 0
            text: (d && d.onBattery ? "BAT " : "AC ") + pct + "%"
            opacity: (d && d.onBattery && pct <= 15) ? 0.65 : 1.0
        }
    }
}
