import "../bar" as B
import "../commonwidgets" as CW
import "../config" as C
import "../state" as S
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

WrapperMouseArea {
  id: root

  hoverEnabled: true

  onPressed: {
    S.UpdateState.update();
  }

  Rectangle {
    color: C.Config.applySecondaryOpacity(root.containsMouse ? Qt.lighter(C.Config.theme.secondary_container, 1.6) : C.Config.theme.secondary_container)
    radius: 6
    implicitHeight: 30

    RowLayout {
      anchors.fill: parent
      anchors.margins: 4
      anchors.leftMargin: 10
      anchors.rightMargin: 10

      Text {
        Layout.fillHeight: true
        text: "New update available!"
        verticalAlignment: Text.AlignVCenter
        font.pointSize: C.Config.fontSize.normal
        color: C.Config.theme.primary
      }

      Item {
        Layout.fillWidth: true
      }

      Text {
        Layout.fillHeight: true
        text: "Update now"
        verticalAlignment: Text.AlignVCenter
        font.pointSize: C.Config.fontSize.normal
        color: C.Config.theme.primary
      }

      CW.FontIcon {
        text: "arrow_forward_ios"
        font.pointSize: C.Config.fontSize.normal
        color: C.Config.theme.primary
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
}
