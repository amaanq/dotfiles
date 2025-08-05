import QtQuick
import QtQuick.Controls
import "../config" as C

Slider {
  id: root

  property real radius: 2
  implicitWidth: 150
  implicitHeight: 12
  topPadding: 4
  bottomPadding: 4
  // Prevent cutoff
  leftPadding: handle.height - background.height
  rightPadding: handle.height - background.height

  background: Rectangle {
    x: root.leftPadding
    y: root.topPadding + root.availableHeight / 2 - height / 2
    anchors {
      left: parent.left
      right: parent.right
      verticalCenter: parent.verticalCenter
    }
    height: 4
    radius: root.radius
    color: C.Config.applySecondaryOpacity(C.Config.theme.secondary_container)

    Rectangle {
      width: root.visualPosition * parent.width
      height: parent.height
      color: C.Config.theme.primary
      radius: root.radius
    }
  }

  handle: CutRectangle {
    width: root.implicitHeight
    height: root.implicitHeight
    radius: 6
    color: C.Config.theme.primary
    x: root.visualPosition * (parent.width) - width / 2
  }
}
