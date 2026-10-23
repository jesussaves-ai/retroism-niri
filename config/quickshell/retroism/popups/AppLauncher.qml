import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

import ".."
import "../utils" as Utils

/* Retroism app launcher.
 *
 * Converted from an anchored PopupWindow to a full-screen Overlay layer
 * surface: a popup window never received keyboard focus (activeFocus=false),
 * so typing in the search box did nothing. A layer surface with
 * WlrKeyboardFocus.Exclusive reliably receives key events.
 */
PanelWindow {
    id: root

    // menuWidth / screenHeight are still passed by Bar.qml; kept for
    // compatibility although the overlay no longer needs them.
    property int menuWidth: 0
    property int screenHeight: 0
    property int popupWidth: 600
    property var currentApps: []
    property var closeCallback: function () {}

    visible: false
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // Click anywhere outside the frame closes the launcher
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeAppLauncher()
    }

    // DesktopEntries is scanned asynchronously: on a fresh shell the list can
    // still be empty when the launcher is first opened. Retry until populated.
    Timer {
        id: retryTimer
        interval: 250
        repeat: true
        running: false
        onTriggered: {
            if (Utils.AppSearch.list.length > 0) {
                retryTimer.stop();
                if (searchInput.text.length === 0)
                    root.currentApps = Array.from(Utils.AppSearch.list);
            }
        }
    }

    Rectangle {
        id: frame
        anchors.centerIn: parent
        implicitWidth: root.popupWidth
        implicitHeight: 380
        color: Config.colors.base
        layer.enabled: true

        property int topOffset: 20

        PopupWindowFrame {
            id: startMenuFrame
            windowTitle: "Search"
            windowTitleIcon: "\ue8b6"
            windowTitleDecorationWidth: 190

            Item {
                id: content
                anchors.fill: startMenuFrame
                anchors.margins: 8
                anchors.topMargin: frame.topOffset + 20
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        implicitHeight: 40
                        color: Config.colors.highlight
                        border.color: Config.colors.outline
                        border.width: 1
                        clip: true

                        TextField {
                            id: searchInput
                            width: parent.width
                            anchors.centerIn: parent
                            text: ""
                            font.pixelSize: 16
                            font.family: fontMonaco.name
                            color: Config.colors.text
                            selectionColor: Config.colors.shadow
                            padding: 2
                            selectByMouse: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            focus: true

                            background: Rectangle {
                                color: "transparent"
                            }

                            Keys.onEscapePressed: root.closeAppLauncher()

                            onAccepted: {
                                if (root.currentApps.length > 0) {
                                    root.currentApps[0].execute();
                                    root.closeAppLauncher();
                                }
                            }
                            onTextChanged: {
                                if (searchInput.text.length === 0)
                                    root.currentApps = Array.from(Utils.AppSearch.list);
                                else
                                    root.currentApps = Utils.AppSearch.fuzzyQuery(searchInput.text);
                            }
                        }

                        Rectangle {
                            implicitHeight: 40
                            implicitWidth: 40
                            Layout.alignment: Qt.AlignLeft
                            color: Config.colors.base
                            border.color: Config.colors.outline
                            border.width: 1
                            Text {
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                anchors.fill: parent
                                font.family: iconFont.name
                                font.pixelSize: 24
                                text: "\ue8b6"
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: parent.width
                        implicitHeight: parent.height - 60
                        color: "transparent"
                        border.color: Config.colors.outline
                        border.width: 1
                        clip: true

                        ListView {
                            id: appsView
                            model: root.currentApps
                            anchors.fill: parent
                            anchors.margins: 6
                            anchors.bottomMargin: 1
                            flickableDirection: Flickable.VerticalFlick
                            boundsBehavior: Flickable.DragOverBounds
                            maximumFlickVelocity: 3500
                            clip: true
                            spacing: 4

                            delegate: Item {
                                width: parent.width
                                height: 34
                                Button {
                                    width: parent.width
                                    height: 34
                                    opacity: mouse.hovered ? 0.85 : 1
                                    background: Rectangle {
                                        anchors.fill: parent
                                        color: parent.pressed ? Config.colors.shadow : Config.colors.highlight
                                        border.width: 1
                                        border.color: Config.colors.outline
                                    }
                                    onReleased: {
                                        modelData.execute();
                                        root.closeAppLauncher();
                                    }
                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 0
                                        property var iconPath: Utils.AppSearch.getIcon(modelData.icon)
                                        Image {
                                            Layout.leftMargin: 8
                                            asynchronous: true
                                            Layout.maximumWidth: 20
                                            Layout.maximumHeight: 20
                                            antialiasing: true
                                            source: parent.iconPath
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 8
                                            Layout.alignment: Qt.AlignLeft
                                            text: modelData.name
                                            font.family: fontMonaco.name
                                            font.pixelSize: 12
                                            color: Config.colors.text
                                            elide: Text.ElideRight
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
                    }
                }
            }
        }
    }

    function openAppLauncher() {
        root.visible = true;
        root.currentApps = Array.from(Utils.AppSearch.list);
        if (root.currentApps.length === 0)
            retryTimer.start();
        searchInput.text = "";
        searchInput.forceActiveFocus();
    }

    function closeAppLauncher() {
        root.visible = false;
        Config.currentPopup = Config.SystemPopup.None;
    }
}
