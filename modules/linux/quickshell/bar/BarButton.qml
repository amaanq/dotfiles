import QtQuick
import Quickshell
import Quickshell.Widgets
import "../config" as C

OffsetMouseWrapper {
  id: root
  property alias contentItem: contentItem
  default property alias data: contentItem.data

  property alias radius: contentItem.radius
  property alias topLeftRadius: contentItem.topLeftRadius
  property alias topRightRadius: contentItem.topRightRadius
  property alias bottomLeftRadius: contentItem.bottomLeftRadius
  property alias bottomRightRadius: contentItem.bottomRightRadius
  property alias leftPadding: contentItem.leftMargin
  property alias rightPadding: contentItem.rightMargin
  property alias topPadding: contentItem.topMargin
  property alias bottomPadding: contentItem.bottomMargin

  extraTopMargin: 1
  extraBottomMargin: 1

  hoverEnabled: true

  radius: 5

  WrapperRectangle {
    id: contentItem
    color: root.containsPress ? "#20ffffff" : root.containsMouse ? "#10ffffff" : "transparent" // ??
    Behavior on color {
      ColorAnimation {
        duration: C.Globals.anim_FAST
        easing.type: Easing.BezierSpline
        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
      }
    }
  }
}
