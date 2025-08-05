import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../config" as C
import "../bar" as B
import "../state" as S
import "../commonwidgets" as CW

ColumnLayout {
  id: root

  property string icon: ""
  property real percentage: 50

  RowLayout {
    Layout.fillWidth: true

    CW.FontIcon {
      text: root.icon

      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      font.pointSize: 11
      color: C.Config.theme.on_surface
    }

    Item {
      Layout.fillWidth: true
    }

    Text {
      text: percentage + "%"

      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      font.pointSize: 11
      color: C.Config.theme.on_surface
    }
  }

  CW.StyledProgressBar {
    value: percentage / 100.0
    Layout.fillWidth: true
    implicitHeight: 3
  }
}
