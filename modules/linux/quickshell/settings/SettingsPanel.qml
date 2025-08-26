import "../commonwidgets" as CW
import "../config" as C
import "../state" as S
import "./categories" as CAT
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland

PanelWindow {
    id: root

    property var currentComponent: bar

    WlrLayershell.namespace: "hyprland-shell:bar"
    WlrLayershell.layer: WlrLayer.overlay
    anchors: C.Config.noAnchors
    color: "transparent"
    visible: S.MiscState.settingsOpen
    implicitWidth: 1000
    implicitHeight: 800
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    GlobalShortcut {
        name: "settingsToggle"
        appid: "hyprland-shell"
        description: qsTr("Toggles settings menu on press")
        onPressed: {
            S.MiscState.settingsOpen = !S.MiscState.settingsOpen;
            S.MiscState.settingsOpenGrab = S.MiscState.settingsOpenGrab;
        }
    }

    HyprlandFocusGrab {
        id: grab

        active: S.MiscState.settingsOpenGrab
        windows: [root]
        onCleared: () => {
            S.MiscState.settingsOpen = false;
            S.MiscState.settingsOpenGrab = false;
        }
    }

    Rectangle {
        id: rectt

        focus: S.MiscState.settingsOpenGrab
        Keys.onPressed: (event) => {
            // Esc to close
            if (event.key === Qt.Key_Escape)
                S.MiscState.settingsOpen = false;

        }
        radius: C.Config.settings.panels.radius
        color: C.Config.applyBaseOpacity(C.Config.theme.background)
        border.width: C.Config.settings.panels.borders ? C.Config.settings.panels.bordersSize : 0
        border.color: C.Config.applyBaseOpacity(C.Config.theme.outline_variant)
        anchors.fill: parent
        visible: opacity != 0
        opacity: S.MiscState.settingsOpen ? 1 : 0

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4

            ColumnLayout {
                Layout.preferredWidth: 120
                Layout.fillHeight: true

                CategoryButton {
                    id: bar

                    icon: "settings"
                    text: "Bar"
                    active: root.currentComponent == bar
                    onPressed: root.currentComponent = bar
                }

                CategoryButton {
                    id: panels

                    icon: "menu"
                    text: "Panels"
                    active: root.currentComponent == panels
                    onPressed: root.currentComponent = panels
                }

                CategoryButton {
                    id: other

                    icon: "more_horiz"
                    text: "Other"
                    active: root.currentComponent == other
                    onPressed: root.currentComponent = other
                }

            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                color: C.Config.applyBaseOpacity(C.Config.theme.outline_variant)
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                CAT.BarCategory {
                    opacity: root.currentComponent == bar ? 1 : 0
                    z: root.currentComponent == bar ? 2 : 1
                    anchors.fill: parent

                    Behavior on opacity {
                        NumberAnimation {
                            duration: C.Globals.anim_MEDIUM
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                        }

                    }

                }

                CAT.PanelsCategory {
                    opacity: root.currentComponent == panels ? 1 : 0
                    z: root.currentComponent == panels ? 2 : 1
                    anchors.fill: parent

                    Behavior on opacity {
                        NumberAnimation {
                            duration: C.Globals.anim_MEDIUM
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                        }

                    }

                }

                CAT.OtherCategory {
                    opacity: root.currentComponent == other ? 1 : 0
                    z: root.currentComponent == other ? 2 : 1
                    anchors.fill: parent

                    Behavior on opacity {
                        NumberAnimation {
                            duration: C.Globals.anim_MEDIUM
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                        }

                    }

                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: C.Globals.anim_MEDIUM
                easing.type: Easing.BezierSpline
                easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }

        }

    }

}
