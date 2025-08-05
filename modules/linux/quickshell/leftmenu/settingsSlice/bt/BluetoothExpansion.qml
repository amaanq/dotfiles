import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Bluetooth

import "../../../config" as C
import "../../../commonwidgets" as CW
import "../../../state" as S

WrapperRectangle {
  id: root
  required property BluetoothDevice device
  readonly property bool stateChanging: device.state === BluetoothDeviceState.Connecting || device.state == BluetoothDeviceState.Disconnecting

  color: device.connected ? Qt.darker(C.Config.theme.primary, 1.8) : C.Config.applySecondaryOpacity(Qt.lighter(C.Config.theme.surface_container, 1.8))
  radius: 6

  ColumnLayout {
    id: cl

    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
      margins: 6
    }

    CW.StyledText {
      text: `${root.device.deviceName}, ${root.device.address}`
    }

    CW.StyledText {
      text: {
        let text = root.device.connected ? "Connected" : (root.device.paired ? "Paired" : "Not Connected");
        if (root.device.batteryAvailable)
          text += `, ${root.device.battery * 100}% Battery`;
        return text;
      }
    }

    WrapperMouseArea {
      id: ma

      hoverEnabled: true

      Layout.preferredWidth: 100
      Layout.preferredHeight: 30
      Layout.bottomMargin: 12

      Layout.alignment: Qt.AlignRight

      onClicked: {
        if (root.stateChanging)
          return;
        else if (root.device.connected)
          root.device.disconnect();
        else if (root.device.paired)
          root.device.connect();
        else {
          root.device.pair();
          root.device.trusted = true;
        }
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
          text: {
            switch (root.device.state) {
            case BluetoothDeviceState.Disconnected:
              return (root.device.paired ? "Connect" : "Pair");
            case BluetoothDeviceState.Connecting:
              return "Connecting";
            case BluetoothDeviceState.Connected:
              return "Disconnect";
            case BluetoothDeviceState.Disconnecting:
              return "Disconnecting";
            }
          }
        }
      }
    }
  }
}
