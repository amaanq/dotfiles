import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../config" as C
import "../commonwidgets" as CW
import "../state" as S

RowLayout {
  id: root
  property alias icon: osdIcon.text
  property alias value: osdProgressBar.value
  property alias displayText: volumePercentage.text

  spacing: 12
  CW.FontIcon {
    id: osdIcon
    font.pointSize: C.Config.fontSize.h2
  }
  CW.StyledProgressBar {
    id: osdProgressBar
  }
  Item {
    id: osdNumber
    implicitWidth: 15
    implicitHeight: volumePercentage.implicitHeight
    CW.StyledText {
      id: volumePercentage
      anchors.centerIn: parent
    }
  }
}
