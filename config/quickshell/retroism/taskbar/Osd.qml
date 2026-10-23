import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import ".."

/* Platinum on-screen display for volume and brightness.
 *
 * Volume   : reacts to PipeWire changes (media keys run wpctl).
 * Brightness: watches /sys/class/backlight via FileView (no forks).
 * Never takes keyboard focus and never reserves screen space.
 */
PanelWindow {
    id: root

    visible: false
    color: "transparent"

    anchors {
        bottom: true
        left: true
        right: true
    }
    margins {
        bottom: 70
    }
    implicitHeight: 92

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property string kind: "volume"
    property int value: 0
    property bool muted: false

    function flash(what, val, isMuted) {
        root.kind = what;
        root.value = Math.max(0, Math.min(100, val));
        root.muted = isMuted === true;
        root.visible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: root.visible = false
    }

    // ── Volume source ────────────────────────────────────────────────────
    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }
    property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    Connections {
        target: root.audio
        enabled: root.audio !== null
        function onVolumeChanged() {
            root.flash("volume", Math.round(root.audio.volume * 100), root.audio.muted);
        }
        function onMutedChanged() {
            root.flash("volume", Math.round(root.audio.volume * 100), root.audio.muted);
        }
    }

    // ── Brightness source ────────────────────────────────────────────────
    FileView { id: blNow; path: "/sys/class/backlight/intel_backlight/brightness"; blockLoading: true; printErrors: false }
    FileView { id: blMax; path: "/sys/class/backlight/intel_backlight/max_brightness"; blockLoading: true; printErrors: false }

    property int lastBrightness: -1

    Timer {
        interval: 300
        repeat: true
        running: true
        onTriggered: {
            blNow.reload();
            blMax.reload();
            const raw = parseInt(blNow.text() || "-1");
            const max = parseInt(blMax.text() || "0");
            if (raw < 0 || max <= 0)
                return;
            if (raw !== root.lastBrightness) {
                if (root.lastBrightness !== -1 && !root.visible)
                    root.flash("brightness", Math.round(100 * raw / max), false);
                root.lastBrightness = raw;
            }
        }
    }

    // ── Presentation ─────────────────────────────────────────────────────
    Rectangle {
        id: frame
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: 340
        height: 84
        color: Config.colors.base
        border.width: 1
        border.color: Config.colors.outline

        // raised bevel
        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 1
            anchors.left: parent.left; anchors.leftMargin: 1
            anchors.right: parent.right; anchors.rightMargin: 1
            height: 3
            color: Config.colors.highlight
        }
        Rectangle {
            anchors.top: parent.top; anchors.topMargin: 1
            anchors.left: parent.left; anchors.leftMargin: 1
            height: parent.height - 2
            width: 3
            color: Config.colors.highlight
        }
        Rectangle {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 1
            anchors.left: parent.left; anchors.leftMargin: 1
            anchors.right: parent.right; anchors.rightMargin: 1
            height: 3
            color: Config.colors.shadow
        }
        Rectangle {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 1
            anchors.right: parent.right; anchors.rightMargin: 1
            height: parent.height - 2
            width: 3
            color: Config.colors.shadow
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.kind === "volume" ? (root.muted ? "VOLUME — MUTED" : "VOLUME") : "BRIGHTNESS"
                    font.family: fontCharcoal.name
                    font.pixelSize: 13
                    font.bold: true
                    color: Config.colors.text
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.value + "%"
                    font.family: fontMonaco.name
                    font.pixelSize: 14
                    font.bold: true
                    color: Config.colors.text
                }
            }

            // Segmented bar (20 blocks) in a sunken well
            Rectangle {
                Layout.fillWidth: true
                height: 22
                color: Config.colors.well
                border.width: 1
                border.color: Config.colors.outline

                Rectangle {
                    anchors.top: parent.top; anchors.topMargin: 1
                    anchors.left: parent.left; anchors.leftMargin: 1
                    anchors.right: parent.right; anchors.rightMargin: 1
                    height: 2
                    color: Config.colors.shadow
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 3

                    Repeater {
                        model: 20
                        Rectangle {
                            width: (parent.width - 19 * 3) / 20
                            height: parent.height
                            color: root.muted ? "#8a8a8a"
                                : (index < Math.round(root.value / 5) ? Config.colors.accent : "#a8a8a8")
                            border.width: 1
                            border.color: Config.colors.outline
                        }
                    }
                }
            }
        }
    }
}
