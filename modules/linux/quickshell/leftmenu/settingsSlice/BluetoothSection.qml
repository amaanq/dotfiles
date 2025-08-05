import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Bluetooth
import QtQuick.Controls

import "../../config" as C
import "../../state" as S
import "../../commonwidgets" as CW
import "./wifi" as W
import "./bt" as B

BaseListSection {
  id: root
  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
  property BluetoothDevice selectedDevice: null

  header: CW.ValueSwitch {
    Layout.fillWidth: true
    Layout.leftMargin: 5
    Layout.rightMargin: 5
    label: "Bluetooth"
    bold: true
    checked: root.adapter.enabled
    onToggled: root.adapter.enabled = checked
  }

  model: adapter.devices

  delegate: B.BluetoothDeviceEntry {
    required property BluetoothDevice modelData
    device: modelData

    width: ListView.view.width
    open: root.selectedDevice == device
    onClicked: root.selectedDevice = root.selectedDevice == device ? null : device
  }

  footerIcon: "bluetooth_searching"
  footerActive: adapter.discovering
  onFooterClicked: {
    adapter.discoverable = !adapter.discovering;
    adapter.discovering = !adapter.discovering;
  }
}
