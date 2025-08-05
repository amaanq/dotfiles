import QtQuick
import QtQuick.Controls
import "../config" as C

ProgressBar {
  id: root
  implicitHeight: 4
  implicitWidth: 120

  property color colHighlight: C.Config.theme.primary
  property color colTrough: C.Config.applySecondaryOpacity(C.Config.theme.secondary_container)

  Behavior on value {
    NumberAnimation {
      duration: C.Globals.anim_MEDIUM
      easing.type: Easing.BezierSpline
      easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
    }
  }

  background: null
  contentItem: Item {
    anchors {
      verticalCenter: parent.verticalCenter
      left: parent.left
      right: parent.right
    }

    Rectangle {
      // Background fill
      z: 0
      radius: root.height / 2
      anchors.fill: parent
      width: root.width
      height: root.height
      color: root.colTrough
    }

    Rectangle {
      // Left fill
      z: 1
      radius: root.height / 2
      anchors {
        verticalCenter: parent.verticalCenter
        left: parent.left
      }
      width: root.width * root.visualPosition
      height: root.height
      color: root.colHighlight
    }
  }
}
