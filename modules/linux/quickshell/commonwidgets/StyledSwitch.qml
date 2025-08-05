import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../config" as C

Switch {
  id: root

  implicitHeight: 20
  implicitWidth: 35
  property real switchHandlePadding: 3
  property real switchHandlePaddingUnchecked: 5

  background: Rectangle {
    radius: root.height / 2
    color: checked ? C.Config.theme.primary : C.Config.theme.surface_container_highest

    border.width: checked ? 0 : 1
    border.color: C.Config.theme.outline

    Behavior on color {
      ColorAnimation {
        duration: C.Globals.anim_MEDIUM
        easing.type: Easing.BezierSpline
        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
      }
    }
  }

  indicator: Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    property real padding: checked ? root.switchHandlePadding : root.switchHandlePaddingUnchecked
    property real size: root.height - padding * 2
    x: root.checked ? root.width - (width + padding) : padding
    width: size
    height: size
    radius: root.height / 2
    color: checked ? C.Config.theme.on_primary : C.Config.theme.outline

    Behavior on x {
      NumberAnimation {
        duration: C.Globals.anim_MEDIUM
        easing.type: Easing.BezierSpline
        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
      }
    }
  }
}
