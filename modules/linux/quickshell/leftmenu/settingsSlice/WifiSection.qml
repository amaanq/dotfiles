import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import QtQuick.Controls

import "../../config" as C
import "../../state" as S
import "../../commonwidgets" as CW
import "./wifi" as W

BaseListSection {
  id: root
  property string selectedStation: "[[VAXRY_WAS_HERE]]"

  header: CW.ValueSwitch {
    Layout.fillWidth: true
    Layout.leftMargin: 5
    Layout.rightMargin: 5
    label: "Wifi"
    bold: true
    checked: S.WifiState.wifiEnabled
    onToggled: S.WifiState.setWifiEnabled(!S.WifiState.wifiEnabled)
  }

  model: S.WifiState.wifiStations.filter(x => { return x.ssid != "" })
  delegate: W.WifiStation {
    required property int index
    width: ListView.view.width
    station: S.WifiState.wifiStations[index]
    onClicked: {
      if (selectedStation == S.WifiState.wifiStations[index].bssid)
        selectedStation = "[[VAXRY_WAS_HERE]]";
      else
        selectedStation = S.WifiState.wifiStations[index].bssid;
    }
    open: selectedStation == S.WifiState.wifiStations[index].bssid
  }

  footerIcon: "refresh"
  onFooterClicked: S.WifiState.refreshWifi()

  placeholder: !S.WifiState.wifiEnabled ? "Wifi is disabled" : (S.WifiState.wifiScanning ? "Scanning..." : "No stations available")
}
