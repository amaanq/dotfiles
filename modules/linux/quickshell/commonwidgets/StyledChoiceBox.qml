import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../config" as C

SpinBox {
  id: root

  property real baseHeight: 26
  property real radius: 6
  property real innerButtonRadius: 2

  property var values: ["Hello", "werl"]

  editable: false
  implicitHeight: 20

  from: 0
  to: values.length - 1
  wrap: true

  background: Rectangle {
    anchors.centerIn: parent
    height: root.baseHeight
    width: contentItem.implicitWidth + 20
    color: C.Config.applySecondaryOpacity(C.Config.theme.surface_container_high)
    radius: root.radius
    border.color: C.Config.applySecondaryOpacity(C.Config.theme.outline_variant)
    border.width: 1
  }

  contentItem: Item {
    anchors.centerIn: parent
    implicitHeight: root.baseHeight
    implicitWidth: Math.max(labelText.implicitWidth, root.baseHeight) + 40

    Text {
      id: labelText
      anchors.centerIn: parent
      text: root.values[root.value]
      color: C.Config.theme.on_surface
      font.pointSize: C.Config.fontSize.normal
    }
  }

  down.indicator: Rectangle {
    anchors {
      top: root.background.top
      bottom: root.background.bottom
      left: parent.left
      topMargin: root.background.border.width
      bottomMargin: root.background.border.width
      leftMargin: root.background.border.width
    }
    implicitHeight: root.baseHeight
    implicitWidth: root.baseHeight
    topLeftRadius: root.radius
    bottomLeftRadius: root.radius
    topRightRadius: root.innerButtonRadius
    bottomRightRadius: root.innerButtonRadius

    color: root.down.pressed ? C.Config.applySecondaryOpacity(Qt.lighter(C.Config.theme.surface_container_high)) : root.down.hovered ? C.Config.applySecondaryOpacity(C.Config.theme.surface_container_high) : Qt.alpha(C.Config.theme.surface_container_high, 0)
    Behavior on color {
      ColorAnimation {
        duration: C.Globals.anim_FAST
        easing.type: Easing.BezierSpline
        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
      }
    }

    FontIcon {
      anchors.centerIn: parent
      text: "keyboard_arrow_left"
      iconSize: 20
      color: C.Config.theme.on_surface
    }
  }

  up.indicator: Rectangle {
    anchors {
      top: root.background.top
      bottom: root.background.bottom
      right: parent.right
      topMargin: root.background.border.width
      bottomMargin: root.background.border.width
      rightMargin: root.background.border.width
    }
    implicitHeight: root.baseHeight
    implicitWidth: root.baseHeight
    topRightRadius: root.radius
    bottomRightRadius: root.radius
    topLeftRadius: root.innerButtonRadius
    bottomLeftRadius: root.innerButtonRadius

    color: root.up.pressed ? C.Config.applySecondaryOpacity(Qt.lighter(C.Config.theme.surface_container_high)) : root.up.hovered ? C.Config.applySecondaryOpacity(C.Config.theme.surface_container_high) : Qt.alpha(C.Config.theme.surface_container_high, 0)
    Behavior on color {
      ColorAnimation {
        duration: C.Globals.anim_FAST
        easing.type: Easing.BezierSpline
        easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
      }
    }

    FontIcon {
      anchors.centerIn: parent
      text: "keyboard_arrow_right"
      iconSize: 20
      color: C.Config.theme.on_surface
    }
  }
}
