import "../../bar" as B
import "../../commonwidgets" as CW
import "../../config" as C
import "../../state" as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

WrapperMouseArea {
  id: root

  property string icon
  property string text

  signal clicked

  hoverEnabled: true

  height: layout.implicitHeight

  onPressed: clicked()

  RowLayout {
    anchors.fill: parent

    Item { Layout.fillWidth: true }

    Rectangle {
      height: layout.implicitHeight + 10
      width: layout.implicitWidth + 10
      radius: 10

      color: C.Config.applySecondaryOpacity(root.containsMouse ? Qt.lighter(C.Config.theme.surface_container_high, 1.8) : C.Config.theme.surface_container_high)

      Behavior on color {
        ColorAnimation {
          duration: C.Globals.anim_MEDIUM
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }

      RowLayout {
        id: layout

        anchors {
          horizontalCenter: parent.horizontalCenter
          verticalCenter: parent.verticalCenter
        }

        CW.FontIcon {
          text: root.icon;
          color: C.Config.theme.on_surface
        }

        CW.StyledText {
          color: C.Config.theme.on_surface
          text: root.text
          font.pointSize: C.Config.fontSize.large * 1.4
        }
      }
    }

    Item { Layout.fillWidth: true }
  }
}

