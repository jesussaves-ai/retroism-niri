import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

import "../popups" as Popups
import ".."

Scope {
    // Taskbar variants, we have one taskber per screen.
    Variants {
        model: Quickshell.screens
        Item {
            id: root
            required property var modelData
            property int currentPopup: Config.SystemPopup.None

            PanelWindow {
                id: taskbar
                screen: root.modelData
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                anchors {
                    top: true
                    left: true
                    right: true
                }
                implicitHeight: 36

                /*=== Taskbar Background (colors & shading) ===*/
                color: Config.colors.base
                Item {
                    id: taskbarBackground
                    anchors.fill: parent
                    // Hard 1px black outline (classic Platinum frame)
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 1
                        border.color: Config.colors.outline
                    }
                    // Bright top highlight line -> reads as a raised edge
                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 2
                        height: 1
                        color: Config.colors.highlight
                    }
                    // Dark band along the bottom -> reads as thickness/shadow
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 2
                        height: 2
                        color: Config.colors.shadow
                    }
                }
                /*=== ===================================== ===*/

                /*=== Workspaces & Background for it ===*/
                Item {
                    id: test2
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    height: parent.height - 8

                    // The margins are weird due to the additional outlines added to each button
                    // that add depth, which is 1 pixel; thus we expand the width by 5 and not 4.
                    anchors.leftMargin: 11
                    width: workspaces.width + 5
                    Rectangle {
                        id: background2
                        anchors.fill: test2

                        anchors.bottomMargin: -2
                        color: "transparent"
                        Rectangle {
                            anchors.fill: background2
                            border.width: 0
                            color: Config.colors.shadow
                        }
                        Rectangle {
                            anchors.fill: background2
                            color: "transparent"
                            border.width: 1
                            z: -5
                            anchors.margins: -1
                            anchors.bottomMargin: 1
                        }
                    }
                    Workspaces {
                        id: workspaces
                        anchors.leftMargin: 2
                        anchors.rightMargin: 0
                    }
                }
                /*=== ============================== ===*/

                /*=== StartMenu & Other popup Stuff ===*/
                Popups.StartMenu {
                    id: startMenu
                    menuWidth: workspaces.width + startmenuButton.width
                    closeCallback: taskbar.closeAllPopups
                }
                Popups.ThemeMenu {
                    id: themeMenu
                    menuWidth: workspaces.width + startmenuButton.width + themeMenuButton.width
                }
                Popups.AppLauncher {
                    id: appLauncher
                    closeCallback: taskbar.closeAllPopups
                    menuWidth: taskbar.width / 2
                    popupWidth: 500
                    screenHeight: modelData.height
                }
                Popups.SysMonitor {
                    id: sysMonitor
                    menuWidth: workspaces.width + startmenuButton.width + themeMenuButton.width + 44
                    closeCallback: taskbar.closeAllPopups
                }
                Popups.SessionMenu {
                    id: sessionMenu
                    menuWidth: workspaces.width + startmenuButton.width + themeMenuButton.width + 70
                    closeCallback: taskbar.closeAllPopups
                }
                function closeAllPopups() {
                    switch (root.currentPopup) {
                    case Config.SystemPopup.Startmenu:
                        startMenu.closeStartMenu();
                        break;
                    case Config.SystemPopup.ThemePicker:
                        themeMenu.closeThemeMenu();
                        break;
                    case Config.SystemPopup.AppLauncher:
                        appLauncher.closeAppLauncher();
                        break;
                    case Config.SystemPopup.SysMonitor:
                        sysMonitor.visible = false;
                        break;
                    }
                    root.currentPopup = Config.SystemPopup.None;
                }

                TaskbarButton {
                    id: startmenuButton
                    isToggled: root.currentPopup == Config.SystemPopup.Startmenu ? true : false
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: workspaces.width + 20 + 4
                    onClicked: {
                        if (root.currentPopup == Config.SystemPopup.None) {
                            startMenu.openStartMenu();
                            root.currentPopup = Config.SystemPopup.Startmenu;
                        } else {
                            taskbar.closeAllPopups();
                            root.currentPopup = Config.SystemPopup.None;
                        }
                    }
                }
                TaskbarButton {
                    id: themeMenuButton
                    isToggled: root.currentPopup == Config.SystemPopup.ThemePicker ? true : false
                    iconFontValue: "\ue3ae"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: workspaces.width + 40 + 11
                    onClicked: {
                        if (root.currentPopup == Config.SystemPopup.None) {
                            themeMenu.openThemeMenu();
                            root.currentPopup = Config.SystemPopup.ThemePicker;
                        } else {
                            taskbar.closeAllPopups();
                            root.currentPopup = Config.SystemPopup.None;
                        }
                    }
                }
                TaskbarButton {
                    id: sysmonButton
                    isToggled: root.currentPopup == Config.SystemPopup.SysMonitor ? true : false
                    iconFontValue: "\ue30c"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: workspaces.width + 60 + 18
                    onClicked: {
                        if (root.currentPopup == Config.SystemPopup.None) {
                            sysMonitor.visible = true;
                            root.currentPopup = Config.SystemPopup.SysMonitor;
                        } else {
                            taskbar.closeAllPopups();
                            root.currentPopup = Config.SystemPopup.None;
                        }
                    }
                }
                TaskbarButton {
                    id: appLauncherButton
                    isToggled: root.currentPopup == Config.SystemPopup.AppLauncher ? true : false
                    iconFontValue: "\ue8b6"
                    anchors.centerIn: parent
                    onClicked: {
                        if (root.currentPopup == Config.SystemPopup.None) {
                            appLauncher.openAppLauncher();
                            root.currentPopup = Config.SystemPopup.AppLauncher;
                        } else {
                            taskbar.closeAllPopups();
                            root.currentPopup = Config.SystemPopup.None;
                        }
                    }
                }
                TaskButtons {
                    id: taskButtonsRow
                    anchors.right: appLauncherButton.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    // Cap the width so many windows can no longer collide with
                    // the workspace/start cluster on the left.
                    width: Math.min(implicitWidth, taskbar.width * 0.38)
                    clip: true
                }
                Scope {
                    id: sysmonIpc
                    IpcHandler {
                        target: "launcher"
                        function toggle() {
                            if (root.currentPopup == Config.SystemPopup.None) {
                                appLauncher.openAppLauncher();
                                root.currentPopup = Config.SystemPopup.AppLauncher;
                            } else {
                                taskbar.closeAllPopups();
                                root.currentPopup = Config.SystemPopup.None;
                            }
                        }
                    }
                    IpcHandler {
                        target: "sysmon"
                        function toggle() {
                            sysMonitor.visible = !sysMonitor.visible;
                        }
                    }
                    IpcHandler {
                        target: "session"
                        function toggle() {
                            sessionMenu.toggle();
                        }
                    }
                }
                Scope {
                    id: appLauncherIpc
                    property string screenName: taskbar.screen.name
                    IpcHandler {
                        target: "appLauncher_" + appLauncherIpc.screenName
                        function toggleAppLauncher() {
                            if (root.currentPopup == Config.SystemPopup.None) {
                                appLauncher.openAppLauncher();
                                root.currentPopup = Config.SystemPopup.AppLauncher;
                            } else {
                                taskbar.closeAllPopups();
                                root.currentPopup = Config.SystemPopup.None;
                            }
                        }
                    }
                }

                /*=== ============================= ===*/

                /*=== System Tray & Background for it ===*/
                MediaWidget {
                    id: mediaWidget
                    anchors.right: statusCluster.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                }
                StatusCluster {
                    id: statusCluster
                    anchors.right: test.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item {
                    id: test
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    height: parent.height - 8
                    width: sysTray.width + 18
                    Rectangle {
                        id: background
                        anchors.fill: test

                        anchors.bottomMargin: -2
                        color: "transparent"
                        Rectangle {
                            anchors.fill: background
                            border.width: 0
                            color: Config.colors.shadow
                        }
                        Rectangle {
                            anchors.fill: background
                            color: "transparent"
                            border.width: 1
                            z: -5
                            anchors.margins: -1
                            anchors.bottomMargin: 1
                        }
                    }
                    SysTray {
                        id: sysTray
                    }
                }
                /*=== =============================== ===*/
            }

            /*=== POPUP CLOSING PANEL ===*/
            // This panel is strictly for detecting clicks
            // outside of popups in order to close them.
            PanelWindow {
                id: overlay
                screen: root.modelData
                color: "transparent"

                implicitHeight: screen.height

                // Better UX to not have it close on hotbar press? idk. TODO: Figure this out
                //implicitHeight: screen.height - taskbar.implicitHeight

                anchors {
                    bottom: true
                    left: true
                    right: true
                }

                visible: root.currentPopup != Config.SystemPopup.None ? true : false

                exclusionMode: ExclusionMode.Ignore

                MouseArea {
                    id: popupArea
                    width: Screen.width
                    height: Screen.height
                    visible: root.currentPopup != Config.SystemPopup.None ? true : false
                    onClicked: {
                        taskbar.closeAllPopups();
                    }
                }
            }
            /*=== =================== ===*/
        }
    }

    enum SystemPopups {
        Startmenu,
        ThemePicker,
        None
    }
}
