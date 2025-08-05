import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import "../../config" as C
import "../../commonwidgets" as CW

WrapperMouseArea {
  id: root

  property string text: ""

  margin: 2
  width: height
  hoverEnabled: true

  Rectangle {
    id: bg
    anchors.fill: parent

    color: root.containsMouse ? C.Config.applySecondaryOpacity(Qt.lighter(C.Config.theme.surface_container, 1.8)) : Qt.alpha(C.Config.theme.surface_container, 0)
    radius: 8
    implicitHeight: icon.implicitHeight
    implicitWidth: icon.implicitHeight // Square

    CW.FontIcon {
      id: icon
      text: root.text
      font.pointSize: C.Config.fontSize.normal
      anchors.centerIn: parent
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
