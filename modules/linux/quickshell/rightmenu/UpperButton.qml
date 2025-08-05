import "../bar" as B
import "../commonwidgets" as CW
import "../config" as C
import "../state" as S
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

WrapperMouseArea {
    id: root

    property string icon: "visibility"
    property string description: "Vax was here"
    property bool active: false

    signal toggled()

    onClicked: () => {
        root.toggled();
    }
    implicitHeight: 30
    implicitWidth: 30
    hoverEnabled: true

    Rectangle {
        anchors.fill: parent
        color: active ? (root.containsMouse ? Qt.lighter(C.Config.theme.primary, 1.1) : C.Config.theme.primary) : C.Config.applySecondaryOpacity(root.containsMouse ? Qt.lighter(C.Config.theme.surface_container_high, 1.8) : C.Config.theme.surface_container_high)
        radius: 6

        CW.FontIcon {
            anchors.fill: parent
            text: root.icon
            font.pointSize: C.Config.fontSize.normal
            color: active ? C.Config.theme.on_primary : C.Config.theme.on_surface
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        CW.StyledText {
            color: active ? C.Config.theme.on_primary : C.Config.theme.on_surface
            text: description
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: root.containsMouse ? 0.7 : 0

            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }

            transform: Translate {
                y: -15
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: C.Globals.anim_SLOW
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
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
