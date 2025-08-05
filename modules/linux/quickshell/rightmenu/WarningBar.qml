import "../bar" as B
import "../commonwidgets" as CW
import "../config" as C
import "../state" as S
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Rectangle {
  id: root

  property string text: "Hello"

  color: C.Config.applySecondaryOpacity(Qt.tint(root.containsMouse ? Qt.lighter(C.Config.theme.secondary_container, 1.6) : C.Config.theme.secondary_container, "red"))
  radius: 6
  implicitHeight: Math.max(30, rl.height + 8)

  RowLayout {
    id: rl
    anchors {
      margins: 4
      leftMargin: 10
      rightMargin: 10
      top: parent.top
      left: parent.left
      right: parent.right
    }

    CW.FontIcon {
      text: "error"
      font.pointSize: C.Config.fontSize.normal
      color: Qt.tint(C.Config.theme.primary, "red")
    }

    Text {
      text: root.text
      verticalAlignment: Text.AlignVCenter
      horizontalAlignment: Text.AlignLeft
      font.pointSize: C.Config.fontSize.normal
      color: Qt.tint(C.Config.theme.primary, "red")
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    Item {
      Layout.fillWidth: true
    }
  }

  Behavior on color {
    ColorAnimation {
      duration: C.Globals.anim_MEDIUM
      easing.type: Easing.BezierSpline
      easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
    }
  }
}
