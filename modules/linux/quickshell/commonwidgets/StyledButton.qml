import "../config" as C
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

WrapperMouseArea {
  id: root

  implicitWidth: Math.max(100, lbl.width + 30)
  implicitHeight: 30
  hoverEnabled: true

  property string label: "Hello World"

  signal clicked

  onPressed: {
    clicked();
  }

  Rectangle {
    anchors.fill: parent
    radius: 8
    color: C.Config.applySecondaryOpacity(root.containsMouse ? Qt.lighter(C.Config.theme.surface_container, 2.4) : Qt.lighter(C.Config.theme.surface_container, 1.6))

    Text {
      id: lbl
      text: label
      anchors.fill: parent
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      font.pointSize: C.Config.fontSize.normal
      color: C.Config.theme.on_surface
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
