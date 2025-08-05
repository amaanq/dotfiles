import "../" as P
import "../../commonwidgets" as CW
import "../../config" as C
import "../../state" as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ColumnLayout {
  id: root

  anchors.fill: parent
  spacing: 10

  Item {
    Layout.fillHeight: true
  }

  CW.StyledText {
    Layout.alignment: Qt.AlignHCenter
    font.pointSize: C.Config.fontSize.h1
    text: "Power menu"
  }

  CW.HorizontalLine {
    Layout.bottomMargin: 20
  }

  RowLayout {
    Layout.fillWidth: true

    PowerButton {
      icon: "mode_off_on"
      text: "Shutdown"
      onClicked: Quickshell.execDetached(["shutdown", "-P", "0"])
      Layout.fillWidth: true
    }

    PowerButton {
      icon: "bedtime"
      text: "Suspend"
      onClicked: Quickshell.execDetached(["systemctl", "suspend"])
      Layout.fillWidth: true
    }
  }

  RowLayout {
    Layout.fillWidth: true

    PowerButton {
      icon: "logout"
      text: "Log out"
      onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
      Layout.fillWidth: true
    }

    PowerButton {
      icon: "replay"
      text: "Reboot"
      onClicked: Quickshell.execDetached(["reboot"])
      Layout.fillWidth: true
    }
  }

  PowerButton {
    icon: "lock"
    text: "Lock"
    onClicked: Quickshell.execDetached(["hyprlock"])
    Layout.fillWidth: true
  }

  Item {
    Layout.fillHeight: true
  }
}