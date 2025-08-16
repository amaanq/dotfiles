import "../../../commonwidgets" as CW
import "../../../config" as C
import "../../../state" as S
import "../shared"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

WrapperMouseArea {
  id: root

  property var station: {
    "ssid": "Vaxry was here",
    "security": "None",
    "bars": 4,
    "active": false
  }
  property bool open: false

  hoverEnabled: true

  ColumnLayout {
    id: collayout1

    anchors.fill: parent

    spacing: -1

    DeviceElement {
      Layout.fillWidth: true
      label: station.ssid
      active: station.active
      additionalIcon: station.bars == 4 ? "network_wifi" : (station.bars == 3 ? "network_wifi_3_bar" : (station.bars == 2 ? "network_wifi_2_bar" : "network_wifi_1_bar"))
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

    WifiExpansion {
      Layout.fillWidth: true
      lines: [station.ssid + ", " + station.bssid, "Freq: " + station.freq + "GHz", "Security: " + station.security, "Wifi Points: " + station.points, "Signal: " + (station.bars == 4 ? "Very Good" : (station.bars == 3 ? "Good" : (station.bars == 2 ? "Average" : "Poor")))]
      visible: opacity != 0
      opacity: open ? 1 : 0
      active: station.active
      ssid: station.ssid
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
