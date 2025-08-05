import "../../../commonwidgets" as CW
import "../../../config" as C
import "../../../state" as S
import "../shared"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Bluetooth

WrapperMouseArea {
  id: root
  required property BluetoothDevice device
  property bool open: false

  hoverEnabled: true

  ColumnLayout {
    id: collayout1

    anchors.fill: parent

    spacing: -1

    DeviceElement {
      Layout.fillWidth: true
      label: root.device.name
      active: root.device.connected
      additionalIcon: "flowchart"
      hovered: root.containsMouse
    }

    Item {
      Layout.preferredHeight: open ? 6 : -1

      Behavior on Layout.preferredHeight {
        NumberAnimation {
          duration: C.Globals.anim_NORMAL
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }
    }

    BluetoothExpansion {
      Layout.fillWidth: true
      device: root.device
      visible: opacity != 0
      opacity: open ? 1 : 0
      Layout.preferredHeight: open ? implicitHeight : 0

      Behavior on opacity {
        NumberAnimation {
          duration: C.Globals.anim_NORMAL
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }

      Behavior on Layout.preferredHeight {
        NumberAnimation {
          duration: C.Globals.anim_NORMAL
          easing.type: Easing.BezierSpline
          easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
        }
      }
    }
  }

  Behavior on implicitHeight {
    NumberAnimation {
      duration: 400
      easing.type: Easing.BezierSpline
      easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
    }
  }
}
