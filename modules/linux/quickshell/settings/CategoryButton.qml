import "../commonwidgets" as CW
import "../config" as C
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

WrapperMouseArea {
    id: root

    property string icon: "photo"
    property string text: "Vaxry was here"
    property bool active: false

    hoverEnabled: true
    implicitWidth: 120
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        color: active ? (root.containsMouse ? Qt.lighter(C.Config.theme.primary, 1.1) : C.Config.theme.primary) : C.Config.applySecondaryOpacity(root.containsMouse ? Qt.lighter(C.Config.theme.surface_container_high, 1.8) : C.Config.theme.surface_container_high)
        radius: 10

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4

            CW.FontIcon {
                text: root.icon
                color: active ? C.Config.theme.on_primary : C.Config.theme.on_surface
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                Layout.topMargin: 5 // Doesn't wanna align, piece of shit
                iconSize: 20

                Behavior on color {
                    ColorAnimation {
                        duration: C.Globals.anim_MEDIUM
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

            CW.StyledText {
                text: root.text
                color: active ? C.Config.theme.on_primary : C.Config.theme.on_surface
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Behavior on color {
                    ColorAnimation {
                        duration: C.Globals.anim_MEDIUM
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
                    }

                }

            }

        }

        Behavior on color {
            ColorAnimation {
                duration: C.Globals.anim_MEDIUM
                easing.type: Easing.BezierSpline
                easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
            }

        }

    }

}
