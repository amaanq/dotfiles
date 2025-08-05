import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import "../../config" as C
import "../../commonwidgets" as CW

Rectangle {
  id: root

  property string icon: "photo"
  property bool active: false
  property bool hovered: false

  color: active ? (hovered ? Qt.lighter(C.Config.theme.primary, 1.1) : C.Config.theme.primary) : C.Config.applySecondaryOpacity(hovered ? Qt.lighter(C.Config.theme.surface_container_high, 1.8) : C.Config.theme.surface_container_high)
  radius: 10

  implicitWidth: 40
  implicitHeight: 40

  CW.FontIcon {
    anchors.centerIn: parent
    text: icon
    color: active ? C.Config.theme.on_primary : C.Config.theme.on_surface
  }

  Behavior on color {
    ColorAnimation {
      duration: C.Globals.anim_MEDIUM
      easing.type: Easing.BezierSpline
      easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
    }
  }
}
