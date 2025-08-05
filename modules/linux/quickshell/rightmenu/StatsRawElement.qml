import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../config" as C
import "../commonwidgets" as CW
import "../bar" as B
import "../state" as S

RowLayout {
  id: root

  spacing: 4

  property string icon: ""
  property string amount: "10"

  CW.FontIcon {
    text: root.icon

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    font.pointSize: 10
    color: C.Config.theme.on_surface
  }

  Text {
    text: amount

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    font.pointSize: 11
    color: C.Config.theme.on_surface
  }
}
