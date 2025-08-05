import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../config" as C

ScrollBar {
  id: root
  policy: ScrollBar.AsNeeded
  implicitWidth: 6

  opacity: (policy == ScrollBar.AlwaysOn || root.pressed || root.hovered || root.active) ? 1 : 0
  Behavior on opacity {
    NumberAnimation {
      duration: C.Globals.anim_SLOW
      easing.type: Easing.BezierSpline
      easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
    }
  }

  background: Rectangle {
    anchors.fill: parent
    color: C.Config.applySecondaryOpacity(C.Config.theme.surface_container)
    radius: 4
  }

  contentItem: Rectangle {
    id: content

    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
      topMargin: root.height * root.visualPosition
    }
    color: root.pressed ? C.Config.theme.outline : root.hovered ? C.Config.applySecondaryOpacity(C.Config.theme.outline) : C.Config.applySecondaryOpacity(C.Config.theme.outline_variant)
    radius: 4

    Behavior on color {
      ColorAnimation {
        duration: 400
        easing.type: Easing.BezierSpline
        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
      }
    }
  }
}
