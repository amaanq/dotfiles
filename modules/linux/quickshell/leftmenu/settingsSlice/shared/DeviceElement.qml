import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import "../../../config" as C
import "../../../commonwidgets" as CW

Rectangle {
  id: root

  property bool active: false
  property bool hovered: false
  property string label: "Device"
  property string additionalIcon: ""

  color: active ? (hovered ? Qt.darker(C.Config.theme.primary, 1.2) : Qt.darker(C.Config.theme.primary, 1.8)) : C.Config.applySecondaryOpacity(hovered ? Qt.lighter(C.Config.theme.surface_container, 1.8) : C.Config.theme.surface_container)
  radius: 6

  implicitHeight: 30

  CW.StyledText {
    anchors.fill: parent
    anchors.leftMargin: 4
    text: label
    verticalAlignment: Text.AlignVCenter
    color: C.Config.theme.on_surface
  }

  CW.FontIcon {
    anchors {
      verticalCenter: parent.verticalCenter
      right: parent.right
      rightMargin: 10
    }
    text: additionalIcon
    visible: additionalIcon != ""
  }

  Behavior on color {
    ColorAnimation {
      duration: C.Globals.anim_SLOW
      easing.type: Easing.BezierSpline
      easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
    }
  }
}
