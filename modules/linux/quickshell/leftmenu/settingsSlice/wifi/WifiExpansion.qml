import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import "../../../config" as C
import "../../../commonwidgets" as CW
import "../../../state" as S

Rectangle {
  id: root

  property var lines: []
  property string ssid: ""
  property bool active: false

  color: active ? Qt.darker(C.Config.theme.primary, 1.8) : C.Config.applySecondaryOpacity(Qt.lighter(C.Config.theme.surface_container, 1.8))
  radius: 6

  implicitHeight: cl.implicitHeight

  ColumnLayout {
    id: cl

    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
      margins: 6
    }

    Repeater {
      model: lines

      CW.StyledText {
        required property int index;
        text: lines[index]
      }
    }

    WrapperMouseArea {
      id: ma

      hoverEnabled: true

      Layout.preferredWidth: 90
      Layout.preferredHeight: 30
      Layout.bottomMargin: 12

      Layout.alignment: Qt.AlignRight

      onClicked: {
        if (active)
          S.WifiState.disconnect(root.ssid);
        else
          S.WifiState.connect(root.ssid);
      }

      Rectangle {
        anchors.fill: parent
        radius: 6

        color: C.Config.applySecondaryOpacity(ma.containsMouse ? Qt.lighter(C.Config.theme.background, 1.5) : C.Config.theme.background)

        Behavior on color {
          ColorAnimation {
            duration: 400
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }

        CW.StyledText {
          anchors.centerIn: parent
          text: root.active ? "Disconnect" : "Connect"
        }
      }
    }
  }
}
