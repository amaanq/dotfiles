import "../../../bar" as B
import "../../../commonwidgets" as CW
import "../../../config" as C
import "../../../state" as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

RowLayout {
  id: root

  property string label: "vax was here"
  property alias value: s.value
  property alias values: s.values
  signal moved

  CW.StyledText {
    text: label
  }

  Item {
    Layout.fillWidth: true
  }

  CW.StyledChoiceBox {
    id: s
    value: root.value
    values: root.values
    onValueModified: root.moved()
  }
}
